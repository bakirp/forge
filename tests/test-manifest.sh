#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
setup_test_tmp "forge-manifest-test"

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

print_test_summary
