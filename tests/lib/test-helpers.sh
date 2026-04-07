#!/usr/bin/env bash
# Shared test helpers for FORGE test suite

# Source shared colors, then alias short names for test convenience
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/lib/colors.sh"
GRN=$GREEN
YEL=$YELLOW
RST=$NC

FAILS=0
SKIPS=0

pass() { printf "%sPASS%s: %s\n" "$GRN" "$RST" "$1"; }
fail() { printf "%sFAIL%s: %s\n" "$RED" "$RST" "$1"; FAILS=$((FAILS + 1)); }
skip() { printf "%sSKIP%s: %s\n" "$YEL" "$RST" "$1"; SKIPS=$((SKIPS + 1)); }
warn() { printf "%sWARN%s: %s\n" "$YEL" "$RST" "$1"; }

# BASH_SOURCE[1] = the script that sourced this file (the test script).
# This assumes test-helpers.sh is sourced directly from the test — not transitively.
ROOT="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"

# setup_test_tmp <name> — create temp dir and register cleanup trap
setup_test_tmp() {
  local name="${1:-forge-test}"
  TEST_TMP="${TMPDIR:-/tmp}/${name}-$$"
  mkdir -p "$TEST_TMP"
  trap 'rm -rf "$TEST_TMP"' EXIT
}

# print_test_summary [total] — print pass/fail/skip counts and exit
# If total is provided, shows "N passed, N failed, N skipped" with coloring
print_test_summary() {
  local total="${1:-}"
  echo ""
  echo "──────────────────────────────"
  if [[ -n "$total" ]]; then
    local passed=$((total - FAILS - SKIPS))
    if [[ $FAILS -gt 0 ]]; then
      printf "%s%d failed%s, %d passed, %d skipped\n" "$RED" "$FAILS" "$RST" "$passed" "$SKIPS"
    else
      printf "%sAll %d tests passed%s, %d skipped\n" "$GRN" "$passed" "$RST" "$SKIPS"
    fi
  else
    printf "Failures: %d  Skipped: %d\n" "$FAILS" "$SKIPS"
  fi
  [[ $FAILS -eq 0 ]] && exit 0 || exit 1
}
