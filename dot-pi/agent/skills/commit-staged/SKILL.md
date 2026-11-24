---
name: commit-staged
description: Review staged Git changes, draft a commit message, and wait for explicit user approval before committing only the staged files. Use when asked to commit staged changes, make a commit from the index, or prepare a staged commit.
---

# Commit staged files

Commit only what is already in the Git index. Never stage files, use `git commit -a`, amend, or push.

## 1. Inspect the staged changes

- `git status --short` — see what is staged, unstaged, and untracked.
- `git diff --cached --stat` — summarize the staged changes.
- `git diff --cached` — read the full staged diff before writing a message.
- `git log -8 --pretty=format:%s` — match the repository's existing subject-line style.

If nothing is staged, stop and tell the user that there is nothing to commit. Do not stage anything on their behalf. If there are unstaged or untracked files, mention them briefly but leave them alone.

## 2. Draft the commit message

- One imperative subject line, ideally 72 characters or fewer, with no trailing period.
- Follow the style of recent commits in this repository; do not invent Conventional Commits prefixes unless the repository uses them.
- Add a blank line and short bullet points for the "what" and "why" only when the change needs explaining.
- If the user supplied wording (as arguments to `/skill:commit-staged` or in their request), base the draft on it.

## 3. Ask for approval — mandatory gate

Show the staged file list and the exact proposed message in a fenced block, then ask the user whether to use it.

Do not run `git commit` until the user has explicitly approved that message in a later message. Approvals include "yes", "looks good", or "commit". If the user suggests changes, revise the message and ask again. If they reject it, stop. Never treat the original request to commit as approval of your draft.

## 4. Commit

After approval, commit the approved text verbatim. Use a heredoc so multi-line messages are preserved:

```bash
git commit -F - <<'EOF'
Subject line

- Detail from the approved message
EOF
```

Do not add `Co-authored-by`, "Generated with ...", or any other trailers unless the user asked for them. If a hook fails or the command errors, report the output and stop; do not retry blindly or use `--no-verify` unless the user asks.

## 5. Verify and report

Run `git status --short` and `git log -1 --stat`, then report the commit hash and subject. Note any remaining unstaged or untracked changes without touching them.
