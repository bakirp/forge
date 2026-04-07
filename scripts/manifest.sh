#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/colors.sh"
source "$(dirname "$0")/lib/json-helpers.sh"

RUNS_DIR=".forge/runs"

cmd_create() {
  local desc="${1:?Usage: manifest.sh create \"description\"}"
  local id="run-$(date -u +%Y%m%d-%H%M%S)"
  local dir="$RUNS_DIR/$id"
  mkdir -p "$dir"
  local ts; ts=$(now_iso)
  local payload
  payload=$(cat <<EOF
{"id":"$id","task":"$desc","started":"$ts","status":"active","phase":"think","artifacts":{},"blockers":[],"history":[{"phase":"think","status":"started","timestamp":"$ts"}]}
EOF
  )
  json_create "$payload" "$dir/manifest.json"
  printf '%s\n' "$id" > "$RUNS_DIR/latest"
  echo -e "${GREEN}Created${NC} $id"
  echo "$id"
}

resolve_manifest() {
  local f="$RUNS_DIR/${1:?run-id required}/manifest.json"
  [[ -f "$f" ]] || { echo -e "${RED}FAIL${NC} manifest not found: $f" >&2; exit 1; }
  echo "$f"
}

cmd_phase() {
  local rid="${1:?Usage: manifest.sh phase <run-id> <phase>}"
  local phase="${2:?phase required}"
  local f; f=$(resolve_manifest "$rid")
  local ts; ts=$(now_iso)
  if $HAS_JQ; then
    jq_write "$f" --arg p "$phase" --arg ts "$ts" \
      '.phase=$p | .history += [{"phase":$p,"status":"started","timestamp":$ts}]'
  else
    py_write "$f" "d['phase']='$phase'; d['history'].append({'phase':'$phase','status':'started','timestamp':'$ts'})"
  fi
  echo -e "${GREEN}Phase${NC} -> $phase"
}

cmd_status() {
  local rid="${1:?Usage: manifest.sh status <run-id> <status>}"
  local status="${2:?status required}"
  local f; f=$(resolve_manifest "$rid")
  local ts; ts=$(now_iso)
  if $HAS_JQ; then
    jq_write "$f" --arg s "$status" --arg ts "$ts" \
      '.status=$s | .history += [{"phase":.phase,"status":$s,"timestamp":$ts}]'
  else
    py_write "$f" "d['status']='$status'; d['history'].append({'phase':d['phase'],'status':'$status','timestamp':'$ts'})"
  fi
  echo -e "${GREEN}Status${NC} -> $status"
}

cmd_artifact() {
  local rid="${1:?Usage: manifest.sh artifact <run-id> <name> <path>}"
  local name="${2:?artifact name required}" path="${3:?artifact path required}"
  local f; f=$(resolve_manifest "$rid")
  if $HAS_JQ; then
    jq_write "$f" --arg n "$name" --arg p "$path" '.artifacts[$n]=$p'
  else
    py_write "$f" "d['artifacts']['$name']='$path'"
  fi
  echo -e "${GREEN}Artifact${NC} $name -> $path"
}

cmd_blocker() {
  local rid="${1:?Usage: manifest.sh blocker <run-id> \"message\"}"
  local msg="${2:?blocker message required}"
  local f; f=$(resolve_manifest "$rid")
  if $HAS_JQ; then
    jq_write "$f" --arg m "$msg" '.blockers += [$m]'
  else
    py_write "$f" "d['blockers'].append('$msg')"
  fi
  echo -e "${YELLOW}Blocker${NC} added: $msg"
}

cmd_show() {
  local rid="${1:?Usage: manifest.sh show <run-id>}"
  local f; f=$(resolve_manifest "$rid")
  json_print "$f"
}

case "${1:-help}" in
  create)   shift; cmd_create "$@" ;;
  phase)    shift; cmd_phase "$@" ;;
  status)   shift; cmd_status "$@" ;;
  artifact) shift; cmd_artifact "$@" ;;
  blocker)  shift; cmd_blocker "$@" ;;
  show)     shift; cmd_show "$@" ;;
  *) echo "Usage: manifest.sh {create|phase|status|artifact|blocker|show} [args...]"; exit 1 ;;
esac
