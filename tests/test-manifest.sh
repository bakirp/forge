#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
RST='\033[0m'

FAILS=0
SKIPS=0

pass() { printf "${GRN}PASS${RST}: %s\n" "$1"; }
fail() { printf "${RED}FAIL${RST}: %s\n" "$1"; FAILS=$((FAILS + 1)); }
skip() { printf "${YEL}SKIP${RST}: %s\n" "$1"; SKIPS=$((SKIPS + 1)); }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_TMP="${TMPDIR:-/tmp}/forge-manifest-test-$$"
mkdir -p "$TEST_TMP"
trap 'rm -rf "$TEST_TMP"' EXIT

cd "$TEST_TMP"

run_id="$("$ROOT/scripts/manifest.sh" create "manifest regression test" | tail -1)"

if [[ -f ".forge/runs/latest" ]]; then
  pass "manifest create writes .forge/runs/latest"
else
  fail "manifest create did not write .forge/runs/latest"
fi

if [[ -f ".forge/runs/$run_id/manifest.json" ]]; then
  pass "manifest create writes the run manifest file"
else
  fail "manifest create did not write .forge/runs/$run_id/manifest.json"
fi

if [[ -f ".forge/runs/latest" && "$(cat .forge/runs/latest)" == "$run_id" ]]; then
  pass "latest run pointer matches the created run id"
else
  fail "latest run pointer does not match the created run id"
fi

echo ""
echo "──────────────────────────────"
printf "Failures: %d  Skipped: %d\n" "$FAILS" "$SKIPS"
exit "$FAILS"
