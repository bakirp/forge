#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"

if ! command -v node >/dev/null 2>&1; then
  skip "node is not installed — cannot run pg-agent tests"
  print_test_summary 1
fi

if [[ ! -d "$ROOT/node_modules" ]]; then
  skip "node_modules is missing — run npm install before pg-agent tests"
  print_test_summary 1
fi

if (cd "$ROOT" && node --test tests/node/*.test.mjs); then
  pass "pg-agent node test suite passes"
else
  fail "pg-agent node test suite failed"
fi

print_test_summary 1
