#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/host-detect.sh
# Detects: claude-code, codex, cursor, unknown
# Outputs the detected host name

# Detection logic:
# - Claude Code: check for ~/.claude/ directory or CLAUDE_CODE env var
# - Codex: check for codex CLI or CODEX env var
# - Cursor: check for .cursor/ directory or CURSOR env var
# - Unknown: fallback

detect_host() {
    if [ -d "$HOME/.claude" ] || [ -n "${CLAUDE_CODE:-}" ]; then
        echo "claude-code"
    elif command -v codex &>/dev/null || [ -n "${CODEX:-}" ]; then
        echo "codex"
    elif [ -d ".cursor" ] || [ -n "${CURSOR:-}" ]; then
        echo "cursor"
    else
        echo "unknown"
    fi
}

HOST=$(detect_host)
echo "$HOST"
