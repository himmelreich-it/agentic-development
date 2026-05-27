---
name: git-tidy
description: Audit and tidy the local repo — analyze git worktrees and local branches, flag stale ones (merged to main, including via squash-merge) and dirty ones, then clean them after user confirmation. Use when user asks to tidy, clean, prune, audit, or check worktrees/branches.
user_invocable: true
---

Analyze worktrees and local branches in the current repo, identify stale ones, propose cleanup, then act after user confirms.

Squash-merged branches don't show up under `git branch --merged`, so we must detect them via PR state on GitHub (`gh`) or by comparing the branch's tree against `main`.

## Workflow

### 1. Gather state

Run in parallel from repo root:

```bash
git worktree list
git branch --format='%(refname:short) %(upstream:short) %(upstream:track)'
git fetch --prune origin
```

### 2. Classify each branch

For each local branch (excluding `main`/`master`):

- **Merged (regular)** — appears in `git branch --merged main`
- **Merged (squash)** — PR is closed/merged on GitHub. Check via `gh pr list --state merged --head <branch> --json number,state --limit 1`
- **Gone remote** — upstream marked `[gone]` in branch listing
- **Active** — none of the above

For each worktree path: check `git -C <path> status --short` to see if it has uncommitted work. Dirty worktrees are NEVER auto-removed.

### 3. Present findings

Show table:

```
## Worktree audit

### Stale (safe to remove)
- feature/AI-XXX (worktree: /path) — merged via PR #123
- feature/AI-YYY (no worktree) — squash-merged via PR #124

### Active
- feature/AI-ZZZ — open PR / no PR yet, branch ahead of main

### Dirty (skipped)
- feature/AI-WWW — has uncommitted changes, leave alone

Remove the stale ones?
```

### 4. Clean up (after user confirms)

For each stale entry:

```bash
# IMPORTANT: cd to repo root first; never run from inside a worktree you're about to delete
cd <repo-root>

# Worktree (if exists)
git worktree remove <path>

# Branch (use -D since squash-merge isn't recognized by -d)
git branch -D <branch>
```

Then `git worktree prune` to clean any stale admin records.

## Gotchas

- Never `cd` into a worktree you're about to delete — Bash will lose its cwd.
- `git branch -d` refuses squash-merged branches; use `-D`.
- Sandbox may block writes to `.git/config`; branch delete still succeeds but emits warnings — safe to ignore.
- If `gh` is missing or unauthenticated, fall back to tree-comparison: `git cherry main <branch>` empty output = all commits present in main.
