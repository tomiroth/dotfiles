/**
 * pi-vim add-on: `yc` in NORMAL mode copies the latest fenced code block from
 * the most recent assistant messages to the clipboard.
 *
 * `yc` is not a valid Vim sequence (pi-vim would just cancel the pending `y`),
 * so intercepting the `c` while pi-vim has a bare pending `y` is safe.
 *
 * Also exposes `/yank-code [n]` (n = 1 for latest, 2 for the one before, ...).
 */

import { copyToClipboard, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";

const FENCE_RE = /^[ \t]*(`{3,}|~{3,})[^\n]*\n([\s\S]*?)\n[ \t]*\1[ \t]*$/gm;

function extractCodeBlocks(text: string): string[] {
	const blocks: string[] = [];
	for (const m of text.matchAll(FENCE_RE)) blocks.push(m[2]);
	return blocks;
}

/** Returns code blocks newest-first across the current branch. */
function findCodeBlocks(ctx: ExtensionContext): string[] {
	const result: string[] = [];
	const branch = ctx.sessionManager.getBranch() as any[];
	for (let i = branch.length - 1; i >= 0; i--) {
		const entry = branch[i];
		if (entry?.type !== "message" || entry.message?.role !== "assistant") continue;
		const content = entry.message.content;
		const text = Array.isArray(content)
			? content.filter((c: any) => c?.type === "text").map((c: any) => c.text).join("\n")
			: typeof content === "string"
				? content
				: "";
		result.push(...extractCodeBlocks(text).reverse());
	}
	return result;
}

export default function (pi: ExtensionAPI) {
	let currentCtx: ExtensionContext | undefined;

	async function yank(ctx: ExtensionContext, n = 1) {
		const blocks = findCodeBlocks(ctx);
		const block = blocks[n - 1];
		if (block === undefined) {
			ctx.ui.notify(n === 1 ? "No code block found" : `Code block #${n} not found`, "warning");
			return;
		}
		try {
			await copyToClipboard(block);
			const lines = block.split("\n").length;
			ctx.ui.notify(`Copied code block (${lines} line${lines === 1 ? "" : "s"})`, "info");
		} catch (err) {
			ctx.ui.notify(`Copy failed: ${(err as Error).message}`, "error");
		}
	}

	pi.registerCommand("yank-code", {
		description: "Copy the latest code block (or the nth latest) to the clipboard",
		handler: async (args, ctx) => {
			const n = Math.max(1, Number.parseInt(args?.trim() || "1", 10) || 1);
			await yank(ctx, n);
		},
	});

	pi.on("session_start", (_event, ctx) => {
		currentCtx = ctx;
		// Defer so pi-vim's session_start handler has installed its editor first.
		setTimeout(() => {
			const previous = ctx.ui.getEditorComponent();
			if (!previous) return;
			ctx.ui.setEditorComponent((tui, theme, kb) => {
				const editor: any = previous(tui, theme, kb);
				if (!editor || typeof editor.getMode !== "function" || editor.__yankCodePatched) return editor;
				editor.__yankCodePatched = true;
				const original = editor.handleInput.bind(editor);
				editor.handleInput = (data: string) => {
					if (
						data === "c" &&
						editor.getMode() === "normal" &&
						editor.pendingOperator === "y" &&
						!editor.pendingMotion &&
						!editor.pendingTextObject &&
						!editor.operatorCount
					) {
						if (typeof editor.cancelPendingOperator === "function") editor.cancelPendingOperator();
						else editor.pendingOperator = null;
						if (currentCtx) void yank(currentCtx);
						editor.invalidate?.();
						return;
					}
					return original(data);
				};
				return editor;
			});
		}, 0);
	});
}
