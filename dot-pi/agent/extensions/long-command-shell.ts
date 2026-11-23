/**
 * Show a scrollable "shell" box when a bash tool call runs longer than a threshold.
 *
 * Pi already streams bash output into the tool result, but it stays in the chat
 * transcript. This extension watches tool execution events and, once a command
 * exceeds the delay (default 2s), pins a boxed terminal-like view above the
 * editor showing the command, elapsed time, and its output. The box follows the
 * tail until you scroll up; scroll with the mouse wheel or alt+up/down.
 *
 * Configuration:
 *   PI_LONG_SHELL_DELAY_MS   Delay before the box appears (default: 2000)
 *   PI_LONG_SHELL_LINES      Output history kept for scrolling (default: 200)
 *   PI_LONG_SHELL_BOX_HEIGHT "auto" (30% of terminal rows) or a row count
 *
 * Commands:
 *   /long-shell            Show current settings
 *   /long-shell on|off     Enable or disable the box for this session
 *   /long-shell height     Show the current height setting
 *   /long-shell height n   Fix the box at n rows (6-30)
 *   /long-shell height auto Follow the terminal height again
 *   /long-shell <ms>       Change the delay for this session (minimum 100ms)
 */

import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import {
	matchesKey,
	replaceControlCharacters,
	stripTerminalSequences,
	truncateToWidth,
	type TuiMouseEvent,
	type TuiMouseEventResult,
} from "@earendil-works/pi-tui";

const WIDGET_KEY = "long-command-shell";
const DEFAULT_DELAY_MS = 2_000;
const DEFAULT_HISTORY_LINES = 200;
const AUTO_HEIGHT_RATIO = 0.3;
const MIN_BOX_HEIGHT = 6;
const MAX_BOX_HEIGHT = 30;
const TICK_MS = 1_000;
/** Top border, header row, scroll hint and bottom border. */
const BOX_CHROME_ROWS = 4;

type HeightSetting = { mode: "auto" } | { mode: "fixed"; rows: number };

type ShellState = {
	command: string;
	rawOutput: string;
	lines: string[];
	scrollTop: number;
	following: boolean;
	startedAt: number;
	shown: boolean;
	delayTimer?: NodeJS.Timeout;
};

/** One box is shared by all in-flight commands; the newest long command wins. */
const active = new Map<string, ShellState>();
let enabled = true;
let delayMs = readPositiveInt(process.env.PI_LONG_SHELL_DELAY_MS, DEFAULT_DELAY_MS);
let historyLines = readPositiveInt(process.env.PI_LONG_SHELL_LINES, DEFAULT_HISTORY_LINES);
let heightSetting = parseHeightSetting(process.env.PI_LONG_SHELL_BOX_HEIGHT);
let terminalRows = Math.max(1, process.stdout.rows || 24);
let appliedHeight = 0;
let widgetMounted = false;
let tickTimer: NodeJS.Timeout | undefined;
let requestRender: (() => void) | undefined;
let unsubscribeInput: (() => void) | undefined;

function clampHeight(rows: number): number {
	return Math.max(MIN_BOX_HEIGHT, Math.min(MAX_BOX_HEIGHT, Math.floor(rows)));
}

function parseHeightSetting(raw: string | undefined): HeightSetting {
	if (!raw || raw.trim().toLowerCase() === "auto") return { mode: "auto" };
	const rows = Number(raw);
	return Number.isFinite(rows) ? { mode: "fixed", rows: clampHeight(rows) } : { mode: "auto" };
}

function effectiveBoxHeight(): number {
	return heightSetting.mode === "fixed"
		? heightSetting.rows
		: clampHeight(Math.round(terminalRows * AUTO_HEIGHT_RATIO));
}

function contentRows(): number {
	return Math.max(1, effectiveBoxHeight() - BOX_CHROME_ROWS);
}

function readPositiveInt(raw: string | undefined, fallback: number): number {
	const value = Number(raw);
	return Number.isFinite(value) && value >= 1 ? Math.floor(value) : fallback;
}

function cleanCommand(command: string): string {
	return replaceControlCharacters(stripTerminalSequences(command)).trim();
}

function commandPreview(command: string): string {
	const singleLine = command.replace(/\s+/g, " ").trim();
	return singleLine.length > 120 ? `${singleLine.slice(0, 117)}...` : singleLine;
}

function cleanLine(line: string): string {
	return replaceControlCharacters(stripTerminalSequences(line));
}

/** Bash updates carry a fresh snapshot of the output, not an incremental chunk. */
function snapshotText(partial: unknown): string | undefined {
	if (!partial || typeof partial !== "object") return undefined;
	const content = (partial as { content?: unknown }).content;
	if (!Array.isArray(content)) return undefined;

	const text = content
		.filter(
			(part): part is { type: string; text: string } =>
				!!part &&
				typeof part === "object" &&
				(part as { type?: unknown }).type === "text" &&
				typeof (part as { text?: unknown }).text === "string",
		)
		.map((part) => part.text)
		.join("\n");

	return text;
}

function latestVisibleState(): { state: ShellState; others: number } | undefined {
	let latest: ShellState | undefined;
	let others = 0;
	for (const state of active.values()) {
		if (!state.shown) continue;
		if (latest) others++;
		else latest = state;
	}
	return latest ? { state: latest, others } : undefined;
}

function maxScroll(state: ShellState): number {
	return Math.max(0, state.lines.length - contentRows());
}

function setOutput(state: ShellState, text: string): void {
	if (text === state.rawOutput) return;
	state.rawOutput = text;

	const lines = text.trimEnd().split("\n").map(cleanLine);
	state.lines = lines.slice(-historyLines);

	if (state.following) state.scrollTop = maxScroll(state);
	else state.scrollTop = Math.min(state.scrollTop, maxScroll(state));
}

function scrollBy(state: ShellState, delta: number): void {
	const maximum = maxScroll(state);
	if (maximum === 0) return;
	state.scrollTop = Math.max(0, Math.min(maximum, state.scrollTop + delta));
	state.following = state.scrollTop >= maximum;
}

function scrollTo(state: ShellState, top: number): void {
	const maximum = maxScroll(state);
	if (maximum === 0) return;
	state.scrollTop = Math.max(0, Math.min(maximum, top));
	state.following = state.scrollTop >= maximum;
}

/** Re-anchor scrolling when the box height changes (including after a terminal resize). */
function syncHeight(): void {
	const height = effectiveBoxHeight();
	if (height === appliedHeight) return;
	appliedHeight = height;
	for (const state of active.values()) {
		const maximum = maxScroll(state);
		state.scrollTop = state.following ? maximum : Math.min(state.scrollTop, maximum);
	}
}

function setHeightSetting(setting: HeightSetting): void {
	heightSetting = setting;
	syncHeight();
	requestRender?.();
}

function clearTimers(state: ShellState): void {
	if (state.delayTimer) clearTimeout(state.delayTimer);
	state.delayTimer = undefined;
}

function stopTicker(): void {
	if (tickTimer) clearInterval(tickTimer);
	tickTimer = undefined;
}

function startTicker(): void {
	if (tickTimer) return;
	tickTimer = setInterval(() => requestRender?.(), TICK_MS);
	tickTimer.unref?.();
}

function unmountWidget(ctx: ExtensionContext): void {
	stopTicker();
	requestRender = undefined;
	if (!widgetMounted) return;
	widgetMounted = false;
	if (ctx.hasUI) ctx.ui.setWidget(WIDGET_KEY, undefined);
}

function renderBox(state: ShellState, theme: Theme, others: number, width: number): string[] {
	const inner = Math.max(1, width - 2);
	const border = (text: string) => theme.fg("border", text);
	const row = (text: string) =>
		border("│") + truncateToWidth(text, inner, "…", true) + border("│");

	const seconds = Math.max(0, Math.round((Date.now() - state.startedAt) / 100) / 10);
	const more = others ? `  +${others} more` : "";
	const lines = [
		border(`╭${"─".repeat(inner)}╮`),
		row(
			theme.fg("toolTitle", theme.bold("$ ")) +
				theme.fg("accent", commandPreview(state.command)) +
				theme.fg("dim", ` ${seconds}s${more}`),
		),
	];

	const rows = contentRows();
	const hasOutput = state.lines.length > 0 && !(state.lines.length === 1 && state.lines[0] === "");
	const visible = hasOutput ? state.lines.slice(state.scrollTop, state.scrollTop + rows) : [];
	for (let index = 0; index < rows; index++) {
		const line = visible[index];
		lines.push(line === undefined ? row("") : row(theme.fg("toolOutput", line)));
	}

	const first = hasOutput ? state.scrollTop + 1 : 0;
	const last = hasOutput ? state.scrollTop + visible.length : 0;
	const position = `${first}-${last}/${state.lines.length}`;
	const hint = ` wheel / alt+↑↓ · ${position}${state.following ? " · live" : ""}`;
	lines.push(row(theme.fg("dim", hint)));
	lines.push(border(`╰${"─".repeat(inner)}╯`));
	return lines;
}

function mountWidget(ctx: ExtensionContext): void {
	if (widgetMounted || !ctx.hasUI) return;
	widgetMounted = true;
	startTicker();

	ctx.ui.setWidget(WIDGET_KEY, (tui, theme) => {
		requestRender = () => tui.requestRender();
		terminalRows = Math.max(1, tui.terminal.rows || terminalRows);
		syncHeight();

		return {
			render(width: number): string[] {
				terminalRows = Math.max(1, tui.terminal.rows || terminalRows);
				syncHeight();
				const visible = latestVisibleState();
				return visible ? renderBox(visible.state, theme, visible.others, width) : [];
			},

			invalidate() {},

			dispose() {
				requestRender = undefined;
			},

			handleMouse(event: TuiMouseEvent): TuiMouseEventResult | undefined {
				if (event.type !== "wheel" || !event.wheelDelta) return undefined;
				const state = latestVisibleState()?.state;
				if (!state || maxScroll(state) === 0) return undefined;

				const delta = Math.max(-6, Math.min(6, event.wheelDelta));
				scrollBy(state, delta);
				requestRender?.();
				return { handled: true };
			},
		};
	});
}

function finish(ctx: ExtensionContext, toolCallId: string): void {
	const state = active.get(toolCallId);
	if (!state) return;
	clearTimers(state);
	active.delete(toolCallId);

	if (latestVisibleState()) requestRender?.();
	else unmountWidget(ctx);
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		unsubscribeInput = ctx.ui.onTerminalInput((data) => {
			const state = latestVisibleState()?.state;
			if (!state || maxScroll(state) === 0) return;

			if (matchesKey(data, "alt+up")) scrollBy(state, -1);
			else if (matchesKey(data, "alt+down")) scrollBy(state, 1);
			else if (matchesKey(data, "alt+pageUp")) scrollBy(state, -contentRows());
			else if (matchesKey(data, "alt+pageDown")) scrollBy(state, contentRows());
			else if (matchesKey(data, "alt+home")) scrollTo(state, 0);
			else if (matchesKey(data, "alt+end")) scrollTo(state, Number.MAX_SAFE_INTEGER);
			else return;

			requestRender?.();
			return { consume: true };
		});
	});

	pi.on("tool_execution_start", async (event, ctx) => {
		if (!enabled || !ctx.hasUI || event.toolName !== "bash" || event.parentToolCallId) return;
		if (typeof event.args?.command !== "string") return;

		const state: ShellState = {
			command: cleanCommand(event.args.command),
			rawOutput: "",
			lines: [],
			scrollTop: 0,
			following: true,
			startedAt: Date.now(),
			shown: false,
		};
		active.set(event.toolCallId, state);

		state.delayTimer = setTimeout(() => {
			state.delayTimer = undefined;
			if (!active.has(event.toolCallId)) return;
			state.shown = true;
			mountWidget(ctx);
			requestRender?.();
		}, delayMs);
		state.delayTimer.unref?.();
	});

	pi.on("tool_execution_update", async (event) => {
		const state = active.get(event.toolCallId);
		if (!state) return;

		const output = snapshotText(event.partialResult);
		if (output !== undefined) {
			setOutput(state, output);
			if (state.shown) requestRender?.();
		}
	});

	pi.on("tool_execution_end", async (event, ctx) => {
		finish(ctx, event.toolCallId);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		unsubscribeInput?.();
		unsubscribeInput = undefined;
		for (const state of active.values()) clearTimers(state);
		active.clear();
		unmountWidget(ctx);
	});

	pi.registerCommand("long-shell", {
		description: "Configure the live shell box for long-running bash commands",
		getArgumentCompletions(prefix: string) {
			return ["on", "off", "status", "height", "auto"].filter((value) =>
				value.startsWith(prefix.toLowerCase()),
			);
		},
		handler: async (args, ctx) => {
			const argument = args.trim().toLowerCase();

			if (!argument || argument === "status") {
				const height =
					heightSetting.mode === "auto"
						? `auto ${effectiveBoxHeight()} rows (${terminalRows} terminal rows)`
						: `fixed ${heightSetting.rows} rows`;
				ctx.ui.notify(
					`Live shell box ${enabled ? "on" : "off"} · delay ${delayMs}ms · ${height} · ${historyLines} lines of history`,
					"info",
				);
				return;
			}

			if (argument === "on" || argument === "off") {
				enabled = argument === "on";
				if (!enabled) {
					for (const state of active.values()) clearTimers(state);
					unmountWidget(ctx);
				}
				ctx.ui.notify(`Live shell box ${enabled ? "enabled" : "disabled"}`, "info");
				return;
			}

			if (argument === "auto") {
				setHeightSetting({ mode: "auto" });
				ctx.ui.notify(`Box height: auto (${effectiveBoxHeight()} rows)`, "info");
				return;
			}

			if (argument === "height" || argument.startsWith("height ")) {
				const raw = argument.slice("height".length).trim();
				if (!raw) {
					ctx.ui.notify(
						heightSetting.mode === "auto"
							? `Box height: auto (30% of ${terminalRows} rows = ${effectiveBoxHeight()})`
							: `Box height: fixed ${heightSetting.rows} rows`,
						"info",
					);
					return;
				}
				if (raw === "auto") {
					setHeightSetting({ mode: "auto" });
					ctx.ui.notify(`Box height: auto (${effectiveBoxHeight()} rows)`, "info");
					return;
				}
				const rows = Number(raw);
				if (!Number.isFinite(rows) || rows < MIN_BOX_HEIGHT || rows > MAX_BOX_HEIGHT) {
					ctx.ui.notify(`Box height must be ${MIN_BOX_HEIGHT}-${MAX_BOX_HEIGHT} rows or auto`, "warning");
					return;
				}
				setHeightSetting({ mode: "fixed", rows: Math.floor(rows) });
				ctx.ui.notify(`Live shell box height: ${effectiveBoxHeight()} rows`, "info");
				return;
			}

			const value = Number(argument.replace(/ms$/, ""));
			if (!Number.isFinite(value) || value < 100) {
				ctx.ui.notify(
					"Usage: /long-shell on|off|status|height [auto|<rows>]|<milliseconds >= 100>",
					"warning",
				);
				return;
			}

			delayMs = Math.floor(value);
			ctx.ui.notify(`Live shell box delay: ${delayMs}ms`, "info");
		},
	});
}
