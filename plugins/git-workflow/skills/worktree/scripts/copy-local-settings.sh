#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="${1:?Usage: $0 <source-root> <worktree-root>}"
WORKTREE_ROOT="${2:?Usage: $0 <source-root> <worktree-root>}"

# Symlink all .env* files (symlinks don't trigger the sandbox read deny rule
# on .env, and keep worktrees in sync with the source).
# Skip .env.example — it's committed to git, use the branch's version.
shopt -s nullglob
for f in "$SOURCE_ROOT"/.env*; do
  name="$(basename "$f")"
  if [ "$name" = ".env.example" ]; then
    continue
  fi
  ln -sfn "$f" "$WORKTREE_ROOT/$name"
  echo "Linked $name"
done
shopt -u nullglob

# Copy .claude directory, then replace settings.local.json with a symlink
# so local permission/hook tweaks stay in sync across worktrees.
if [ -d "$SOURCE_ROOT/.claude" ]; then
  cp -R "$SOURCE_ROOT/.claude" "$WORKTREE_ROOT/"
  echo "Copied .claude/"
  if [ -f "$SOURCE_ROOT/.claude/settings.local.json" ]; then
    ln -sfn "$SOURCE_ROOT/.claude/settings.local.json" "$WORKTREE_ROOT/.claude/settings.local.json"
    echo "Linked .claude/settings.local.json"
  fi
fi

# Symlink CLAUDE.local.md if present
if [ -f "$SOURCE_ROOT/CLAUDE.local.md" ]; then
  ln -sfn "$SOURCE_ROOT/CLAUDE.local.md" "$WORKTREE_ROOT/CLAUDE.local.md"
  echo "Linked CLAUDE.local.md"
fi

# Copy .vscode directory
if [ -d "$SOURCE_ROOT/.vscode" ]; then
  cp -R "$SOURCE_ROOT/.vscode" "$WORKTREE_ROOT/"
  echo "Copied .vscode/"
fi

# Copy .idea directory (selective — skip user-specific files and
# interpreter-bound config so the worktree gets a fresh Python SDK).
if [ -d "$SOURCE_ROOT/.idea" ]; then
  # Exclude patterns support shell globs (e.g. *.iml).
  IDEA_EXCLUDE=(
    workspace.xml
    tasks.xml
    usage.statistics.xml
    shelf
    dataSources.local.xml
    dynamic.xml
    sonarlint
    misc.xml   # pins project SDK — would point the worktree at the source repo's venv
    '*.iml'    # module file pins jdkName — same problem
  )

  mkdir -p "$WORKTREE_ROOT/.idea"
  for item in "$SOURCE_ROOT/.idea"/*; do
    name="$(basename "$item")"
    skip=false
    for exc in "${IDEA_EXCLUDE[@]}"; do
      # shellcheck disable=SC2053 # intentional glob match
      if [[ "$name" == $exc ]]; then
        skip=true
        break
      fi
    done
    if [ "$skip" = false ]; then
      cp -R "$item" "$WORKTREE_ROOT/.idea/"
    fi
  done
  echo "Copied .idea/ (excluding user-specific and interpreter-bound files)"
fi

# Install dependencies
if [ -f "$WORKTREE_ROOT/pyproject.toml" ]; then
  echo "Installing dependencies..."
  (cd "$WORKTREE_ROOT" && uv sync)
fi

echo "Done."
