#!/usr/bin/env bash
# FORGE compliance logging — append rule violations to project-local JSONL
# Usage:
#   bash scripts/compliance-log.sh <skill_name> <rule_key> <severity> "<details>"
#   bash scripts/compliance-log.sh view [--skill X] [--severity X] [--run X]
#
# Parameters:
#   skill_name:  e.g. build, review, ship
#   rule_key:    e.g. missing-arch-doc, stale-artifact, tdd-violation
#   severity:    critical | major | minor | info
#   details:     free-text description of the violation
set -euo pipefail

source "$(dirname "$0")/lib/colors.sh"
source "$(dirname "$0")/lib/json-helpers.sh"

COMPLIANCE_FILE=".forge/compliance.jsonl"
LOCK_FILE=".forge/.compliance.lock"

mkdir -p .forge

# Atomic append helper
append_line() {
  if command -v flock &>/dev/null; then
    flock "$LOCK_FILE" -c "printf '%s\n' '$1' >> '$COMPLIANCE_FILE'"
  else
    printf '%s\n' "$1" >> "$COMPLIANCE_FILE"
  fi
}

cmd_log() {
  local skill="${1:?Usage: compliance-log.sh <skill> <rule_key> <severity> \"<details>\"}"
  local rule="${2:?rule_key required}"
  local severity="${3:?severity required (critical|major|minor|info)}"
  local details="${4:?details required}"

  local ts; ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local project; project=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
  local run_id=""
  if [[ -f .forge/runs/latest ]]; then
    run_id=$(cat .forge/runs/latest)
  fi

  local line
  if $HAS_JQ; then
    line=$(jq -nc \
      --arg ts "$ts" \
      --arg skill "$skill" \
      --arg rule "$rule" \
      --arg sev "$severity" \
      --arg det "$details" \
      --arg proj "$project" \
      --arg rid "$run_id" \
      '{timestamp:$ts,skill:$skill,rule:$rule,severity:$sev,details:$det,project:$proj,run_id:$rid}')
  else
    line=$(python3 -c "
import json, sys
print(json.dumps({
    'timestamp': sys.argv[1],
    'skill': sys.argv[2],
    'rule': sys.argv[3],
    'severity': sys.argv[4],
    'details': sys.argv[5],
    'project': sys.argv[6],
    'run_id': sys.argv[7]
}))" "$ts" "$skill" "$rule" "$severity" "$details" "$project" "$run_id")
  fi

  append_line "$line"
  echo -e "${YELLOW}COMPLIANCE${NC} [$severity] $skill: $rule — $details"
}

cmd_view() {
  if [[ ! -f "$COMPLIANCE_FILE" ]]; then
    echo "No compliance log found at $COMPLIANCE_FILE"
    exit 0
  fi

  local filter_skill="" filter_severity="" filter_run=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skill)    filter_skill="$2"; shift 2 ;;
      --severity) filter_severity="$2"; shift 2 ;;
      --run)      filter_run="$2"; shift 2 ;;
      *)          shift ;;
    esac
  done

  if $HAS_JQ; then
    local jq_filter="."
    [[ -n "$filter_skill" ]] && jq_filter="$jq_filter | select(.skill == \"$filter_skill\")"
    [[ -n "$filter_severity" ]] && jq_filter="$jq_filter | select(.severity == \"$filter_severity\")"
    [[ -n "$filter_run" ]] && jq_filter="$jq_filter | select(.run_id == \"$filter_run\")"
    jq -c "$jq_filter" "$COMPLIANCE_FILE"
  else
    python3 -c "
import json, sys
skill_f = sys.argv[1] or None
sev_f = sys.argv[2] or None
run_f = sys.argv[3] or None
with open(sys.argv[4]) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        d = json.loads(line)
        if skill_f and d.get('skill') != skill_f: continue
        if sev_f and d.get('severity') != sev_f: continue
        if run_f and d.get('run_id') != run_f: continue
        print(json.dumps(d))
" "$filter_skill" "$filter_severity" "$filter_run" "$COMPLIANCE_FILE"
  fi
}

case "${1:-help}" in
  view) shift; cmd_view "$@" ;;
  help|-h|--help)
    echo "Usage:"
    echo "  compliance-log.sh <skill> <rule_key> <severity> \"<details>\"  — log a violation"
    echo "  compliance-log.sh view [--skill X] [--severity X] [--run X]   — view violations"
    exit 0
    ;;
  *)  cmd_log "$@" ;;
esac
