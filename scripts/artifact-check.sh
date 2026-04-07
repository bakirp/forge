#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/colors.sh"
FAILURES=0

pass() { echo -e "  ${GREEN}PASS${NC} $1"; }
fail() { echo -e "  ${RED}FAIL${NC} $1"; ((FAILURES++)); }

check_exists() {
  [[ -f "$1" ]] && pass "file exists: $1" || fail "file missing: $1"
  [[ -f "$1" ]]
}

has_line() { grep -q "$2" "$1" 2>/dev/null && pass "$3" || fail "$3 missing ($2)"; }

check_architecture() {
  echo "Checking architecture: $1"
  check_exists "$1" || return
  has_line "$1" "^## Status: LOCKED" "Status: LOCKED header"
  for s in "Data Flow" "API Contract" "Test Strategy"; do has_line "$1" "## $s" "section: $s"; done
}

check_report() {
  echo "Checking $2: $1"
  check_exists "$1" || return
  has_line "$1" "^## Status:" "Status header"
  has_line "$1" "## Summary" "Summary section"
  has_line "$1" "^## commit_sha:" "commit_sha field"
  has_line "$1" "^## tree_hash:" "tree_hash field"

  # Freshness check: verify report was written against current HEAD
  local current_sha current_tree
  current_sha=$(git rev-parse HEAD 2>/dev/null) || { fail "cannot determine current HEAD"; return; }
  current_tree=$(git rev-parse "HEAD^{tree}" 2>/dev/null) || { fail "cannot determine current tree hash"; return; }

  local report_sha report_tree
  report_sha=$(grep "^## commit_sha:" "$1" | awk '{print $NF}')
  report_tree=$(grep "^## tree_hash:" "$1" | awk '{print $NF}')

  if [[ "$report_sha" == "$current_sha" ]]; then
    pass "commit_sha matches HEAD ($current_sha)"
  else
    fail "STALE: $2 report commit_sha ($report_sha) does not match HEAD ($current_sha) — re-run /$2"
  fi

  if [[ "$report_tree" == "$current_tree" ]]; then
    pass "tree_hash matches HEAD^{tree} ($current_tree)"
  else
    fail "STALE: $2 report tree_hash ($report_tree) does not match HEAD^{tree} ($current_tree) — re-run /$2"
  fi
}

check_manifest() {
  echo "Checking manifest: $1"
  check_exists "$1" || return
  if command -v jq &>/dev/null; then
    jq . "$1" >/dev/null 2>&1 && pass "valid JSON" || { fail "invalid JSON"; return; }
    for k in id task status phase; do
      jq -e ".$k" "$1" >/dev/null 2>&1 && pass "field: $k" || fail "field missing: $k"
    done
  else
    python3 -c "
import json,sys
try:
  d=json.load(open('$1'))
  print('  \033[0;32mPASS\033[0m valid JSON')
  for k in ['id','task','status','phase']:
    if k in d: print(f'  \033[0;32mPASS\033[0m field: {k}')
    else: print(f'  \033[0;31mFAIL\033[0m field missing: {k}'); sys.exit(1)
except json.JSONDecodeError:
  print('  \033[0;31mFAIL\033[0m invalid JSON'); sys.exit(1)
" || ((FAILURES++))
  fi
}

get_artifact_keys() {
  local f="$1"
  if command -v jq &>/dev/null; then jq -r '.artifacts|keys[]' "$f" 2>/dev/null
  else python3 -c "import json;[print(k) for k in json.load(open('$f')).get('artifacts',{})]"; fi
}

get_artifact_path() {
  local f="$1" k="$2"
  if command -v jq &>/dev/null; then jq -r ".artifacts[\"$k\"]" "$f"
  else python3 -c "import json;print(json.load(open('$f'))['artifacts']['$k'])"; fi
}

check_all() {
  local mf=".forge/runs/${1:?run-id required}/manifest.json"
  echo "Checking all artifacts for $1"
  check_manifest "$mf"
  [[ -f "$mf" ]] || return
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    local path; path=$(get_artifact_path "$mf" "$key")
    case "$key" in
      architecture) check_architecture "$path" ;;
      review|verify) check_report "$path" "$key" ;;
      *) echo "Checking $key: $path"; check_exists "$path" || true ;;
    esac
  done <<< "$(get_artifact_keys "$mf")"
}

case "${1:-help}" in
  architecture) shift; check_architecture "$@" ;;
  review)       shift; check_report "$1" review ;;
  verify)       shift; check_report "$1" verify ;;
  manifest)     shift; check_manifest "$@" ;;
  all)          shift; check_all "$@" ;;
  *) echo "Usage: artifact-check.sh {architecture|review|verify|manifest|all} <path|run-id>"; exit 1 ;;
esac
exit "$FAILURES"
