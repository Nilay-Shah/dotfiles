#!/usr/bin/env bash
set -euo pipefail

echo "=== Claude AI Workflow Bootstrap ==="

# Beads
if ! command -v bd &>/dev/null; then
  echo "Installing beads..."
  brew install beads
else
  echo "beads: $(bd --version 2>/dev/null || echo 'installed')"
fi

# Linear CLI
if ! command -v linear &>/dev/null; then
  echo "Installing linear CLI..."
  brew install schpet/tap/linear
  echo "  Run 'linear config' to authenticate"
else
  echo "linear: installed"
fi

# Load config
source ~/.config/claude/workflow.env

# Beads stealth init for known repos
IFS=',' read -ra repos <<< "$BEADS_REPOS"
for repo in "${repos[@]}"; do
  repo_name=$(basename "$repo")
  beads_path="$HOME/.beads/$BEADS_ORG/$repo_name"

  if [[ ! -d "$repo/.git" ]]; then
    echo "Skipping $repo (not a git repo)"
    continue
  fi

  if [[ -d "$beads_path" ]] && [[ -L "$repo/.beads" ]]; then
    echo "beads ($repo_name): already configured"
    continue
  fi

  echo "Initializing beads for $repo_name..."
  mkdir -p "$beads_path"
  (cd "$repo" && bd init --stealth --db "$beads_path/beads.db" --prefix "$repo_name" --skip-hooks 2>&1)

  # Replace .beads dir with symlink
  rm -rf "$repo/.beads"
  ln -s "$beads_path" "$repo/.beads"
  echo "  Symlinked $repo/.beads -> $beads_path"
done

# Beads Claude hooks (idempotent merge)
bd setup claude 2>/dev/null || true

# Claude plugins
if command -v claude &>/dev/null; then
  claude plugin install superpowers@claude-plugins-official 2>/dev/null || echo "superpowers: already installed or failed"
else
  echo "claude CLI not found — install Claude Code first"
fi

# Manual steps
echo ""
echo "Manual steps:"
echo "  linear config   # authenticate Linear CLI (opens browser)"
echo ""
echo "Done."
