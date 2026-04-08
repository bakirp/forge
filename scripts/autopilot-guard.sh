#!/usr/bin/env bash
set -euo pipefail

# FORGE autopilot-guard: enforces iteration limits via state file + exit codes.
# State lives at .forge/autopilot/state.json — real file, real counters, real enforcement.
#
# Usage:
#   autopilot-guard.sh init [--max-inner N] [--max-outer N] [--max-total N]
#   autopilot-guard.sh check
#   autopilot-guard.sh tick <phase>
#   autopilot-guard.sh fail <phase> <issue-hash>
#   autopilot-guard.sh complete
#   autopilot-guard.sh status

source "$(dirname "$0")/lib/colors.sh"
source "$(dirname "$0")/lib/json-helpers.sh"

STATE_DIR=".forge/autopilot"
STATE_FILE="$STATE_DIR/state.json"

# --- Commands ---

cmd_init() {
  local max_inner=3 max_outer=2 max_total=15

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --max-inner)  max_inner="$2"; shift 2 ;;
      --max-outer)  max_outer="$2"; shift 2 ;;
      --max-total)  max_total="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Validate numeric inputs
  for var_name in max_inner max_outer max_total; do
    eval "val=\$$var_name"
    [[ "$val" =~ ^[0-9]+$ ]] || { echo "ERROR: --$var_name must be a positive integer, got '$val'" >&2; exit 1; }
  done

  mkdir -p "$STATE_DIR"

  local ts; ts=$(now_iso)
  local payload
  payload=$(cat <<EOF
{
  "status": "running",
  "started": "$ts",
  "max_inner": $max_inner,
  "max_outer": $max_outer,
  "max_total": $max_total,
  "inner_count": 0,
  "outer_count": 0,
  "total_count": 0,
  "current_phase": "init",
  "last_failure_hashes": [],
  "history": [{"event": "init", "timestamp": "$ts"}]
}
EOF
  )

  if $HAS_JQ; then
    printf '%s\n' "$payload" | jq . > "$STATE_FILE"
  else
    python3 -c "import json, sys; json.dump(json.loads(sys.argv[1]), open(sys.argv[2],'w'), indent=2)" "$payload" "$STATE_FILE"
  fi

  echo -e "${GREEN}GUARD${NC} initialized (inner=$max_inner, outer=$max_outer, total=$max_total)"
}

cmd_check() {
  [[ -f "$STATE_FILE" ]] || { echo -e "${RED}GUARD HALT${NC} no state file — run 'init' first" >&2; exit 1; }

  local status inner outer total max_inner max_outer max_total
  if $HAS_JQ; then
    status=$(jq_read "$STATE_FILE" '.status')
    inner=$(jq_read "$STATE_FILE" '.inner_count')
    outer=$(jq_read "$STATE_FILE" '.outer_count')
    total=$(jq_read "$STATE_FILE" '.total_count')
    max_inner=$(jq_read "$STATE_FILE" '.max_inner')
    max_outer=$(jq_read "$STATE_FILE" '.max_outer')
    max_total=$(jq_read "$STATE_FILE" '.max_total')
  else
    status=$(py_read "$STATE_FILE" "d['status']")
    inner=$(py_read "$STATE_FILE" "d['inner_count']")
    outer=$(py_read "$STATE_FILE" "d['outer_count']")
    total=$(py_read "$STATE_FILE" "d['total_count']")
    max_inner=$(py_read "$STATE_FILE" "d['max_inner']")
    max_outer=$(py_read "$STATE_FILE" "d['max_outer']")
    max_total=$(py_read "$STATE_FILE" "d['max_total']")
  fi

  if [[ "$status" == "halted" ]]; then
    echo -e "${RED}GUARD HALT${NC} autopilot was previously halted. Reset with 'init' to start a new run." >&2
    exit 1
  fi

  if [[ "$status" == "completed" ]]; then
    echo -e "${RED}GUARD HALT${NC} autopilot already completed. Run 'init' for a new session." >&2
    exit 1
  fi

  if (( inner >= max_inner )); then
    cmd_halt "inner loop exhausted ($inner/$max_inner build-review cycles)"
    exit 1
  fi

  if (( outer >= max_outer )); then
    cmd_halt "outer loop exhausted ($outer/$max_outer verify-rebuild cycles)"
    exit 1
  fi

  if (( total >= max_total )); then
    cmd_halt "total budget exhausted ($total/$max_total skill invocations)"
    exit 1
  fi

  echo -e "${GREEN}GUARD OK${NC} inner=$inner/$max_inner outer=$outer/$max_outer total=$total/$max_total"
}

cmd_tick() {
  [[ -f "$STATE_FILE" ]] || { echo -e "${RED}GUARD HALT${NC} no state file" >&2; exit 1; }

  local phase="${1:?Usage: autopilot-guard.sh tick <phase>}"
  local counter="${2:-}" # optional: "inner" or "outer" to increment loop counter
  local ts; ts=$(now_iso)

  # Batch all updates into a single read-parse-write cycle
  local counter_expr=""
  if [[ "$counter" == "inner" ]]; then
    counter_expr=" | .inner_count += 1"
  elif [[ "$counter" == "outer" ]]; then
    counter_expr=" | .outer_count += 1"
  fi

  if $HAS_JQ; then
    jq_write "$STATE_FILE" --arg p "$phase" --arg ts "$ts" \
      ".total_count += 1 | .current_phase=\$p | .history += [{\"event\":\"tick\",\"phase\":\$p,\"timestamp\":\$ts}]${counter_expr}"
  else
    local py_counter=""
    [[ "$counter" == "inner" ]] && py_counter="; d['inner_count']+=1"
    [[ "$counter" == "outer" ]] && py_counter="; d['outer_count']+=1"
    py_write "$STATE_FILE" "d['total_count']+=1; d['current_phase']=sys.argv[2]; d['history'].append({'event':'tick','phase':sys.argv[2],'timestamp':sys.argv[3]})${py_counter}" "$phase" "$ts"
  fi

  echo -e "${GREEN}GUARD TICK${NC} $phase (total=$(cmd_read_field total_count))"
}

cmd_fail() {
  [[ -f "$STATE_FILE" ]] || { echo -e "${RED}GUARD HALT${NC} no state file" >&2; exit 1; }

  local phase="${1:?Usage: autopilot-guard.sh fail <phase> <issue-hash>}"
  local issue_hash="${2:?issue-hash required}"
  local ts; ts=$(now_iso)

  # Check for repeated failure (same hash already in last_failure_hashes)
  local is_repeat=false
  if $HAS_JQ; then
    local count
    count=$(jq_read "$STATE_FILE" --arg h "$issue_hash" '[.last_failure_hashes[] | select(. == $h)] | length')
    (( count > 0 )) && is_repeat=true
  else
    local count
    count=$(py_read "$STATE_FILE" "d['last_failure_hashes'].count(sys.argv[2])" "$issue_hash")
    (( count > 0 )) && is_repeat=true
  fi

  # Record the failure
  if $HAS_JQ; then
    jq_write "$STATE_FILE" --arg h "$issue_hash" --arg p "$phase" --arg ts "$ts" \
      '.last_failure_hashes += [$h] | .history += [{"event":"fail","phase":$p,"issue":$h,"timestamp":$ts}]'
  else
    py_write "$STATE_FILE" "d['last_failure_hashes'].append(sys.argv[2]); d['history'].append({'event':'fail','phase':sys.argv[3],'issue':sys.argv[2],'timestamp':sys.argv[4]})" "$issue_hash" "$phase" "$ts"
  fi

  if $is_repeat; then
    cmd_halt "repeated failure in $phase (issue: $issue_hash)"
    exit 1
  fi

  echo -e "${YELLOW}GUARD FAIL${NC} recorded: $phase ($issue_hash)"
}

cmd_halt() {
  local reason="${1:-unknown}"
  local ts; ts=$(now_iso)

  if $HAS_JQ; then
    jq_write "$STATE_FILE" --arg r "$reason" --arg ts "$ts" \
      '.status="halted" | .halt_reason=$r | .history += [{"event":"halt","reason":$r,"timestamp":$ts}]'
  else
    py_write "$STATE_FILE" "d['status']='halted'; d['halt_reason']=sys.argv[2]; d['history'].append({'event':'halt','reason':sys.argv[2],'timestamp':sys.argv[3]})" "$reason" "$ts"
  fi

  echo -e "${RED}GUARD HALT${NC} $reason" >&2
}

cmd_complete() {
  [[ -f "$STATE_FILE" ]] || { echo -e "${RED}GUARD HALT${NC} no state file" >&2; exit 1; }

  local ts; ts=$(now_iso)

  if $HAS_JQ; then
    jq_write "$STATE_FILE" --arg ts "$ts" \
      '.status="completed" | .completed=$ts | .history += [{"event":"complete","timestamp":$ts}]'
  else
    py_write "$STATE_FILE" "d['status']='completed'; d['completed']=sys.argv[2]; d['history'].append({'event':'complete','timestamp':sys.argv[2]})" "$ts"
  fi

  echo -e "${GREEN}GUARD${NC} autopilot completed"
}

cmd_status() {
  [[ -f "$STATE_FILE" ]] || { echo "no autopilot state" >&2; exit 1; }

  if $HAS_JQ; then
    jq . "$STATE_FILE"
  else
    python3 -c "import json, sys; print(json.dumps(json.load(open(sys.argv[1])),indent=2))" "$STATE_FILE"
  fi
}

cmd_read_field() {
  local field="${1:?field required}"
  if $HAS_JQ; then
    jq_read "$STATE_FILE" ".$field"
  else
    py_read "$STATE_FILE" "d['$field']"
  fi
}

cmd_reset_inner() {
  [[ -f "$STATE_FILE" ]] || { echo -e "${RED}GUARD HALT${NC} no state file" >&2; exit 1; }

  if $HAS_JQ; then
    jq_write "$STATE_FILE" '.inner_count=0 | .last_failure_hashes=[]'
  else
    py_write "$STATE_FILE" "d['inner_count']=0; d['last_failure_hashes']=[]"
  fi

  echo -e "${GREEN}GUARD${NC} inner loop counter reset"
}

case "${1:-help}" in
  init)         shift; cmd_init "$@" ;;
  check)        cmd_check ;;
  tick)         shift; cmd_tick "$@" ;;
  fail)         shift; cmd_fail "$@" ;;
  halt)         shift; cmd_halt "$@" ;;
  complete)     cmd_complete ;;
  status)       cmd_status ;;
  reset-inner)  cmd_reset_inner ;;
  *) echo "Usage: autopilot-guard.sh {init|check|tick|fail|halt|complete|status|reset-inner} [args...]"; exit 1 ;;
esac
