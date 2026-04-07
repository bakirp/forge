#!/usr/bin/env bash
set -euo pipefail

# FORGE test: autopilot-guard enforcement
# Run from project root: bash tests/test-autopilot-guard.sh

source "$(dirname "$0")/lib/test-helpers.sh"
GUARD="$ROOT/scripts/autopilot-guard.sh"
TEST_TMP="${TMPDIR:-/tmp}/forge-guard-test-$$"

# Run guard in an isolated temp dir so we don't touch real .forge/
setup_sandbox() {
  rm -rf "$TEST_TMP"
  mkdir -p "$TEST_TMP"
  cd "$TEST_TMP"
}

teardown_sandbox() {
  cd "$ROOT"
  rm -rf "$TEST_TMP"
}

trap teardown_sandbox EXIT

# ── 1. Guard script exists and is executable ──

if [[ -x "$GUARD" ]]; then
  pass "autopilot-guard.sh exists and is executable"
else
  fail "autopilot-guard.sh missing or not executable"
fi

# ── 2. Init creates state file ──

setup_sandbox
bash "$GUARD" init --max-inner 2 --max-outer 1 --max-total 5 > /dev/null

if [[ -f ".forge/autopilot/state.json" ]]; then
  pass "init creates state file"
else
  fail "init did not create state file"
fi

# ── 3. Check passes after init ──

if bash "$GUARD" check > /dev/null 2>&1; then
  pass "check passes on fresh init"
else
  fail "check failed on fresh init"
fi

# ── 4. Tick increments total counter ──

bash "$GUARD" tick brainstorm > /dev/null
bash "$GUARD" tick architect > /dev/null

# Read total_count
TOTAL=$(python3 -c "import json; print(json.load(open('.forge/autopilot/state.json'))['total_count'])")
if [[ "$TOTAL" == "2" ]]; then
  pass "tick increments total_count (got $TOTAL)"
else
  fail "tick total_count expected 2, got $TOTAL"
fi

# ── 5. Tick with 'inner' increments inner counter ──

bash "$GUARD" tick review inner > /dev/null

INNER=$(python3 -c "import json; print(json.load(open('.forge/autopilot/state.json'))['inner_count'])")
if [[ "$INNER" == "1" ]]; then
  pass "tick with 'inner' increments inner_count (got $INNER)"
else
  fail "tick inner_count expected 1, got $INNER"
fi

# ── 6. Inner limit enforcement ──

bash "$GUARD" tick review inner > /dev/null

# Now inner_count=2 which equals max_inner=2 — next check should HALT
if bash "$GUARD" check > /dev/null 2>&1; then
  fail "check should have halted at inner limit (2/2) but passed"
else
  pass "check correctly halts at inner limit (2/2)"
fi

# ── 7. Reset-inner allows continued operation ──

# Re-init for a clean state to test reset-inner flow
teardown_sandbox
setup_sandbox
bash "$GUARD" init --max-inner 2 --max-outer 1 --max-total 10 > /dev/null
bash "$GUARD" tick review inner > /dev/null
bash "$GUARD" tick review inner > /dev/null

# Inner is now at limit — reset it
bash "$GUARD" reset-inner > /dev/null

# Status should be back to running (need to un-halt first — re-init cleanly)
# Actually reset-inner resets the counter but status was set to halted by the check.
# Let's test this differently: reset-inner BEFORE check halts
teardown_sandbox
setup_sandbox
bash "$GUARD" init --max-inner 2 --max-outer 1 --max-total 10 > /dev/null
bash "$GUARD" tick build > /dev/null
bash "$GUARD" tick review inner > /dev/null
bash "$GUARD" tick build > /dev/null
bash "$GUARD" tick review inner > /dev/null
# inner=2, but we haven't checked yet — reset before check
bash "$GUARD" reset-inner > /dev/null

if bash "$GUARD" check > /dev/null 2>&1; then
  pass "reset-inner allows check to pass again"
else
  fail "reset-inner did not reset inner counter"
fi

# ── 8. Total limit enforcement ──

teardown_sandbox
setup_sandbox
bash "$GUARD" init --max-inner 3 --max-outer 2 --max-total 3 > /dev/null

bash "$GUARD" tick phase1 > /dev/null
bash "$GUARD" tick phase2 > /dev/null
bash "$GUARD" tick phase3 > /dev/null

# total_count=3 which equals max_total=3 — should halt
if bash "$GUARD" check > /dev/null 2>&1; then
  fail "check should have halted at total limit (3/3) but passed"
else
  pass "check correctly halts at total limit (3/3)"
fi

# ── 9. Repeated failure detection ──

teardown_sandbox
setup_sandbox
bash "$GUARD" init > /dev/null

# First failure should be recorded but not halt
if bash "$GUARD" fail review "hash_abc123" > /dev/null 2>&1; then
  pass "first failure recorded without halt"
else
  fail "first failure should not halt"
fi

# Same hash again should trigger halt (repeated failure)
if bash "$GUARD" fail review "hash_abc123" > /dev/null 2>&1; then
  fail "repeated failure should have halted but didn't"
else
  pass "repeated failure correctly triggers halt"
fi

# ── 10. Halted state blocks check ──

# State should be halted from previous test
if bash "$GUARD" check > /dev/null 2>&1; then
  fail "check should reject halted state"
else
  pass "check correctly rejects halted state"
fi

# ── 11. Complete sets status ──

teardown_sandbox
setup_sandbox
bash "$GUARD" init > /dev/null
bash "$GUARD" complete > /dev/null

STATUS=$(python3 -c "import json; print(json.load(open('.forge/autopilot/state.json'))['status'])")
if [[ "$STATUS" == "completed" ]]; then
  pass "complete sets status to completed"
else
  fail "complete status expected 'completed', got '$STATUS'"
fi

# ── 12. Completed state blocks check ──

if bash "$GUARD" check > /dev/null 2>&1; then
  fail "check should reject completed state"
else
  pass "check correctly rejects completed state"
fi

# ── 13. Check without init fails ──

teardown_sandbox
setup_sandbox

if bash "$GUARD" check > /dev/null 2>&1; then
  fail "check should fail without init"
else
  pass "check correctly fails without state file"
fi

# ── 14. Outer limit enforcement ──

teardown_sandbox
setup_sandbox
bash "$GUARD" init --max-inner 3 --max-outer 1 --max-total 20 > /dev/null

bash "$GUARD" tick verify outer > /dev/null

# outer_count=1 which equals max_outer=1 — should halt
if bash "$GUARD" check > /dev/null 2>&1; then
  fail "check should have halted at outer limit (1/1) but passed"
else
  pass "check correctly halts at outer limit (1/1)"
fi

# ── 15. History records all events ──

teardown_sandbox
setup_sandbox
bash "$GUARD" init > /dev/null
bash "$GUARD" tick build > /dev/null
bash "$GUARD" tick review inner > /dev/null
bash "$GUARD" complete > /dev/null

EVENTS=$(python3 -c "import json; d=json.load(open('.forge/autopilot/state.json')); print(len(d['history']))")
# init + tick(build) + tick(review) + complete = 4 events
if [[ "$EVENTS" == "4" ]]; then
  pass "history records all events (4 entries)"
else
  fail "history expected 4 events, got $EVENTS"
fi

print_test_summary
