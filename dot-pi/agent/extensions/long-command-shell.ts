/**
 * Show a scrollable "shell" box when a bash tool call runs longer than a threshold.
 *
 * Pi already streams bash output into the tool result, but it stays in the chat
 * transcript. This extension watches tool execution events and, once a command
 * exceeds the delay (default 2s), pins a boxed terminal-like view above the
 * editor showing the command, elapsed time, and its output. The box follows the
 * tail until you scroll up; scroll with the mouse wheel or alt+up/down.
 *
 * While bash itself has streamed nothing (e.g. `cmd > out.log; grep x out.log`
 * or `cmd | tail`), the box instead follows a file referenced by the command,
 * like `tail -f`: a redirect/tee target (`> out.log`, `| tee out.log`) or a file
 * read by tail/head/grep/cat/etc. Bash output takes over again as soon as any
 * arrives.
 * For plain pipelines (`cmd 2>&1 | tail -20`) the executed command is rewritten
 * to `cmd 2>&1 | tee -a <tmpfile> | tail -20` so there is a file to follow. Only
 * the executed copy changes; the transcript and model see the original command.
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
 *   /long-shell tee on|off Toggle the tee rewrite for `| tail` / `| head` pipelines
 *   /long-shell <ms>       Change the delay for this session (minimum 100ms)
 *
 *   PI_LONG_SHELL_TEE=0    Disable the tee rewrite by default
 */

import { open, rm, stat } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { isAbsolute, resolve } from "node:path";
import { StringDecoder } from "node:string_decoder";
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
const FOLLOW_POLL_MS = 500;
/** Like `tail -f`, start near the end of an existing file rather than at the top. */
const FOLLOW_INITIAL_BYTES = 64 * 1024;
const FOLLOW_MAX_READ_BYTES = 256 * 1024;
/** Top border, header row, scroll hint and bottom border. */
const BOX_CHROME_ROWS = 4;

type HeightSetting = { mode: "auto" } | { mode: "fixed"; rows: number };

type FollowState = {
	/** Absolute paths in priority order; the first one that exists is followed. */
	candidates: string[];
	path?: string;
	offset: number;
	text: string;
	decoder: StringDecoder;
	dropPartialLine: boolean;
	reading: boolean;
	timer?: NodeJS.Timeout;
};

type ShellState = {
	command: string;
	rawOutput: string;
	follow?: FollowState;
	/** True while the box is showing the followed file instead of bash output. */
	showingFile: boolean;
	/** Temp file created by the tee rewrite; deleted when the command finishes. */
	teeFile?: string;
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
let teeEnabled = process.env.PI_LONG_SHELL_TEE !== "0";
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
	refreshLines(state);
}

/** Bash output wins; fall back to the followed file while bash has printed nothing. */
function refreshLines(state: ShellState): void {
	const fileText = state.follow?.path ? state.follow.text : "";
	state.showingFile = !state.rawOutput.trim() && !!fileText;
	const text = state.showingFile ? fileText : state.rawOutput;

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
	if (state.follow?.timer) clearInterval(state.follow.timer);
	if (state.follow) state.follow.timer = undefined;
}

// ---------------------------------------------------------------------------
// File following (tail -f) for commands whose output is hidden behind tail/head
// ---------------------------------------------------------------------------

type Token =
	| { kind: "word"; value: string }
	/** `pipe` is a plain `|`; `pos` is its index in the command. */
	| { kind: "op"; pipe?: boolean; stderrPipe?: boolean; pos?: number }
	| { kind: "redir"; dup: boolean };

/** Minimal shell tokenizer: words (with quotes), control operators and redirections. */
function tokenize(command: string): Token[] {
	const tokens: Token[] = [];
	let word = "";
	let inWord = false;
	const flush = () => {
		if (inWord) tokens.push({ kind: "word", value: word });
		word = "";
		inWord = false;
	};

	for (let i = 0; i < command.length; i++) {
		const ch = command[i]!;
		if (ch === "'" || ch === '"') {
			const end = command.indexOf(ch, i + 1);
			word += command.slice(i + 1, end === -1 ? undefined : end);
			inWord = true;
			i = end === -1 ? command.length : end;
		} else if (ch === "\\" && i + 1 < command.length) {
			word += command[++i];
			inWord = true;
		} else if (/\s/.test(ch)) {
			flush();
			if (ch === "\n") tokens.push({ kind: "op" });
		} else if (ch === ">" || ch === "<" || (ch === "&" && command[i + 1] === ">")) {
			// A purely numeric word right before a redirect is its fd (2>file).
			if (/^\d+$/.test(word)) {
				word = "";
				inWord = false;
			}
			flush();
			if (ch === "&") i++;
			const input = command[i] === "<";
			while (command[i + 1] === ">" || command[i + 1] === "|") i++;
			let dup = false;
			if (command[i + 1] === "&") {
				dup = true;
				i++;
				while (/[\d-]/.test(command[i + 1] ?? "")) i++;
			}
			// Input redirects and heredocs are not output files.
			tokens.push({ kind: "redir", dup: dup || input });
		} else if (ch === "|" || ch === "&" || ch === ";" || ch === "(" || ch === ")") {
			flush();
			const pos = i;
			if ((ch === "|" || ch === "&") && command[i + 1] === ch) {
				i++;
				tokens.push({ kind: "op" });
			} else if (ch === "|" && command[i + 1] === "&") {
				i++;
				tokens.push({ kind: "op", stderrPipe: true });
			} else {
				tokens.push({ kind: "op", pipe: ch === "|", pos });
			}
		} else {
			word += ch;
			inWord = true;
		}
	}
	flush();
	return tokens;
}

/** Options of reader commands whose next word is a value, not a file. */
const READER_VALUE_OPTIONS = new Set([
	"-n", "-c", "-s", "--lines", "--bytes", "--pid", "--sleep-interval",
	"-e", "-m", "-A", "-B", "-C", "--regexp", "--max-count",
]);

/**
 * Commands whose positional args may be files being read. Non-file positionals
 * (grep patterns, jq filters, awk scripts) are harmless: only paths that exist
 * as regular files are ever followed.
 */
const READER_COMMANDS = new Set([
	"tail", "head", "cat", "tac", "grep", "egrep", "fgrep", "rg", "wc", "jq",
	"awk", "sed", "cut", "sort", "uniq", "less", "more", "nl",
]);

function resolveFollowPath(raw: string, cwd: string): string | undefined {
	if (!raw || raw === "-" || /[$`*?[\]{}]/.test(raw)) return undefined;
	const expanded = raw === "~" ? homedir() : raw.startsWith("~/") ? homedir() + raw.slice(1) : raw;
	const path = isAbsolute(expanded) ? expanded : resolve(cwd, expanded);
	return path.startsWith("/dev/") ? undefined : path;
}

/**
 * Files worth following while bash streams nothing: redirect and tee targets plus
 * files given to reader commands (tail/head/grep/cat/...), resolved against any
 * `cd` seen first.
 * Files that are both written and read rank first, then written, then read.
 */
function followCandidates(command: string, cwd: string): string[] {

	const written = new Set<string>();
	const read = new Set<string>();
	let dir = cwd;
	let commandStart = true;
	let current: "cd" | "tee" | "reader" | "other" = "other";
	let skipValue = false;
	let redirectPending = false;

	for (const token of tokenize(command)) {
		if (token.kind === "op") {
			commandStart = true;
			current = "other";
			redirectPending = false;
			continue;
		}
		if (token.kind === "redir") {
			redirectPending = !token.dup;
			continue;
		}

		const value = token.value;
		if (redirectPending) {
			redirectPending = false;
			const path = resolveFollowPath(value, dir);
			if (path) written.add(path);
			continue;
		}

		if (commandStart) {
			commandStart = false;
			const name = value.split("/").pop();
			current = name === "cd" ? "cd" : name === "tee" ? "tee" : name && READER_COMMANDS.has(name) ? "reader" : "other";
			skipValue = false;
			if (name === "nohup" || name === "time" || name === "exec") commandStart = true;
			continue;
		}

		if (current === "cd") {
			const target = resolveFollowPath(value, dir);
			if (target) dir = target;
			current = "other";
		} else if (current === "tee" || current === "reader") {
			if (skipValue) {
				skipValue = false;
			} else if (value.startsWith("-") || value.startsWith("+")) {
				skipValue = current === "reader" && READER_VALUE_OPTIONS.has(value);
			} else {
				const path = resolveFollowPath(value, dir);
				if (path) (current === "tee" ? written : read).add(path);
			}
		}
	}

	const both = [...written].filter((path) => read.has(path));
	return [...new Set([...both, ...written, ...read])];
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'\\''`)}'`;
}

/**
 * Insert `tee -a <file>` before every `| tail` / `| head` so the output hidden
 * behind them lands in a file we can follow. Returns undefined when there is no
 * such pipe or the command is too unusual to rewrite safely (heredocs, `|&`).
 */
function teeRewrite(command: string, file: string): string | undefined {
	if (command.includes("<<")) return undefined;
	const tokens = tokenize(command);
	if (tokens.some((token) => token.kind === "op" && token.stderrPipe)) return undefined;

	const positions: number[] = [];
	for (let index = 0; index < tokens.length - 1; index++) {
		const token = tokens[index]!;
		const next = tokens[index + 1]!;
		if (token.kind !== "op" || !token.pipe || token.pos === undefined || next.kind !== "word") continue;
		const name = next.value.split("/").pop();
		if (name === "tail" || name === "head") positions.push(token.pos);
	}
	if (!positions.length) return undefined;

	const tee = `| tee -a ${shellQuote(file)} `;
	let result = command;
	for (const pos of positions.reverse()) result = result.slice(0, pos) + tee + result.slice(pos);
	return result;
}

function trimToHistory(text: string): string {
	let index = text.length;
	for (let count = 0; count <= historyLines; count++) {
		index = text.lastIndexOf("\n", index - 1);
		if (index <= 0) return text;
	}
	return text.slice(index + 1);
}

async function pollFollow(state: ShellState): Promise<void> {
	const follow = state.follow;
	if (!follow || follow.reading) return;
	follow.reading = true;
	try {
		if (!follow.path) {
			for (const candidate of follow.candidates) {
				const info = await stat(candidate).catch(() => undefined);
				if (!info?.isFile()) continue;
				follow.path = candidate;
				follow.offset = Math.max(0, info.size - FOLLOW_INITIAL_BYTES);
				follow.dropPartialLine = follow.offset > 0;
				break;
			}
			if (!follow.path) return;
		}

		const info = await stat(follow.path).catch(() => undefined);
		if (!info) return;
		if (info.size < follow.offset) {
			// Truncated (e.g. re-created by `>`): start over like `tail -f` does.
			follow.offset = 0;
			follow.text = "";
			follow.decoder = new StringDecoder("utf8");
		}
		if (info.size - follow.offset > FOLLOW_MAX_READ_BYTES) {
			follow.offset = info.size - FOLLOW_INITIAL_BYTES;
			follow.text = "";
			follow.dropPartialLine = true;
			follow.decoder = new StringDecoder("utf8");
		}
		if (info.size === follow.offset) return;

		const handle = await open(follow.path, "r");
		try {
			const buffer = Buffer.alloc(info.size - follow.offset);
			const { bytesRead } = await handle.read(buffer, 0, buffer.length, follow.offset);
			follow.offset += bytesRead;
			let chunk = follow.decoder.write(buffer.subarray(0, bytesRead));
			if (follow.dropPartialLine) {
				const newline = chunk.indexOf("\n");
				if (newline === -1) return;
				chunk = chunk.slice(newline + 1);
				follow.dropPartialLine = false;
			}
			follow.text = trimToHistory(follow.text + chunk.replace(/\r\n/g, "\n"));
		} finally {
			await handle.close();
		}

		// The command may have finished while we were reading.
		if (![...active.values()].includes(state)) return;
		refreshLines(state);
		if (state.shown) requestRender?.();
	} catch {
		// Unreadable file: keep showing whatever we have.
	} finally {
		follow.reading = false;
	}
}

function startFollowing(state: ShellState): void {
	const follow = state.follow;
	if (!follow || follow.timer) return;
	void pollFollow(state);
	follow.timer = setInterval(() => void pollFollow(state), FOLLOW_POLL_MS);
	follow.timer.unref?.();
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
	const source = state.showingFile && state.follow?.path ? ` · tail -f ${state.follow.path}` : "";
	const hint = ` wheel / alt+↑↓ · ${position}${state.following ? " · live" : ""}${source}`;
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
	if (state.teeFile) void rm(state.teeFile, { force: true });

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

		const candidates = followCandidates(event.args.command, ctx.cwd);
		const state: ShellState = {
			command: cleanCommand(event.args.command),
			rawOutput: "",
			follow: candidates.length
				? {
						candidates,
						offset: 0,
						text: "",
						decoder: new StringDecoder("utf8"),
						dropPartialLine: false,
						reading: false,
					}
				: undefined,
			showingFile: false,
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
			// Start after the delay so `> file` has already truncated any stale content.
			startFollowing(state);
			mountWidget(ctx);
			requestRender?.();
		}, delayMs);
		state.delayTimer.unref?.();
	});

	// Runs after tool_execution_start; mutates only the executed copy of the args.
	pi.on("tool_call", async (event) => {
		if (!teeEnabled) return;
		const state = active.get(event.toolCallId);
		const input = event.input as { command?: unknown };
		if (!state || typeof input.command !== "string") return;

		const file = resolve(tmpdir(), `pi-long-shell-${event.toolCallId.replace(/[^\w-]/g, "_")}.log`);
		const rewritten = teeRewrite(input.command, file);
		if (!rewritten) return;

		input.command = rewritten;
		state.teeFile = file;
		const follow = state.follow ?? {
			candidates: [],
			offset: 0,
			text: "",
			decoder: new StringDecoder("utf8"),
			dropPartialLine: false,
			reading: false,
		};
		follow.candidates = [file, ...follow.candidates.filter((path) => path !== file)];
		state.follow = follow;
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
		for (const state of active.values()) {
			clearTimers(state);
			if (state.teeFile) void rm(state.teeFile, { force: true });
		}
		active.clear();
		unmountWidget(ctx);
	});

	pi.registerCommand("long-shell", {
		description: "Configure the live shell box for long-running bash commands",
		getArgumentCompletions(prefix: string) {
			return ["on", "off", "status", "height", "auto", "tee"].filter((value) =>
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
					`Live shell box ${enabled ? "on" : "off"} · delay ${delayMs}ms · ${height} · ${historyLines} lines of history · tee ${teeEnabled ? "on" : "off"}`,
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

			if (argument === "tee" || argument.startsWith("tee ")) {
				const raw = argument.slice("tee".length).trim();
				if (raw === "on" || raw === "off") teeEnabled = raw === "on";
				else if (raw) {
					ctx.ui.notify("Usage: /long-shell tee on|off", "warning");
					return;
				}
				ctx.ui.notify(`Tee rewrite for | tail / | head pipelines: ${teeEnabled ? "on" : "off"}`, "info");
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
					"Usage: /long-shell on|off|status|tee on|off|height [auto|<rows>]|<milliseconds >= 100>",
					"warning",
				);
				return;
			}

			delayMs = Math.floor(value);
			ctx.ui.notify(`Live shell box delay: ${delayMs}ms`, "info");
		},
	});
}
