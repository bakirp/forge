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
  if $HAS_JQ; then
    payload=$(jq -n --arg id "$id" --arg desc "$desc" --arg ts "$ts" \
      '{"id":$id,"task":$desc,"started":$ts,"status":"active","phase":"think","artifacts":{},"blockers":[],"history":[{"phase":"think","status":"started","timestamp":$ts}]}')
  else
    payload=$(python3 -c "import json,sys; print(json.dumps({'id':sys.argv[1],'task':sys.argv[2],'started':sys.argv[3],'status':'active','phase':'think','artifacts':{},'blockers':[],'history':[{'phase':'think','status':'started','timestamp':sys.argv[3]}]}))" "$id" "$desc" "$ts")
  fi
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
    py_write "$f" "d['phase']=sys.argv[2]; d['history'].append({'phase':sys.argv[2],'status':'started','timestamp':sys.argv[3]})" "$phase" "$ts"
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
    py_write "$f" "d['status']=sys.argv[2]; d['history'].append({'phase':d['phase'],'status':sys.argv[2],'timestamp':sys.argv[3]})" "$status" "$ts"
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
    py_write "$f" "d['artifacts'][sys.argv[2]]=sys.argv[3]" "$name" "$path"
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
    py_write "$f" "d['blockers'].append(sys.argv[2])" "$msg"
  fi
  echo -e "${YELLOW}Blocker${NC} added: $msg"
}

cmd_show() {
  local rid="${1:?Usage: manifest.sh show <run-id>}"
  local f; f=$(resolve_manifest "$rid")
  json_print "$f"
}

# Slugify a string: lowercase, hyphens, strip non-alnum, collapse, truncate 50 chars
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g' \
    | sed 's/--*/-/g' \
    | sed 's/^-//;s/-$//' \
    | cut -c1-50
}

cmd_feature_name() {
  local rid="${1:?Usage: manifest.sh feature-name <run-id> <name>}"
  local raw="${2:?feature name required}"
  local name; name=$(slugify "$raw")
  # Conflict detection: if artifacts already exist with this name, append date
  if [[ -f ".forge/build/${name}.md" ]] || [[ -f ".forge/review/${name}.md" ]] || [[ -f ".forge/verify/${name}.md" ]]; then
    name="${name}-$(date -u +%Y-%m-%d)"
  fi
  local f; f=$(resolve_manifest "$rid")
  if $HAS_JQ; then
    jq_write "$f" --arg fn "$name" '.feature_name=$fn'
  else
    py_write "$f" "d['feature_name']=sys.argv[2]" "$name"
  fi
  echo -e "${GREEN}Feature${NC} $name"
  echo "$name"
}

cmd_resolve_feature_name() {
  local latest="$RUNS_DIR/latest"
  if [[ ! -f "$latest" ]]; then
    echo "report"
    return 0
  fi
  local rid; rid=$(cat "$latest")
  local f="$RUNS_DIR/$rid/manifest.json"
  if [[ ! -f "$f" ]]; then
    echo "report"
    return 0
  fi
  local fn
  if $HAS_JQ; then
    fn=$(jq -r '.feature_name // "report"' "$f")
  else
    fn=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('feature_name','report'))" "$f")
  fi
  echo "$fn"
}

case "${1:-help}" in
  create)               shift; cmd_create "$@" ;;
  phase)                shift; cmd_phase "$@" ;;
  status)               shift; cmd_status "$@" ;;
  artifact)             shift; cmd_artifact "$@" ;;
  blocker)              shift; cmd_blocker "$@" ;;
  show)                 shift; cmd_show "$@" ;;
  feature-name)         shift; cmd_feature_name "$@" ;;
  resolve-feature-name) cmd_resolve_feature_name ;;
  *) echo "Usage: manifest.sh {create|phase|status|artifact|blocker|show|feature-name|resolve-feature-name} [args...]"; exit 1 ;;
esac
