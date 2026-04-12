#!/usr/bin/env bash
set -euo pipefail

# FORGE test: compliance logging system
# Run from project root: bash tests/test-compliance-log.sh

source "$(dirname "$0")/lib/test-helpers.sh"

setup_test_tmp "forge-compliance"
TOTAL=0

# ── 1. compliance-log.sh exists and is executable ──
((TOTAL++))
SCRIPT="$ROOT/scripts/compliance-log.sh"
if [[ -f "$SCRIPT" ]]; then
  pass "compliance-log.sh exists"
else
  fail "compliance-log.sh not found"
  print_test_summary "$TOTAL"
fi

# ── 2. compliance-log.sh sources shared libraries ──
((TOTAL++))
if grep -q 'json-helpers.sh' "$SCRIPT" && grep -q 'colors.sh' "$SCRIPT"; then
  pass "compliance-log.sh sources shared libraries"
else
  fail "compliance-log.sh missing shared library imports"
fi

# ── 3. compliance-log.sh supports log and view commands ──
((TOTAL++))
if grep -q 'cmd_log' "$SCRIPT" && grep -q 'cmd_view' "$SCRIPT"; then
  pass "compliance-log.sh has log and view commands"
else
  fail "compliance-log.sh missing log or view command"
fi

# ── 4. compliance-log.sh writes to .forge/compliance.jsonl ──
((TOTAL++))
if grep -q 'compliance.jsonl' "$SCRIPT"; then
  pass "compliance-log.sh writes to .forge/compliance.jsonl"
else
  fail "compliance-log.sh does not reference compliance.jsonl"
fi

# ── 5. compliance-log.sh includes required JSONL fields ──
((TOTAL++))
REQUIRED_FIELDS=(timestamp skill rule severity details project run_id)
all_fields=true
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -q "$field" "$SCRIPT"; then
    fail "compliance-log.sh missing field: $field"
    all_fields=false
  fi
done
if $all_fields; then
  pass "compliance-log.sh includes all required JSONL fields"
fi

# ── 6. compliance-log.sh supports jq and python3 fallback ──
((TOTAL++))
if grep -q 'HAS_JQ' "$SCRIPT" && grep -q 'python3' "$SCRIPT"; then
  pass "compliance-log.sh supports jq and python3 fallback"
else
  fail "compliance-log.sh missing jq/python3 dual-path support"
fi

# ── 7. compliance-log.sh view supports filters ──
((TOTAL++))
if grep -q '\-\-skill' "$SCRIPT" && grep -q '\-\-severity' "$SCRIPT" && grep -q '\-\-run' "$SCRIPT"; then
  pass "compliance-log.sh view supports --skill, --severity, --run filters"
else
  fail "compliance-log.sh view missing filter support"
fi

# ── 8. compliance-log.sh uses atomic append ──
((TOTAL++))
if grep -q 'flock' "$SCRIPT"; then
  pass "compliance-log.sh uses flock for atomic append"
else
  fail "compliance-log.sh missing flock-based atomic append"
fi

# ── 9. /build integrates compliance logging for missing arch doc ──
((TOTAL++))
BUILD_FILE="$ROOT/skills/build/SKILL.md"
if [[ -f "$BUILD_FILE" ]] && grep -q 'compliance-log.sh.*missing-arch-doc' "$BUILD_FILE"; then
  pass "/build logs compliance violation for missing architecture doc"
else
  fail "/build does not log compliance violation for missing architecture doc"
fi

# ── 10. /ship integrates compliance logging for stale artifacts ──
((TOTAL++))
SHIP_FILE="$ROOT/skills/ship/SKILL.md"
if [[ -f "$SHIP_FILE" ]] && grep -q 'compliance-log.sh.*stale-artifact' "$SHIP_FILE"; then
  pass "/ship logs compliance violation for stale artifacts"
else
  fail "/ship does not log compliance violation for stale artifacts"
fi

# ── 11. /ship integrates compliance logging for missing prerequisites ──
((TOTAL++))
if [[ -f "$SHIP_FILE" ]] && grep -q 'compliance-log.sh.*missing-prerequisite' "$SHIP_FILE"; then
  pass "/ship logs compliance violation for missing prerequisites"
else
  fail "/ship does not log compliance violation for missing prerequisites"
fi

# ── 12. /verify integrates compliance logging for failing tests ──
((TOTAL++))
VERIFY_FILE="$ROOT/skills/verify/SKILL.md"
if [[ -f "$VERIFY_FILE" ]] && grep -q 'compliance-log.sh.*tests-failing' "$VERIFY_FILE"; then
  pass "/verify logs compliance violation for failing tests"
else
  fail "/verify does not log compliance violation for failing tests"
fi

# ── 13. ALL skills have compliance logging ──
((TOTAL++))
missing_compliance=()
while IFS= read -r skill_file; do
  rel="${skill_file#"$ROOT/"}"
  if ! grep -q 'compliance-log.sh' "$skill_file"; then
    missing_compliance+=("$rel")
  fi
done < <(find "$ROOT/skills" -name SKILL.md -not -path '*/.git/*' -not -path '*/references/*')

if [[ ${#missing_compliance[@]} -eq 0 ]]; then
  pass "All skills include compliance-log.sh integration"
else
  fail "Skills missing compliance logging: ${missing_compliance[*]}"
fi

print_test_summary "$TOTAL"
