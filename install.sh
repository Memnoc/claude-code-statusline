#!/usr/bin/env bash
set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"

echo "Installing claude-code-statusline..."

# Renderer
mkdir -p "$CLAUDE"
cp "$REPO/statusline-command.sh" "$CLAUDE/statusline-command.sh"
chmod +x "$CLAUDE/statusline-command.sh"

# CLI (needs ~/.local/bin in PATH)
mkdir -p "$HOME/.local/bin"
cp "$REPO/bin/statusline" "$HOME/.local/bin/statusline"
chmod +x "$HOME/.local/bin/statusline"

# Default config (skip if one already exists)
if [ ! -f "$CLAUDE/statusline.conf" ]; then
  cp "$REPO/statusline.conf.example" "$CLAUDE/statusline.conf"
  echo "Created ~/.claude/statusline.conf with defaults."
else
  echo "Existing ~/.claude/statusline.conf kept."
fi

echo ""
echo "Done. Two manual steps:"
echo ""
echo "1. Add to ~/.claude/settings.json:"
cat <<'JSON'
   {
     "statusLine": {
       "type": "command",
       "command": "bash \"$HOME/.claude/statusline-command.sh\""
     }
   }
JSON
echo ""
echo "2. Add to ~/.zshrc (prevents function/binary shadowing):"
echo '   statusline() { command statusline "$@"; }'
echo ""
echo "Ensure ~/.local/bin is in PATH, then restart Claude Code."
