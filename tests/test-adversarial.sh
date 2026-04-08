#!/usr/bin/env bash
set -euo pipefail

# FORGE test: adversarial review skill structure and integration
# Run from project root: bash tests/test-adversarial.sh

source "$(dirname "$0")/lib/test-helpers.sh"

# ═══════════════════════════════════════════════════
# SECTION 1: Skill File Structure
# ═══════════════════════════════════════════════════

SKILL="$ROOT/skills/review/adversarial/SKILL.md"

# ── 1. Skill file exists ──

if [[ -f "$SKILL" ]]; then
  pass "skills/review/adversarial/SKILL.md exists"
else
  fail "skills/review/adversarial/SKILL.md missing"
fi

# ── 2. Has valid frontmatter with required fields ──

if [[ -f "$SKILL" ]]; then
  REQUIRED_FIELDS=(name description argument-hint allowed-tools)
  fm=$(sed -n '2,/^---$/p' "$SKILL" | sed '$d')
  all_ok=true
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$fm" | grep -q "^${field}:"; then
      fail "adversarial SKILL.md missing required field: $field"
      all_ok=false
    fi
  done
  if $all_ok; then
    pass "adversarial SKILL.md has all 4 required frontmatter fields"
  fi
fi

# ── 3. Name field is review-adversarial ──

if [[ -f "$SKILL" ]]; then
  if echo "$fm" | grep -q '^name: review-adversarial'; then
    pass "adversarial skill name is review-adversarial"
  else
    fail "adversarial skill name should be review-adversarial"
  fi
fi

# ── 4. Skill is read-only (no Edit in allowed-tools) ──

if [[ -f "$SKILL" ]]; then
  tools_line=$(echo "$fm" | grep '^allowed-tools:')
  if echo "$tools_line" | grep -q 'Edit'; then
    fail "adversarial skill has Edit tool (should be read-only)"
  else
    pass "adversarial skill does not have Edit tool (read-only)"
  fi
fi

# ═══════════════════════════════════════════════════
# SECTION 2: Attack Surface Coverage
# ═══════════════════════════════════════════════════

# ── 5. Skill references all 7 attack surfaces ──

if [[ -f "$SKILL" ]]; then
  SURFACES=("Auth" "Data loss" "Rollback" "Race condition" "Empty-state" "Version skew" "Observability")
  all_surfaces=true
  for surface in "${SURFACES[@]}"; do
    if ! grep -qi "$surface" "$SKILL"; then
      fail "adversarial skill missing attack surface: $surface"
      all_surfaces=false
    fi
  done
  if $all_surfaces; then
    pass "adversarial skill references all 7 attack surfaces"
  fi
fi

# ── 6. Skill contains finding bar (4 required questions) ──

if [[ -f "$SKILL" ]]; then
  QUESTIONS=("What can go wrong" "Why.*vulnerable" "Likely impact" "Recommendation")
  all_q=true
  for q in "${QUESTIONS[@]}"; do
    if ! grep -qiE "$q" "$SKILL"; then
      fail "adversarial skill missing finding question: $q"
      all_q=false
    fi
  done
  if $all_q; then
    pass "adversarial skill contains all 4 finding bar questions"
  fi
fi

# ── 7. Skill contains confidence score field ──

if [[ -f "$SKILL" ]]; then
  if grep -qi 'Confidence' "$SKILL"; then
    pass "adversarial skill contains confidence score field"
  else
    fail "adversarial skill missing confidence score field"
  fi
fi

# ═══════════════════════════════════════════════════
# SECTION 3: Status and Artifact Convention
# ═══════════════════════════════════════════════════

# ── 8. Uses SHIP/NO-SHIP/SHIP-WITH-CAVEATS (not PASS/FAIL) ──

if [[ -f "$SKILL" ]]; then
  if grep -q 'SHIP' "$SKILL" && grep -q 'NO-SHIP' "$SKILL" && grep -q 'SHIP-WITH-CAVEATS' "$SKILL"; then
    pass "adversarial skill uses SHIP/NO-SHIP/SHIP-WITH-CAVEATS status values"
  else
    fail "adversarial skill missing distinct status values (SHIP/NO-SHIP/SHIP-WITH-CAVEATS)"
  fi
fi

# ── 9. References .forge/review/adversarial.md artifact path ──

if [[ -f "$SKILL" ]]; then
  if grep -q '\.forge/review/adversarial\.md' "$SKILL"; then
    pass "adversarial skill references .forge/review/adversarial.md"
  else
    fail "adversarial skill does not reference .forge/review/adversarial.md"
  fi
fi

# ── 10. Stamps commit_sha and tree_hash ──

if [[ -f "$SKILL" ]]; then
  if grep -q 'commit_sha' "$SKILL" && grep -q 'tree_hash' "$SKILL"; then
    pass "adversarial skill stamps commit_sha and tree_hash"
  else
    fail "adversarial skill missing commit_sha or tree_hash stamp"
  fi
fi

# ── 11. Contains evidence before claims ──

if [[ -f "$SKILL" ]]; then
  if grep -qi 'evidence before claims' "$SKILL"; then
    pass "adversarial skill contains 'evidence before claims'"
  else
    fail "adversarial skill missing 'evidence before claims'"
  fi
fi

# ═══════════════════════════════════════════════════
# SECTION 4: Context Detection and Telemetry
# ═══════════════════════════════════════════════════

# ── 12. Has Step 0 context detection ──

if [[ -f "$SKILL" ]]; then
  if grep -qiE 'Step 0.*Context Detection|Context Detection.*Isolated.*Inline' "$SKILL"; then
    pass "adversarial skill has Step 0 context detection"
  else
    fail "adversarial skill missing Step 0 context detection"
  fi
fi

# ── 13. References telemetry logging ──

if [[ -f "$SKILL" ]]; then
  if grep -q 'telemetry.sh' "$SKILL"; then
    pass "adversarial skill references telemetry logging"
  else
    fail "adversarial skill missing telemetry logging"
  fi
fi

# ── 14. Has error handling section ──

if [[ -f "$SKILL" ]]; then
  if grep -qiE 'Error Handling|NOT CHECKED' "$SKILL"; then
    pass "adversarial skill has error handling guidance"
  else
    fail "adversarial skill missing error handling guidance"
  fi
fi

# ═══════════════════════════════════════════════════
# SECTION 5: Agent Definition
# ═══════════════════════════════════════════════════

AGENT="$ROOT/agents/forge-adversarial-reviewer.md"

# ── 15. Agent file exists ──

if [[ -f "$AGENT" ]]; then
  pass "agents/forge-adversarial-reviewer.md exists"
else
  fail "agents/forge-adversarial-reviewer.md missing"
fi

# ── 16. Agent has required frontmatter fields ──

if [[ -f "$AGENT" ]]; then
  agent_fm=$(sed -n '2,/^---$/p' "$AGENT" | sed '$d')
  AGENT_FIELDS=(name description tools model)
  agent_ok=true
  for field in "${AGENT_FIELDS[@]}"; do
    if ! echo "$agent_fm" | grep -q "^${field}:"; then
      fail "forge-adversarial-reviewer missing field: $field"
      agent_ok=false
    fi
  done
  if $agent_ok; then
    pass "forge-adversarial-reviewer has all required frontmatter fields"
  fi
fi

# ── 17. Agent uses opus model ──

if [[ -f "$AGENT" ]]; then
  if echo "$agent_fm" | grep -q '^model: opus'; then
    pass "forge-adversarial-reviewer uses model: opus"
  else
    fail "forge-adversarial-reviewer does not use model: opus"
  fi
fi

# ── 18. Agent references forge:review skill ──

if [[ -f "$AGENT" ]]; then
  if grep -q 'forge:review' "$AGENT"; then
    pass "forge-adversarial-reviewer references forge:review skill"
  else
    fail "forge-adversarial-reviewer does not reference forge:review skill"
  fi
fi

# ── 19. Agent does not have Edit tool (read-only) ──

if [[ -f "$AGENT" ]]; then
  if echo "$agent_fm" | grep '^tools:' | grep -q 'Edit'; then
    fail "forge-adversarial-reviewer has Edit tool (should be read-only)"
  else
    pass "forge-adversarial-reviewer does not have Edit tool (read-only)"
  fi
fi

# ── 20. Agent references adversarial.md artifact ──

if [[ -f "$AGENT" ]]; then
  if grep -q 'adversarial\.md' "$AGENT"; then
    pass "forge-adversarial-reviewer references adversarial.md artifact"
  else
    fail "forge-adversarial-reviewer does not reference adversarial.md artifact"
  fi
fi

# ═══════════════════════════════════════════════════
# SECTION 6: Routing Integration
# ═══════════════════════════════════════════════════

REVIEW="$ROOT/skills/review/SKILL.md"

# ── 21. /review routes to adversarial sub-skill ──

if [[ -f "$REVIEW" ]]; then
  if grep -qi 'review-adversarial' "$REVIEW"; then
    pass "/review routes to /review-adversarial"
  else
    fail "/review does not route to /review-adversarial"
  fi
fi

# ── 22. /review routing table has adversarial entry ──

if [[ -f "$REVIEW" ]]; then
  if grep -q 'adversarial \[context\]' "$REVIEW"; then
    pass "/review routing table has adversarial entry"
  else
    fail "/review routing table missing adversarial entry"
  fi
fi

# ═══════════════════════════════════════════════════
# SECTION 7: Cross-Skill Consistency
# ═══════════════════════════════════════════════════

# ── 23. /forge overview lists /review adversarial ──

FORGE_SKILL="$ROOT/skills/forge/SKILL.md"
if [[ -f "$FORGE_SKILL" ]]; then
  if grep -q 'review adversarial' "$FORGE_SKILL"; then
    pass "/forge overview lists /review adversarial"
  else
    fail "/forge overview does not list /review adversarial"
  fi
fi

# ── 24. /ship references adversarial report ──

SHIP="$ROOT/skills/ship/SKILL.md"
if [[ -f "$SHIP" ]]; then
  if grep -q 'adversarial' "$SHIP"; then
    pass "/ship references adversarial review"
  else
    fail "/ship does not reference adversarial review"
  fi
fi

# ── 25. artifact-schema.md contains adversarial review schema ──

SCHEMA="$ROOT/docs/artifact-schema.md"
if [[ -f "$SCHEMA" ]]; then
  if grep -q 'Adversarial Review Report' "$SCHEMA"; then
    pass "artifact-schema.md contains adversarial review report schema"
  else
    fail "artifact-schema.md missing adversarial review report schema"
  fi
fi

# ── 26. artifact-schema.md directory tree includes adversarial.md ──

if [[ -f "$SCHEMA" ]]; then
  if grep -q 'adversarial\.md' "$SCHEMA"; then
    pass "artifact-schema.md directory tree includes adversarial.md"
  else
    fail "artifact-schema.md directory tree missing adversarial.md"
  fi
fi

# ── 27. artifact-schema.md cross-artifact table includes /review adversarial ──

if [[ -f "$SCHEMA" ]]; then
  if grep -q 'review adversarial' "$SCHEMA"; then
    pass "artifact-schema.md cross-artifact table includes /review adversarial"
  else
    fail "artifact-schema.md cross-artifact table missing /review adversarial"
  fi
fi

# ── 28. skills-reference.md documents /review adversarial ──

SKILLREF="$ROOT/docs/skills-reference.md"
if [[ -f "$SKILLREF" ]]; then
  if grep -q 'review adversarial' "$SKILLREF"; then
    pass "skills-reference.md documents /review adversarial"
  else
    fail "skills-reference.md missing /review adversarial documentation"
  fi
fi

# ── 29. /ship adversarial section is advisory (not blocking) ──

if [[ -f "$SHIP" ]]; then
  if grep -qi 'does NOT block shipping\|advisory' "$SHIP"; then
    pass "/ship adversarial review is advisory (not blocking)"
  else
    fail "/ship adversarial review may be incorrectly blocking"
  fi
fi

# ── 30. Adversarial review never modifies code ──

if [[ -f "$SKILL" ]]; then
  if grep -qi 'never modif\|read-only' "$SKILL"; then
    pass "adversarial skill enforces read-only (never modifies code)"
  else
    fail "adversarial skill missing read-only enforcement"
  fi
fi

print_test_summary
