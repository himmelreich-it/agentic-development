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

### 2. Audit upstreams correctly (authoritative checks)

For each worktree path:

```bash
git -C <path> branch --show-current
git -C <path> rev-parse --abbrev-ref --symbolic-full-name @{upstream}
```

Classify upstream status per checked-out branch:

- **Upstream set** — command returns `<remote>/<branch>`
- **Upstream missing** — command fails with "no upstream configured"
- **Upstream gone** — upstream exists but `git branch -vv` / branch format shows `[gone]`
- **Detached HEAD** — `branch --show-current` is empty; upstream does not apply

Do **NOT** infer upstream correctness from repo-wide config counts like `branch.*.merge`.

### 3. Classify each branch

For each local branch (excluding `main`/`master`):

- **Merged (regular)** — appears in `git branch --merged main`
- **Merged (squash)** — PR is closed/merged on GitHub. Check via `gh pr list --state merged --head <branch> --json number,state --limit 1`
- **Gone remote** — upstream marked `[gone]` in branch listing
- **Active** — none of the above

For each worktree path: check `git -C <path> status --short` to see if it has uncommitted work. Dirty worktrees are NEVER auto-removed.

### 4. Present findings

Show table:

```
## Worktree audit

### Stale (safe to remove)
- feature/AI-XXX (worktree: /path) — merged via PR #123
- feature/AI-YYY (no worktree) — squash-merged via PR #124

### Active
- feature/AI-ZZZ — open PR / no PR yet, branch ahead of main

### Upstream fixes needed
- feature/AI-AAA (worktree: /path) — no upstream configured; remote branch exists
- feature/AI-BBB (worktree: /path) — no upstream configured; no remote branch yet

### Dirty (skipped)
- feature/AI-WWW — has uncommitted changes, leave alone

Apply upstream fixes and remove stale ones?
```

### 5. Apply fixes / clean up (after user confirms)

For each branch missing upstream:

```bash
# If origin/<branch> exists
git -C <worktree-path> branch --set-upstream-to=origin/<branch> <branch>

# If no remote branch exists yet
git -C <worktree-path> push -u origin <branch>
```

Then, for each stale entry:

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
- `branch.<name>.merge` values alone are insufficient; always verify `@{upstream}` branch-by-branch.
