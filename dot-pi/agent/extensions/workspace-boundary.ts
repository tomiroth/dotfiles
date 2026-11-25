import { existsSync, mkdirSync, readFileSync, realpathSync, statSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";
import { isToolCallEventType, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";

function isWithin(root: string, target: string): boolean {
	const rel = relative(root, target);
	return rel === "" || (rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel));
}

function canonicalizePath(path: string): string {
	const absolute = resolve(path);
	let candidate = absolute;
	while (!existsSync(candidate)) {
		const parent = dirname(candidate);
		if (parent === candidate) return absolute;
		candidate = parent;
	}
	const suffix = relative(candidate, absolute);
	return resolve(realpathSync(candidate), suffix);
}

/** Match the path expansion used by Pi's built-in write/edit tools (~ and @ prefixes). */
function expandPath(cwd: string, path: string): string {
	let value = path.trim();
	if (value.startsWith("~")) value = `${homedir()}${value.slice(1)}`;
	if (value.startsWith("@")) value = value.slice(1);
	return resolve(cwd, value);
}

const safeRoots = ["/tmp", "/var/tmp", "/dev/shm", tmpdir()];

function isSafeRoot(target: string): boolean {
	const canonicalTarget = canonicalizePath(target);
	return safeRoots.some((root) => isWithin(canonicalizePath(root), canonicalTarget));
}

// ---------------------------------------------------------------------------
// Per-project allowlist: directories (and all their children) that are always
// allowed to be modified when working from a given project.
// Stored in ~/.pi/agent/workspace-boundary.json as { projects: { [cwd]: [dir] } }
// ---------------------------------------------------------------------------

const configPath = resolve(homedir(), ".pi", "agent", "workspace-boundary.json");

type Config = { projects: Record<string, string[]> };

function loadConfig(): Config {
	try {
		const parsed = JSON.parse(readFileSync(configPath, "utf8"));
		if (parsed && typeof parsed === "object" && parsed.projects && typeof parsed.projects === "object") return parsed;
	} catch {
		// Missing or invalid config: treat as empty.
	}
	return { projects: {} };
}

function saveConfig(config: Config): void {
	mkdirSync(dirname(configPath), { recursive: true });
	writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`);
}

function projectKey(cwd: string): string {
	return canonicalizePath(cwd);
}

function getAllowedDirs(cwd: string): string[] {
	return loadConfig().projects[projectKey(cwd)] ?? [];
}

function addAllowedDir(cwd: string, dir: string): string {
	const canonical = canonicalizePath(dir);
	const config = loadConfig();
	const key = projectKey(cwd);
	const dirs = config.projects[key] ?? [];
	if (!dirs.includes(canonical)) dirs.push(canonical);
	config.projects[key] = dirs.sort();
	saveConfig(config);
	return canonical;
}

function removeAllowedDir(cwd: string, dir: string): boolean {
	const config = loadConfig();
	const key = projectKey(cwd);
	const dirs = config.projects[key] ?? [];
	const canonical = canonicalizePath(dir);
	const next = dirs.filter((d) => d !== canonical && d !== dir);
	if (next.length === dirs.length) return false;
	if (next.length) config.projects[key] = next;
	else delete config.projects[key];
	saveConfig(config);
	return true;
}

function isAllowedDir(cwd: string, target: string): boolean {
	const dirs = getAllowedDirs(cwd);
	if (!dirs.length) return false;
	const canonicalTarget = canonicalizePath(target);
	return dirs.some((dir) => isWithin(canonicalizePath(dir), canonicalTarget));
}

/** Directory to suggest allowing for a target path (the dir itself, or its parent for files). */
function suggestedDir(target: string): string {
	try {
		if (existsSync(target) && statSync(target).isDirectory()) return target;
	} catch {
		// fall through
	}
	return dirname(target);
}

function isOutsideFrom(cwd: string, from: string, path: string): boolean {
	// Keep the lexical check separate from the real-path check. In particular,
	// a path below cwd must not be treated as outside merely because cwd (or a
	// parent of the path) is a symlink. The real-path check is still needed to
	// prevent a child symlink from escaping the workspace.
	const workspace = resolve(cwd);
	const target = expandPath(from, path);
	if (isSafeRoot(target)) return false;
	if (isAllowedDir(cwd, target)) return false;
	if (!isWithin(workspace, target)) return true;

	return !isWithin(canonicalizePath(workspace), canonicalizePath(target));
}

function isOutside(cwd: string, path: string): boolean {
	return isOutsideFrom(cwd, cwd, path);
}

const safeDevicePaths = ["/dev/null", "/dev/stdout", "/dev/stderr", "/dev/fd/", "/proc/self/fd/"];

function isSafeDevice(path: string): boolean {
	return safeDevicePaths.some((prefix) => path === prefix || (prefix.endsWith("/") && path.startsWith(prefix)));
}

/** Extract explicit path-looking strings from a shell command. */
function candidatePaths(command: string): string[] {
	const found = new Set<string>();
	const pattern = /(?:^|[\s"'>,=(:])((?:\.{1,2}(?:\/|$)|~\/|\$HOME\/|\/)[^\s"'`,;()]*)/g;
	for (const match of command.matchAll(pattern)) {
		const candidate = match[1];
		if (candidate.includes("://") || candidate.startsWith("//") || isSafeDevice(candidate)) continue;
		found.add(candidate);
	}
	return [...found];
}

const mutatingCommands = new Set([
	"rm", "rmdir", "mv", "cp", "install", "mkdir", "touch", "chmod", "chown", "ln",
	"truncate", "tee", "sed", "perl", "python", "python3", "node", "ruby", "go",
	"cargo", "npm", "pnpm", "yarn", "git", "make", "dd", "bash", "sh", "zsh", "fish",
]);

const scriptCommands = new Set([
	"bash", "sh", "zsh", "fish", "python", "python3", "node", "perl", "ruby", "php", "lua", "deno", "bun",
]);

const commandPrefixes = new Set(["sudo", "env", "command", "exec", "time", "nice"]);

function firstCommandToken(segment: string): string | undefined {
	const words = segment.trim().split(/\s+/);
	let index = 0;
	while (words[index] && commandPrefixes.has(words[index].toLowerCase())) index++;
	while (words[index] && /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[index])) index++;
	return words[index];
}

function firstCommand(segment: string): string | undefined {
	const word = firstCommandToken(segment);
	if (!word) return undefined;
	const name = word.replace(/^[(`'"]+|[)`'"]+$/g, "").toLowerCase();
	return name.split("/").pop() || name;
}

function commandIsMutating(command: string | undefined, segment: string): boolean {
	if (!command || !mutatingCommands.has(command)) return false;
	if (command === "sed" || command === "perl") return /(?:^|\s)-[^\s]*i\b/.test(segment);
	if (command === "git") {
		return /^git\s+(?:clean|reset|checkout|restore|apply|merge|rebase|stash|commit|add|rm|mv|push|pull|fetch|clone|init)\b/i.test(segment);
	}
	return true;
}

/** Scripts have no reliably parseable file arguments; require a write hint as well. */
function hasWriteHint(command: string | undefined, segment: string): boolean {
	if (!command || !scriptCommands.has(command)) return true;
	const openForWrite = /open\s*\([^)]*['"][waxr+]+['"]/i.test(segment);
	return openForWrite || /(?:write|mkdir|makedirs|unlink|remove|rmtree|copy|move|rename|chmod|chown|symlink|touch|create|dump|save|append|>\s*['"]?\/)/i.test(segment);
}

/** True only when a command explicitly targets a path outside the workspace. */
function bashMayModifyOutside(cwd: string, command: string): boolean {
	return bashOutsideTargets(cwd, command).length > 0;
}

/** Absolute paths outside the workspace that a command appears to modify. */
function bashOutsideTargets(cwd: string, command: string): string[] {
	const targets = new Set<string>();
	let effectiveCwd = resolve(cwd);

	// Heredocs and other multi-line script bodies are not split into parseable
	// segments. Scan the whole command for path-like targets in that case.
	if (command.includes("<<")) {
		const commandToken = firstCommandToken(command)?.replace(/^['"]|['"]$/g, "");
		const paths = candidatePaths(command).filter((path) => path !== commandToken);
		for (const path of paths) if (isOutsideFrom(cwd, cwd, path)) targets.add(expandPath(cwd, path));
	}

	for (const rawSegment of command.split(/&&|\|\||[|;\n]/)) {
		const segment = rawSegment.trim();
		if (!segment) continue;

		const name = firstCommand(segment);
		const words = segment.split(/\s+/).map((word) => word.replace(/^['"]|['"]$/g, ""));

		if (name === "cd") {
			const target = words.slice(1).find((word) => !word.startsWith("-"));
			if (target) effectiveCwd = expandPath(effectiveCwd, target);
			continue;
		}

		const hasOutputRedirect = /(?:^|[\s;|&])(\d+\s*)?(?:>>?>?|&>)\s*(?!<)/.test(segment);
		if (!hasOutputRedirect && !commandIsMutating(name, segment)) continue;
		if (!hasWriteHint(name, segment)) continue;

		if (name === "cp" || name === "install" || name === "mv") {
			// Only the final argument can create or modify a file outside the
			// workspace; earlier arguments are read-only sources.
			const args = words.slice(words.findIndex((word) => word === name) + 1).filter((word) => !word.startsWith("-"));
			const destination = args.at(-1);
			if (destination && isOutsideFrom(cwd, effectiveCwd, destination)) targets.add(expandPath(effectiveCwd, destination));
			continue;
		}

		// The executable itself may be invoked by its full path (e.g.
		// /usr/bin/sed). That path is not a file operand and must not be
		// mistaken for a target outside the workspace.
		const commandToken = firstCommandToken(segment)?.replace(/^['"]|['"]$/g, "");
		const paths = candidatePaths(segment).filter((path) => path !== commandToken);
		for (const path of paths) if (isOutsideFrom(cwd, effectiveCwd, path)) targets.add(expandPath(effectiveCwd, path));

		// A mutating command with no explicit path operates in effectiveCwd.
		// If that directory is outside the workspace, the operation is outside.
		if (paths.length === 0 && isOutside(cwd, effectiveCwd)) targets.add(effectiveCwd);
	}
	return [...targets];
}

function explainCommand(command: string): string {
	if (/\b(?:rm|rmdir|delete|unlink)\b/i.test(command)) {
		return "It may remove files or directories outside the workspace.";
	}
	if (/\bmv\b/i.test(command)) {
		return "It may move or rename files outside the workspace.";
	}
	if (/\b(?:cp|install)\b/i.test(command)) {
		return "It may copy or install files outside the workspace.";
	}
	if (/\b(?:mkdir|touch|truncate|tee)\b/i.test(command)) {
		return "It may create or modify files outside the workspace.";
	}
	if (/\b(?:chmod|chown|ln)\b/i.test(command)) {
		return "It may change permissions, ownership, or links outside the workspace.";
	}
	if (/>>?>?\s*[^&\s]/.test(command) || /\b(?:sed|perl|python|node|ruby)\b/i.test(command)) {
		return "It may write to files outside the workspace.";
	}
	return "It may run a shell operation that changes files outside the workspace.";
}

const ALLOW_ONCE = "Allow once";
const BLOCK = "Block";
const ALLOW_OTHER = "Always allow another directory…";
const alwaysLabel = (dir: string) => `Always allow ${dir} (and children) in this project`;

async function confirmOutside(
	ctx: ExtensionContext,
	description: string,
	explanation: string,
	targets: string[],
): Promise<boolean> {
	if (!ctx.hasUI) return false;

	const dirs = [...new Set(targets.map((t) => suggestedDir(t)))];
	const options = [ALLOW_ONCE, ...dirs.map(alwaysLabel), ALLOW_OTHER, BLOCK];
	const choice = await ctx.ui.select(
		`Allow modification outside the workspace?\n\n${explanation}\n\n${description}\n\nWorkspace: ${ctx.cwd}`,
		options,
	);
	if (!choice || choice === BLOCK) return false;
	if (choice === ALLOW_ONCE) return true;

	if (choice === ALLOW_OTHER) {
		const input = await ctx.ui.input("Directory to always allow (and its children):", dirs[0] ?? "");
		if (!input?.trim()) return false;
		const saved = addAllowedDir(ctx.cwd, expandPath(ctx.cwd, input));
		ctx.ui.notify(`Always allowed in this project: ${saved}`, "info");
		// Only proceed if the new rule actually covers every target.
		return targets.every((t) => isAllowedDir(ctx.cwd, t));
	}

	const dir = dirs.find((d) => choice === alwaysLabel(d));
	if (!dir) return false;
	const saved = addAllowedDir(ctx.cwd, dir);
	ctx.ui.notify(`Always allowed in this project: ${saved}`, "info");
	return true;
}

export { isOutside, bashMayModifyOutside, bashOutsideTargets };

export default function (pi: ExtensionAPI) {
	pi.registerCommand("allow-dir", {
		description: "Always allow modifying a directory (and its children) from this project",
		handler: async (args, ctx) => {
			let dir = args?.trim();
			if (!dir && ctx.hasUI) dir = (await ctx.ui.input("Directory to always allow (and its children):", ""))?.trim();
			if (!dir) return ctx.ui.notify("Usage: /allow-dir <path>", "warning");
			const saved = addAllowedDir(ctx.cwd, expandPath(ctx.cwd, dir));
			ctx.ui.notify(`Always allowed in this project: ${saved}`, "info");
		},
	});

	pi.registerCommand("disallow-dir", {
		description: "Remove a directory from this project's always-allowed list",
		handler: async (args, ctx) => {
			let dir = args?.trim();
			const dirs = getAllowedDirs(ctx.cwd);
			if (!dir && ctx.hasUI && dirs.length) dir = await ctx.ui.select("Remove which allowed directory?", dirs);
			if (!dir) return ctx.ui.notify("No allowed directories to remove", "info");
			const removed = removeAllowedDir(ctx.cwd, expandPath(ctx.cwd, dir));
			ctx.ui.notify(removed ? `Removed: ${dir}` : `Not in allowed list: ${dir}`, removed ? "info" : "warning");
		},
	});

	pi.registerCommand("allowed-dirs", {
		description: "List directories always allowed from this project",
		handler: async (_args, ctx) => {
			const dirs = getAllowedDirs(ctx.cwd);
			ctx.ui.notify(
				dirs.length
					? `Always allowed from ${ctx.cwd}:\n${dirs.map((d) => `  ${d}`).join("\n")}`
					: "No always-allowed directories for this project",
				"info",
			);
		},
	});

	pi.on("tool_call", async (event, ctx) => {
		if (isToolCallEventType("write", event) || isToolCallEventType("edit", event)) {
			const path = event.input.path;
			if (isOutside(ctx.cwd, path)) {
				const allowed = await confirmOutside(
					ctx,
					`${event.toolName}: ${path}`,
					`This will modify a file outside the workspace: ${path}`,
					[expandPath(ctx.cwd, path)],
				);
				if (!allowed) return { block: true, reason: `Modification outside workspace blocked: ${path}` };
			}
			return;
		}

		if (isToolCallEventType("bash", event)) {
			const targets = bashOutsideTargets(ctx.cwd, event.input.command);
			if (!targets.length) return;
			const allowed = await confirmOutside(ctx, `bash: ${event.input.command}`, explainCommand(event.input.command), targets);
			if (!allowed) return { block: true, reason: "Possible modification outside workspace blocked" };
		}
	});
}
