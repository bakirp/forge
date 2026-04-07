#!/usr/bin/env bash
set -euo pipefail

# FORGE test: /evolve safety guardrails
# Run from project root: bash tests/test-evolution.sh

source "$(dirname "$0")/lib/test-helpers.sh"
EVOLVE="$ROOT/skills/evolve/SKILL.md"

if [ ! -f "$EVOLVE" ]; then
  fail "/evolve SKILL.md does not exist — cannot run evolution safety tests"
  exit 1
fi

# ── 1. /evolve classifies changes by risk level ──

has_low=false has_medium=false has_high=false
grep -qiE 'low.risk' "$EVOLVE" && has_low=true
grep -qiE 'medium.risk' "$EVOLVE" && has_medium=true
grep -qiE 'high.risk' "$EVOLVE" && has_high=true

if $has_low && $has_medium && $has_high; then
  pass "/evolve classifies changes by all 3 risk levels (low, medium, high)"
else
  fail "/evolve missing risk levels (low=$has_low, medium=$has_medium, high=$has_high)"
fi

# ── 2. /evolve requires test harness for auto-apply ──

if grep -qE 'test-routing\.sh|test-blocking\.sh|test-artifacts\.sh' "$EVOLVE"; then
  pass "/evolve requires test harness scripts for auto-apply validation"
else
  fail "/evolve does not reference test harness scripts"
fi

# ── 3. /evolve reverts on test failure ──

if grep -qiE 'revert' "$EVOLVE"; then
  pass "/evolve reverts changes on test failure"
else
  fail "/evolve does not mention reverting on test failure"
fi

# ── 4. /evolve requires explicit approval for high-risk changes ──

if grep -qiE 'explicit.*approv|require.*approv|approval' "$EVOLVE"; then
  pass "/evolve requires explicit approval for high-risk changes"
else
  fail "/evolve does not require explicit approval"
fi

# ── 5. /evolve blocks removal of safety guardrails ──

if grep -qiE 'never.*remove.*safety|removing safety' "$EVOLVE"; then
  pass "/evolve blocks removal of safety guardrails"
else
  fail "/evolve does not explicitly block removal of safety guardrails"
fi

# ── 6. /evolve blocks memory schema changes without approval ──

if grep -qiE 'memory.*schema|modify.*memory' "$EVOLVE"; then
  pass "/evolve guards memory schema changes"
else
  fail "/evolve does not guard memory schema modifications"
fi

# ── 7. /evolve requires retro data to run ──

if grep -qiE 'no retro|No retro|no retrospective' "$EVOLVE"; then
  pass "/evolve requires retrospective data before running"
else
  fail "/evolve does not check for retro data existence"
fi

# ── 8. /evolve warns on limited data (<2 retros) ──

if grep -qiE 'fewer than 2|limited data' "$EVOLVE"; then
  pass "/evolve warns on limited data (<2 retros)"
else
  fail "/evolve does not warn about limited retro data"
fi

# ── 9. /evolve logs all changes to evolution file ──

if grep -qE 'evolve_.*\.json|evolution.*log' "$EVOLVE"; then
  pass "/evolve logs changes to evolution file"
else
  fail "/evolve does not reference evolution log file"
fi

# ── 10. /evolve high-risk category covers structural changes ──

# Structural changes = removing safety checks, changing skill chain order, modifying memory schema
has_safety=false has_chain=false has_schema=false
grep -qiE 'removing safety|remove.*safety' "$EVOLVE" && has_safety=true
grep -qiE 'skill chain|chain order|skill.*order' "$EVOLVE" && has_chain=true
grep -qiE 'memory schema|modifying.*memory|memory.*schema' "$EVOLVE" && has_schema=true

if $has_safety && $has_chain && $has_schema; then
  pass "/evolve high-risk category covers all structural change types"
else
  fail "/evolve high-risk incomplete (safety=$has_safety, chain=$has_chain, schema=$has_schema)"
fi

print_test_summary
