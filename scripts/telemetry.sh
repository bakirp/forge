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

mkdir -p "$TELEMETRY_DIR"

PROJECT_PATH="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Use jq for safe JSON construction; fall back to python3 for proper escaping
if command -v jq &>/dev/null; then
  if [[ -n "$CLASSIFICATION" ]]; then
    jq -nc --arg s "$SKILL_NAME" --arg ts "$TIMESTAMP" --arg p "$PROJECT_PATH" \
      --arg c "$CLASSIFICATION" --arg o "$OUTCOME" \
      '{skill:$s,timestamp:$ts,project:$p,classification:$c,outcome:$o}' >> "$TELEMETRY_FILE"
  else
    jq -nc --arg s "$SKILL_NAME" --arg ts "$TIMESTAMP" --arg p "$PROJECT_PATH" \
      --arg o "$OUTCOME" \
      '{skill:$s,timestamp:$ts,project:$p,outcome:$o}' >> "$TELEMETRY_FILE"
  fi
else
  python3 -c "
import json, sys
d = {'skill': sys.argv[1], 'timestamp': sys.argv[2], 'project': sys.argv[3], 'outcome': sys.argv[4]}
if sys.argv[5]: d['classification'] = sys.argv[5]
print(json.dumps(d))
" "$SKILL_NAME" "$TIMESTAMP" "$PROJECT_PATH" "$OUTCOME" "$CLASSIFICATION" >> "$TELEMETRY_FILE"
fi
