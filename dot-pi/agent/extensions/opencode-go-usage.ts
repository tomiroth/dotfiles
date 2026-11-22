/**
 * OpenCode Go usage extension for Pi.
 *
 * Commands:
 *   /go-usage          Show rolling/weekly/monthly Go usage
 *   /go-usage refresh  Bypass the short-lived cache and fetch fresh usage
 *   /go-usage status   Toggle the compact Go usage item in the footer
 *
 * Uses the documented endpoint:
 *   https://opencode.ai/inference/go/v1/usage
 */

import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const USAGE_URL = "https://opencode.ai/inference/go/v1/usage";
const STATUS_KEY = "opencode-go-usage";
const CACHE_MS = 60_000;

type MeterStatus = "ok" | "rate-limited" | string;

type Meter = {
  status: MeterStatus;
  percent: number;
  resetsAt: string;
};

type UsageResponse = {
  usage: {
    rolling: Meter;
    weekly: Meter;
    monthly: Meter;
  };
};

type ThemeLike = {
  fg: (
    color: "accent" | "success" | "warning" | "error" | "muted" | "dim",
    text: string,
  ) => string;
  bold: (text: string) => string;
};

let cached: { fetchedAt: number; data: UsageResponse } | undefined;
let statusEnabled = true;

function clampPercent(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function meterColor(meter: Meter): "success" | "warning" | "error" {
  if (meter.status === "rate-limited" || meter.percent >= 100) return "error";
  if (meter.percent >= 80) return "warning";
  return "success";
}

function formatDuration(ms: number, roundUp = true): string {
  const minutes = Math.max(0, roundUp ? Math.ceil(ms / 60_000) : Math.floor(ms / 60_000));
  if (minutes < 60) return `${minutes}m`;

  const hours = Math.floor(minutes / 60);
  const remainder = minutes % 60;
  if (hours < 24) return remainder ? `${hours}h ${remainder}m` : `${hours}h`;

  const days = Math.floor(hours / 24);
  const remainingHours = hours % 24;
  return remainingHours ? `${days}d ${remainingHours}h` : `${days}d`;
}

function formatReset(resetsAt: string): string {
  const timestamp = new Date(resetsAt).getTime();
  if (!Number.isFinite(timestamp)) return "reset time unknown";

  const remaining = timestamp - Date.now();
  const local = new Date(timestamp).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });

  return remaining <= 0 ? `resetting (${local})` : `resets ${formatDuration(remaining)} (${local})`;
}

function parseUsage(payload: unknown): UsageResponse {
  if (!payload || typeof payload !== "object") {
    throw new Error("OpenCode Go returned an unexpected usage response");
  }

  const usage = (payload as { usage?: unknown }).usage;
  if (!usage || typeof usage !== "object") {
    throw new Error("OpenCode Go usage response is missing the usage object");
  }

  const record = usage as Record<string, unknown>;
  const parseMeter = (key: "rolling" | "weekly" | "monthly"): Meter => {
    const raw = record[key];
    if (!raw || typeof raw !== "object") {
      throw new Error(`OpenCode Go usage response is missing "${key}"`);
    }

    const meter = raw as Record<string, unknown>;
    const percent = Number(meter.percent);
    if (!Number.isFinite(percent)) {
      throw new Error(`OpenCode Go returned an invalid "${key}" percentage`);
    }

    return {
      status: typeof meter.status === "string" ? meter.status : "ok",
      percent: clampPercent(percent),
      resetsAt: typeof meter.resetsAt === "string" ? meter.resetsAt : "",
    };
  };

  return {
    usage: {
      rolling: parseMeter("rolling"),
      weekly: parseMeter("weekly"),
      monthly: parseMeter("monthly"),
    },
  };
}

async function resolveApiKey(): Promise<string> {
  const environmentalKey = process.env.OPENCODE_API_KEY?.trim();
  if (environmentalKey) return environmentalKey;

  const authPath = join(homedir(), ".pi", "agent", "auth.json");
  let raw: string;
  try {
    raw = await readFile(authPath, "utf8");
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code === "ENOENT") {
      throw new Error("No OpenCode API key found. Set OPENCODE_API_KEY or run /login opencode-go.");
    }
    throw new Error(`Could not read ${authPath}: ${(error as Error).message}`);
  }

  let auth: unknown;
  try {
    auth = JSON.parse(raw);
  } catch {
    throw new Error(`Could not parse ${authPath}`);
  }

  if (!auth || typeof auth !== "object") {
    throw new Error("No OpenCode API key found. Set OPENCODE_API_KEY or run /login opencode-go.");
  }

  const credentials = auth as Record<string, unknown>;
  for (const provider of ["opencode-go", "opencode"]) {
    const entry = credentials[provider];
    if (!entry || typeof entry !== "object") continue;

    const key = (entry as Record<string, unknown>).key;
    if (typeof key === "string" && key.trim()) return key.trim();
  }

  throw new Error("No OpenCode API key found. Set OPENCODE_API_KEY or run /login opencode-go.");
}

async function fetchUsage(force = false): Promise<UsageResponse> {
  if (!force && cached && Date.now() - cached.fetchedAt < CACHE_MS) {
    return cached.data;
  }

  const key = await resolveApiKey();
  let response: Response;
  try {
    response = await fetch(USAGE_URL, {
      headers: {
        Authorization: `Bearer ${key}`,
        Accept: "application/json",
        "User-Agent": "pi-opencode-go-usage/1.0",
      },
      signal: AbortSignal.timeout(10_000),
    });
  } catch (error) {
    if (error instanceof Error && error.name === "TimeoutError") {
      throw new Error("OpenCode Go usage request timed out");
    }
    throw new Error(`Could not reach OpenCode Go: ${(error as Error).message}`);
  }

  const body = await response.text();
  if (!response.ok) {
    let detail = "";
    try {
      const parsed = JSON.parse(body) as Record<string, unknown>;
      for (const field of ["message", "error", "detail"]) {
        if (typeof parsed[field] === "string") {
          detail = parsed[field] as string;
          break;
        }
      }
    } catch {
      detail = body.slice(0, 200);
    }

    const suffix = detail ? `: ${detail.slice(0, 300)}` : "";
    throw new Error(`OpenCode Go usage API returned HTTP ${response.status}${suffix}`);
  }

  let payload: unknown;
  try {
    payload = JSON.parse(body);
  } catch {
    throw new Error("OpenCode Go returned invalid JSON for usage");
  }

  const data = parseUsage(payload);
  cached = { fetchedAt: Date.now(), data };
  return data;
}

function compactUsage(data: UsageResponse, theme: ThemeLike): string {
  const label = (name: string, meter: Meter) =>
    `${name} ${theme.fg(meterColor(meter), `${meter.percent}%`)}`;

  return `${theme.fg("dim", "Go usage")} ${label("5h", data.usage.rolling)}  ${label(
    "week",
    data.usage.weekly,
  )}  ${label("month", data.usage.monthly)}`;
}

function setStatus(ctx: ExtensionContext, text: string | undefined): void {
  if (!statusEnabled || !ctx.hasUI) return;
  ctx.ui.setStatus(STATUS_KEY, text);
}

function setStatusFromData(ctx: ExtensionContext, data: UsageResponse): void {
  setStatus(ctx, compactUsage(data, ctx.ui.theme));
}

async function refreshStatus(ctx: ExtensionContext, force = false): Promise<void> {
  if (!statusEnabled || !ctx.hasUI || ctx.model?.provider !== "opencode-go") return;

  try {
    const data = await fetchUsage(force);
    if (ctx.model?.provider === "opencode-go") setStatusFromData(ctx, data);
  } catch (error) {
    const message = (error as Error).message;
    setStatus(
      ctx,
      ctx.ui.theme.fg("dim", message.includes("API key") ? "Go usage: no key" : "Go usage: unavailable"),
    );

    if (force && ctx.hasUI) {
      ctx.ui.notify(message, "warning");
    }
  }
}

async function showUsagePanel(ctx: ExtensionContext, force: boolean): Promise<void> {
  let state:
    | { kind: "loading" }
    | { kind: "data"; data: UsageResponse; fetchedAt: number }
    | { kind: "error"; message: string } = { kind: "loading" };

  await ctx.ui.custom<void>((tui, theme, keybindings, done) => {
    const load = async (bypassCache: boolean) => {
      state = { kind: "loading" };
      tui.requestRender();

      try {
        const data = await fetchUsage(bypassCache);
        state = { kind: "data", data, fetchedAt: Date.now() };
        await refreshStatus(ctx);
      } catch (error) {
        state = { kind: "error", message: (error as Error).message };
      }

      tui.requestRender();
    };

    void load(force);

    return {
      render(width: number): string[] {
        const lines: string[] = [
          "",
          `  ${theme.fg("accent", theme.bold("OpenCode Go usage"))}`,
          "",
        ];

        if (state.kind === "loading") {
          lines.push(`  ${theme.fg("dim", "Fetching usage...")}`);
        } else if (state.kind === "error") {
          lines.push(`  ${theme.fg("error", state.message)}`);
        } else {
          const barWidth = Math.max(8, Math.min(20, width - 34));

          const rows: Array<[string, Meter]> = [
            ["5-hour", state.data.usage.rolling],
            ["weekly", state.data.usage.weekly],
            ["monthly", state.data.usage.monthly],
          ];

          for (const [label, meter] of rows) {
            const percent = clampPercent(meter.percent);
            const color = meterColor(meter);
            const filled = Math.round((percent / 100) * barWidth);
            const bar =
              theme.fg(color, "█".repeat(filled)) + theme.fg("dim", "░".repeat(barWidth - filled));
            const percentText = `${percent}%`;

            lines.push(`  ${label.padEnd(8)} ${bar}  ${theme.fg(color, percentText.padStart(4))}`);
            lines.push(`  ${theme.fg("dim", `         ${formatReset(meter.resetsAt)}`)}`);
          }

          lines.push("");
          lines.push(
            `  ${theme.fg("dim", `Updated ${formatDuration(Date.now() - state.fetchedAt, false)} ago`)}`,
          );
        }

        lines.push("");
        lines.push(`  ${theme.fg("dim", "R refresh  ·  Enter/Esc close")}`);
        lines.push("");

        return lines.map((line) => truncateToWidth(line, width));
      },

      handleInput(data: string): void {
        if (data === "r" || data === "R") {
          void load(true);
          return;
        }
        if (keybindings.matches(data, "tui.select.confirm") || keybindings.matches(data, "tui.select.cancel")) {
          done();
        }
      },

      invalidate() {},
    };
  });
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("go-usage", {
    description: "Show OpenCode Go usage limits",
    getArgumentCompletions: (prefix: string) => {
      const options = ["refresh", "status"].filter((option) => option.startsWith(prefix.toLowerCase()));
      return options.length ? options.map((value) => ({ value, label: value })) : null;
    },
    handler: async (args, ctx) => {
      const argument = args.trim().toLowerCase().replace(/^--/, "");

      if (argument === "status") {
        statusEnabled = !statusEnabled;
        setStatus(ctx, undefined);
        if (statusEnabled && ctx.model?.provider === "opencode-go") {
          void refreshStatus(ctx);
        }
        ctx.ui.notify(`Go usage footer ${statusEnabled ? "enabled" : "disabled"}`, "info");
        return;
      }

      const force = argument === "refresh" || argument === "r";

      if (ctx.mode === "tui") {
        await showUsagePanel(ctx, force);
        return;
      }

      try {
        const data = await fetchUsage(force);
        const summary = compactUsage(data, ctx.ui.theme);
        if (ctx.model?.provider === "opencode-go") setStatusFromData(ctx, data);
        if (ctx.hasUI) ctx.ui.notify(summary, "info");
        else process.stderr.write(`${summary}\n`);
      } catch (error) {
        const message = (error as Error).message;
        if (ctx.hasUI) ctx.ui.notify(message, "error");
        else process.stderr.write(`${message}\n`);
      }
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.model?.provider !== "opencode-go") return;

    const hit = cached && Date.now() - cached.fetchedAt < CACHE_MS ? cached : undefined;
    setStatus(ctx, hit ? compactUsage(hit.data, ctx.ui.theme) : ctx.ui.theme.fg("dim", "Go usage: ..."));
    void refreshStatus(ctx);
  });

  pi.on("model_select", async (event, ctx) => {
    if (event.model.provider !== "opencode-go") {
      setStatus(ctx, undefined);
      return;
    }
    void refreshStatus(ctx);
  });

  pi.on("turn_end", async (_event, ctx) => {
    void refreshStatus(ctx);
  });
}
