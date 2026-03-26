#!/usr/bin/env bash
# Setup script for ai-skills + gstack
# Installs both skill sets into ~/.claude/skills/ via symlinks.
# Idempotent — safe to re-run.

set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
AI_SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
GSTACK_DIR="$HOME/Projects/gstack"
GSTACK_REPO="https://github.com/garrytan/gstack.git"

echo "=== ai-skills setup ==="
echo ""

# Ensure ~/.claude/skills exists
mkdir -p "$SKILLS_DIR"

# --- ai-skills (this repo) ---
echo "1. Linking ai-skills into $SKILLS_DIR..."

for skill_dir in "$AI_SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  # Skip hidden dirs and non-skill dirs
  [[ "$skill_name" == .* ]] && continue

  target="$SKILLS_DIR/$skill_name"
  if [ -L "$target" ] || [ -e "$target" ]; then
    echo "   $skill_name — already exists, skipping"
  else
    ln -s "$skill_dir" "$target"
    echo "   $skill_name — linked"
  fi
done

echo ""

# --- gstack ---
echo "2. Setting up gstack..."

if [ -d "$GSTACK_DIR" ]; then
  echo "   gstack repo found at $GSTACK_DIR"
  echo "   Pulling latest..."
  (cd "$GSTACK_DIR" && git pull --ff-only 2>/dev/null || echo "   (pull skipped — may have local changes)")
else
  echo "   Cloning gstack to $GSTACK_DIR..."
  git clone "$GSTACK_REPO" "$GSTACK_DIR"
fi

# Link gstack into skills dir
if [ -L "$SKILLS_DIR/gstack" ] || [ -e "$SKILLS_DIR/gstack" ]; then
  echo "   gstack symlink already exists in $SKILLS_DIR"
else
  ln -s "$GSTACK_DIR" "$SKILLS_DIR/gstack"
  echo "   gstack — linked"
fi

# Run gstack's own setup if it exists
if [ -x "$GSTACK_DIR/setup" ]; then
  echo "   Running gstack setup..."
  (cd "$GSTACK_DIR" && ./setup)
fi

echo ""
echo "=== Done ==="
echo ""
echo "Installed skills:"
ls -1 "$SKILLS_DIR" | grep -v '^\.' | sort
