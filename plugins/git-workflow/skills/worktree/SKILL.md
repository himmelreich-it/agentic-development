---
name: worktree
description: Create a git worktree in a peer directory
argument-hint: branch-name
---

Create a git worktree in a peer directory.

## Arguments

The user passed in: `$ARGUMENTS`

Always verify whether it is already an existing branch local or remote, if so, check it out.

Otherwise, if that text is already kebab case, use it directly as the branch name, but prefix it, make sure to check whether it is a feature, bug or something else. If unclear, it is most likely a feature.
Otherwise come up with a good kebab-case name based on what the user passed in.

## Steps

1. Determine the repo root via `git rev-parse --show-toplevel`
2. Resolve the worktree root directory:
   - Check `git config worktree.root` — if set, use that value
   - Otherwise, fall back to `<repo-root>/../worktrees`
3. Create worktree path as `<worktree-root>/<branch-name>`
4. Run: `git worktree add <path> -b <branch-name>`
5. Run the local settings script: `bash ${CLAUDE_SKILL_DIR}/scripts/copy-local-settings.sh <source-root> <worktree-root>`
   This copies `.env` files, `.claude/`, `.vscode/`, `.idea/` and installs dependencies.

Do **NOT** try and copy files yourself, you do not always have access to these files.

## Conclusion

Do not switch context, the user will open a new IDE in the new folder.
Provide the user with the path and next steps.
