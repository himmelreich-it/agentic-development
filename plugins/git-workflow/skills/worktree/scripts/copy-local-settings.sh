#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="${1:?Usage: $0 <source-root> <worktree-root>}"
WORKTREE_ROOT="${2:?Usage: $0 <source-root> <worktree-root>}"

# Copy all .env* files
for f in "$SOURCE_ROOT"/.env*; do
  [ -e "$f" ] || continue
  cp "$f" "$WORKTREE_ROOT/"
  echo "Copied $(basename "$f")"
done

# Copy .claude directory
if [ -d "$SOURCE_ROOT/.claude" ]; then
  cp -R "$SOURCE_ROOT/.claude" "$WORKTREE_ROOT/"
  echo "Copied .claude/"
fi

# Copy .vscode directory
if [ -d "$SOURCE_ROOT/.vscode" ]; then
  cp -R "$SOURCE_ROOT/.vscode" "$WORKTREE_ROOT/"
  echo "Copied .vscode/"
fi

# Copy .idea directory (selective — skip user-specific files)
if [ -d "$SOURCE_ROOT/.idea" ]; then
  IDEA_EXCLUDE=(
    workspace.xml
    tasks.xml
    usage.statistics.xml
    shelf
    dataSources.local.xml
    dynamic.xml
    sonarlint
  )

  mkdir -p "$WORKTREE_ROOT/.idea"
  for item in "$SOURCE_ROOT/.idea"/*; do
    name="$(basename "$item")"
    skip=false
    for exc in "${IDEA_EXCLUDE[@]}"; do
      if [ "$name" = "$exc" ]; then
        skip=true
        break
      fi
    done
    if [ "$skip" = false ]; then
      cp -R "$item" "$WORKTREE_ROOT/.idea/"
    fi
  done
  echo "Copied .idea/ (excluding workspace.xml, tasks.xml, and other user-specific files)"
fi

# Install dependencies
if [ -f "$WORKTREE_ROOT/pyproject.toml" ]; then
  echo "Installing dependencies..."
  (cd "$WORKTREE_ROOT" && uv sync)
fi

echo "Done."
