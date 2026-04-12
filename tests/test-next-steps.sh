#!/usr/bin/env bash
set -euo pipefail

# FORGE test: every pipeline skill includes next-steps guidance
# Run from project root: bash tests/test-next-steps.sh

source "$(dirname "$0")/lib/test-helpers.sh"

TOTAL=0

# ── Pipeline skills must have "What's Next" sections ──

PIPELINE_SKILLS=(build review verify ship debug retro browse benchmark)
for skill in "${PIPELINE_SKILLS[@]}"; do
  ((TOTAL++))
  SKILL_FILE="$ROOT/skills/$skill/SKILL.md"
  if [[ ! -f "$SKILL_FILE" ]]; then
    skip "/$skill not found"
    continue
  fi
  if grep -qi "What's Next\|what.*next" "$SKILL_FILE"; then
    pass "/$skill contains next-steps guidance"
  else
    fail "/$skill missing next-steps guidance"
  fi
done

# ── Design sub-skills must have "What's Next" sections ──

DESIGN_SKILLS=(consult explore review audit polish)
for skill in "${DESIGN_SKILLS[@]}"; do
  ((TOTAL++))
  SKILL_FILE="$ROOT/skills/design/$skill/SKILL.md"
  if [[ ! -f "$SKILL_FILE" ]]; then
    skip "/design $skill not found"
    continue
  fi
  if grep -qi "What's Next\|what.*next" "$SKILL_FILE"; then
    pass "/design $skill contains next-steps guidance"
  else
    fail "/design $skill missing next-steps guidance"
  fi
done

# ── Main design skill has per-sub-skill next steps ──
((TOTAL++))
DESIGN_MAIN="$ROOT/skills/design/SKILL.md"
if [[ -f "$DESIGN_MAIN" ]] && grep -qi "What's Next" "$DESIGN_MAIN"; then
  pass "/design main skill contains next-steps guidance"
else
  fail "/design main skill missing next-steps guidance"
fi

# ── Memory skill has next-steps ──
((TOTAL++))
MEMORY_MAIN="$ROOT/skills/memory/SKILL.md"
if [[ -f "$MEMORY_MAIN" ]] && grep -qi "What's Next" "$MEMORY_MAIN"; then
  pass "/memory contains next-steps guidance"
else
  fail "/memory missing next-steps guidance"
fi

# ── Skills with conditional next steps include both paths ──
((TOTAL++))
REVIEW_FILE="$ROOT/skills/review/SKILL.md"
if [[ -f "$REVIEW_FILE" ]]; then
  if grep -q 'If PASS' "$REVIEW_FILE" && grep -q 'If NEEDS_CHANGES' "$REVIEW_FILE" && grep -q 'If FAIL' "$REVIEW_FILE"; then
    pass "/review has conditional next-steps for PASS, NEEDS_CHANGES, and FAIL"
  else
    fail "/review missing conditional next-steps for all verdict states"
  fi
fi

((TOTAL++))
VERIFY_FILE="$ROOT/skills/verify/SKILL.md"
if [[ -f "$VERIFY_FILE" ]]; then
  if grep -q 'If PASS' "$VERIFY_FILE" && grep -q 'If FAIL' "$VERIFY_FILE"; then
    pass "/verify has conditional next-steps for PASS and FAIL"
  else
    fail "/verify missing conditional next-steps for both verdict states"
  fi
fi

print_test_summary "$TOTAL"
