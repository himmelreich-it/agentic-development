# Worktree Skill

Creates git worktrees in an organized directory, copies local settings (`.env`, `.claude/`, `.vscode/`, `.idea/`), and installs dependencies.

It also ensures branch checkout/upstream handling is correct:
- Existing local branch → checked out directly in the new worktree
- Existing remote branch (`origin/<branch>`) → checked out as a local tracking branch
- Brand-new branch → created from default base; upstream is intentionally absent until first push (`git push -u`)

## Usage

```
/worktree feature/my-branch
/worktree AI-400-new-feature
```

## Worktree Location

The skill resolves the worktree directory in order:

1. **Git config** `worktree.root` — if set, worktrees are created here
2. **Fallback** — `<repo-root>/../worktrees/`

### Configure a custom location

```bash
# Per-repo (recommended)
git config worktree.root ~/code/worktrees

# Global (all repos)
git config --global worktree.root ~/code/worktrees
```

With this config and a branch named `feature/AI-400-new-feature`, the worktree is created at:

```
~/code/worktrees/feature/AI-400-new-feature/
```

Without the config, it falls back to a `worktrees/` sibling directory next to your repo.
