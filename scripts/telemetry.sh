#!/usr/bin/env bash
# FORGE telemetry — append skill invocations to local JSONL
# Usage: bash scripts/telemetry.sh <skill_name> <outcome> [classification]
#   skill_name:     e.g. think, build, review, ship
#   outcome:        completed | aborted | error
#   classification: tiny | feature | epic (optional)
set -euo pipefail

SKILL_NAME="${1:-unknown}"
OUTCOME="${2:-unknown}"
CLASSIFICATION="${3:-}"

TELEMETRY_DIR="$HOME/.forge"
TELEMETRY_FILE="$TELEMETRY_DIR/telemetry.jsonl"

# Ensure directory exists
mkdir -p "$TELEMETRY_DIR"

# Get project path (git root or cwd)
PROJECT_PATH="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Build JSON entry
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ -n "$CLASSIFICATION" ]]; then
  printf '{"skill":"%s","timestamp":"%s","project":"%s","classification":"%s","outcome":"%s"}\n' \
    "$SKILL_NAME" "$TIMESTAMP" "$PROJECT_PATH" "$CLASSIFICATION" "$OUTCOME" \
    >> "$TELEMETRY_FILE"
else
  printf '{"skill":"%s","timestamp":"%s","project":"%s","outcome":"%s"}\n' \
    "$SKILL_NAME" "$TIMESTAMP" "$PROJECT_PATH" "$OUTCOME" \
    >> "$TELEMETRY_FILE"
fi
