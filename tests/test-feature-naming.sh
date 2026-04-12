#!/usr/bin/env bash
set -euo pipefail

# FORGE test: feature naming infrastructure
# Run from project root: bash tests/test-feature-naming.sh

source "$(dirname "$0")/lib/test-helpers.sh"

setup_test_tmp "forge-feature-naming"
TOTAL=0

# ── 1. manifest.sh has feature-name command ──
((TOTAL++))
if grep -q 'feature-name' "$ROOT/scripts/manifest.sh"; then
  pass "manifest.sh contains feature-name command"
else
  fail "manifest.sh missing feature-name command"
fi

# ── 2. manifest.sh has resolve-feature-name command ──
((TOTAL++))
if grep -q 'resolve-feature-name' "$ROOT/scripts/manifest.sh"; then
  pass "manifest.sh contains resolve-feature-name command"
else
  fail "manifest.sh missing resolve-feature-name command"
fi

# ── 3. manifest.sh has slugify function ──
((TOTAL++))
if grep -q 'slugify' "$ROOT/scripts/manifest.sh"; then
  pass "manifest.sh contains slugify function"
else
  fail "manifest.sh missing slugify function"
fi

# ── 4. /think generates feature name in Step 4.5 ──
((TOTAL++))
THINK_FILE="$ROOT/skills/think/SKILL.md"
if [[ -f "$THINK_FILE" ]] && grep -q 'Step 4.5' "$THINK_FILE" && grep -q 'feature.name' "$THINK_FILE"; then
  pass "/think contains Step 4.5 for feature name generation"
else
  fail "/think missing Step 4.5 for feature name generation"
fi

# ── 5. All pipeline skills use resolve-feature-name ──
((TOTAL++))
PIPELINE_SKILLS=(build review verify ship)
all_ok=true
for skill in "${PIPELINE_SKILLS[@]}"; do
  SKILL_FILE="$ROOT/skills/$skill/SKILL.md"
  if [[ -f "$SKILL_FILE" ]] && grep -q 'resolve-feature-name' "$SKILL_FILE"; then
    : # ok
  else
    fail "/$skill does not use resolve-feature-name"
    all_ok=false
  fi
done
if $all_ok; then
  pass "All pipeline skills use resolve-feature-name"
fi

# ── 6. All pipeline agents use resolve-feature-name ──
((TOTAL++))
AGENTS=(forge-builder forge-reviewer forge-verifier forge-shipper forge-adversarial-reviewer)
agents_ok=true
for agent in "${AGENTS[@]}"; do
  AGENT_FILE="$ROOT/agents/$agent.md"
  if [[ -f "$AGENT_FILE" ]] && grep -q 'resolve-feature-name' "$AGENT_FILE"; then
    : # ok
  else
    fail "agent $agent does not use resolve-feature-name"
    agents_ok=false
  fi
done
if $agents_ok; then
  pass "All pipeline agents use resolve-feature-name"
fi

# ── 7. Telemetry script resolves feature name dynamically ──
((TOTAL++))
TELEMETRY_FILE="$ROOT/scripts/telemetry.sh"
if [[ -f "$TELEMETRY_FILE" ]] && grep -q 'resolve-feature-name' "$TELEMETRY_FILE"; then
  pass "telemetry.sh resolves feature name dynamically"
else
  fail "telemetry.sh does not resolve feature name — still uses hardcoded report.md"
fi

# ── 8. Backward compatibility: resolve-feature-name falls back to "report" ──
((TOTAL++))
if grep -q '"report"' "$ROOT/scripts/manifest.sh" && grep -q 'resolve-feature-name' "$ROOT/scripts/manifest.sh"; then
  pass "resolve-feature-name includes fallback to 'report' for backward compatibility"
else
  fail "resolve-feature-name missing fallback to 'report'"
fi

# ── 9. manifest.sh feature-name command handles conflict detection ──
((TOTAL++))
if grep -q 'date -u' "$ROOT/scripts/manifest.sh" && grep -q 'conflict\|already exist' "$ROOT/scripts/manifest.sh"; then
  pass "feature-name command includes date-based conflict detection"
else
  fail "feature-name command missing conflict detection logic"
fi

# ── 10. /autopilot uses feature-named artifact paths ──
((TOTAL++))
AUTOPILOT_FILE="$ROOT/skills/autopilot/SKILL.md"
if [[ -f "$AUTOPILOT_FILE" ]] && grep -q 'resolve-feature-name' "$AUTOPILOT_FILE"; then
  pass "/autopilot uses resolve-feature-name for artifact paths"
else
  fail "/autopilot does not use resolve-feature-name"
fi

print_test_summary "$TOTAL"
