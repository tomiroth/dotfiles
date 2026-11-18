import { existsSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
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

function isOutsideFrom(cwd: string, from: string, path: string): boolean {
	// Keep the lexical check separate from the real-path check. In particular,
	// a path below cwd must not be treated as outside merely because cwd (or a
	// parent of the path) is a symlink. The real-path check is still needed to
	// prevent a child symlink from escaping the workspace.
	const workspace = resolve(cwd);
	const target = expandPath(from, path);
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

function firstCommand(segment: string): string | undefined {
	const words = segment.trim().split(/\s+/);
	let index = 0;
	while (words[index] && commandPrefixes.has(words[index].toLowerCase())) index++;
	while (words[index] && /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[index])) index++;
	const word = words[index];
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
	let effectiveCwd = resolve(cwd);

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

		if (name === "cp" || name === "install") {
			// Only the final argument can create or modify a file outside the
			// workspace; earlier arguments are read-only sources.
			const args = words.slice(words.findIndex((word) => word === name) + 1).filter((word) => !word.startsWith("-"));
			const destination = args.at(-1);
			if (destination && isOutsideFrom(cwd, effectiveCwd, destination)) return true;
			continue;
		}

		if (candidatePaths(segment).some((path) => isOutsideFrom(cwd, effectiveCwd, path))) return true;
	}
	return false;
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

async function confirmOutside(
	ctx: ExtensionContext,
	description: string,
	explanation: string,
): Promise<boolean> {
	if (!ctx.hasUI) return false;
	return ctx.ui.confirm(
		"Allow modification outside the workspace?",
		`${explanation}\n\n${description}\n\nWorkspace: ${ctx.cwd}`,
	);
}

export { isOutside, bashMayModifyOutside };

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (isToolCallEventType("write", event) || isToolCallEventType("edit", event)) {
			const path = event.input.path;
			if (isOutside(ctx.cwd, path)) {
				const allowed = await confirmOutside(
					ctx,
					`${event.toolName}: ${path}`,
					`This will modify a file outside the workspace: ${path}`,
				);
				if (!allowed) return { block: true, reason: `Modification outside workspace blocked: ${path}` };
			}
			return;
		}

		if (isToolCallEventType("bash", event) && bashMayModifyOutside(ctx.cwd, event.input.command)) {
			const allowed = await confirmOutside(
				ctx,
				`bash: ${event.input.command}`,
				explainCommand(event.input.command),
			);
			if (!allowed) return { block: true, reason: "Possible modification outside workspace blocked" };
		}
	});
}
