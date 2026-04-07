#!/usr/bin/env bash
# FORGE telemetry — append skill invocations to local JSONL
# Usage:
#   bash scripts/telemetry.sh <skill_name> <outcome> [classification]
#   bash scripts/telemetry.sh phase-transition <skill_name> [token_estimate] [tool_calls]
#
# Commands:
#   <skill_name> <outcome>     — log skill completion (original behavior)
#   phase-transition           — log context metrics at skill boundary
#
# Parameters:
#   skill_name:     e.g. think, build, review, ship
#   outcome:        completed | aborted | error
#   classification: tiny | feature | epic (optional)
#   token_estimate: approximate context token count (optional)
#   tool_calls:     number of tool calls in this phase (optional)
set -euo pipefail

TELEMETRY_DIR="$HOME/.forge"
TELEMETRY_FILE="$TELEMETRY_DIR/telemetry.jsonl"

mkdir -p "$TELEMETRY_DIR"

PROJECT_PATH="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# --- phase-transition: log context metrics at skill boundaries ---
if [[ "${1:-}" == "phase-transition" ]]; then
  SKILL_NAME="${2:-unknown}"
  TOKEN_ESTIMATE="${3:-0}"
  TOOL_CALLS="${4:-0}"

  # Measure artifact sizes if they exist
  ARCH_SIZE=0
  BUILD_REPORT_SIZE=0
  REVIEW_SIZE=0
  VERIFY_SIZE=0
  if [[ -d .forge/architecture ]]; then
    ARCH_SIZE=$(wc -c .forge/architecture/*.md 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
  fi
  if [[ -f .forge/build/report.md ]]; then
    BUILD_REPORT_SIZE=$(wc -c < .forge/build/report.md 2>/dev/null || echo 0)
  fi
  if [[ -f .forge/review/report.md ]]; then
    REVIEW_SIZE=$(wc -c < .forge/review/report.md 2>/dev/null || echo 0)
  fi
  if [[ -f .forge/verify/report.md ]]; then
    VERIFY_SIZE=$(wc -c < .forge/verify/report.md 2>/dev/null || echo 0)
  fi

  if command -v jq &>/dev/null; then
    jq -nc \
      --arg type "phase-transition" \
      --arg skill "$SKILL_NAME" \
      --arg ts "$TIMESTAMP" \
      --arg p "$PROJECT_PATH" \
      --argjson tokens "${TOKEN_ESTIMATE:-0}" \
      --argjson tools "${TOOL_CALLS:-0}" \
      --argjson arch "$ARCH_SIZE" \
      --argjson build_report "$BUILD_REPORT_SIZE" \
      --argjson review "$REVIEW_SIZE" \
      --argjson verify "$VERIFY_SIZE" \
      '{type:$type,skill:$skill,timestamp:$ts,project:$p,token_estimate:$tokens,tool_calls:$tools,artifacts:{architecture_bytes:$arch,build_report_bytes:$build_report,review_bytes:$review,verify_bytes:$verify}}' >> "$TELEMETRY_FILE"
  else
    python3 -c "
import json, sys
print(json.dumps({
    'type': 'phase-transition',
    'skill': sys.argv[1],
    'timestamp': sys.argv[2],
    'project': sys.argv[3],
    'token_estimate': int(sys.argv[4]),
    'tool_calls': int(sys.argv[5]),
    'artifacts': {
        'architecture_bytes': int(sys.argv[6]),
        'build_report_bytes': int(sys.argv[7]),
        'review_bytes': int(sys.argv[8]),
        'verify_bytes': int(sys.argv[9])
    }
}))
" "$SKILL_NAME" "$TIMESTAMP" "$PROJECT_PATH" "$TOKEN_ESTIMATE" "$TOOL_CALLS" \
  "$ARCH_SIZE" "$BUILD_REPORT_SIZE" "$REVIEW_SIZE" "$VERIFY_SIZE" >> "$TELEMETRY_FILE"
  fi
  exit 0
fi

# --- standard skill invocation logging ---
SKILL_NAME="${1:-unknown}"
OUTCOME="${2:-unknown}"
CLASSIFICATION="${3:-}"

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
