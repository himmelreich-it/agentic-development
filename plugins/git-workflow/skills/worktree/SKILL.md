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
4. Resolve branch source before creating the worktree:
   - If local branch exists: use it directly
   - Else if `origin/<branch-name>` exists: create a local tracking branch from it
   - Else: create a new branch from `origin/HEAD` (fallback to `origin/main` if needed)
5. Create the worktree with the matching command:
   - Local branch: `git worktree add <path> <branch-name>`
   - Remote-only branch: `git worktree add --track -b <branch-name> <path> origin/<branch-name>`
   - New branch: `git worktree add -b <branch-name> <path> <default-base>`
6. Verify upstream in the created worktree:
   - `git -C <path> rev-parse --abbrev-ref --symbolic-full-name @{upstream}`
7. If upstream is missing:
   - If `origin/<branch-name>` exists: run `git -C <path> branch --set-upstream-to=origin/<branch-name> <branch-name>`
   - If this is a brand-new branch with no remote branch yet: state explicitly that upstream cannot exist yet and instruct first push with `git -C <path> push -u origin <branch-name>`
8. Run the local settings script: `bash ${CLAUDE_SKILL_DIR}/scripts/copy-local-settings.sh <source-root> <worktree-root>`
   This copies `.env` files, `.claude/`, `.vscode/`, `.idea/` and installs dependencies.

Do **NOT** try and copy files yourself, you do not always have access to these files.
Do **NOT** claim upstreams are correct from global config counts like `branch.*.merge`; only per-branch `@{upstream}` checks are authoritative.

## Conclusion

Do not switch context, the user will open a new IDE in the new folder.
Provide the user with the path, branch name, and exact upstream status (set / missing / gone).
