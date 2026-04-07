#!/usr/bin/env bash
set -euo pipefail

# FORGE test: completeness checks across core skills
# Run from project root: bash tests/test-completeness.sh

source "$(dirname "$0")/lib/test-helpers.sh"

# ── 1. Evidence-before-claims: core skills should contain the principle ──

EVIDENCE_REQUIRED=(build review verify ship design/review)

for skill in "${EVIDENCE_REQUIRED[@]}"; do
  path="$ROOT/skills/$skill/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -qi 'evidence before claims' "$path"; then
      pass "/$skill contains 'evidence before claims'"
    else
      fail "/$skill missing 'evidence before claims'"
    fi
  else
    skip "/$skill not found"
  fi
done

# /architect uses different wording — check for its actual evidence requirement
path="$ROOT/skills/architect/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qiE 'show evidence|evidence it was written|before claiming.*complete' "$path"; then
    pass "/architect contains evidence requirement before claiming complete"
  else
    fail "/architect missing evidence requirement before claiming architecture doc is complete"
  fi
else
  skip "/architect not found"
fi

# /think is a router/classifier — verify it routes rather than making completion claims
path="$ROOT/skills/think/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qiE 'route|classify|dispatch' "$path"; then
    pass "/think is a router — routes tasks rather than making completion claims"
  else
    fail "/think missing routing/classification logic"
  fi
else
  skip "/think not found"
fi

# ── 2. Artifact directory creation: skills that write artifacts should create dirs ──

DIR_CREATION_SKILLS=(architect review verify browse ship design/consult design/explore design/review)

for skill in "${DIR_CREATION_SKILLS[@]}"; do
  path="$ROOT/skills/$skill/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -qiE 'mkdir|[Cc]reate.*if.*exist' "$path"; then
      pass "/$skill handles artifact directory creation"
    else
      fail "/$skill missing artifact directory creation (mkdir or 'Create...if...exist')"
    fi
  else
    skip "/$skill not found"
  fi
done

# ── 3. Missing file handling: /ship and /verify handle missing reports ──

MISSING_SKILLS=(ship verify)

for skill in "${MISSING_SKILLS[@]}"; do
  path="$ROOT/skills/$skill/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -qiE 'no.*report|not found|BLOCKED|does not exist' "$path"; then
      pass "/$skill handles missing reports"
    else
      fail "/$skill missing handling for absent reports (no report/not found/BLOCKED/does not exist)"
    fi
  else
    skip "/$skill not found"
  fi
done

# ── 4. Error handling: all 6 core skills should have error handling guidance ──

CORE_SKILLS=(think architect build review verify ship)

for skill in "${CORE_SKILLS[@]}"; do
  path="$ROOT/skills/$skill/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -qiE 'error.handl|if.*fail|retry|abort' "$path"; then
      pass "/$skill contains error handling guidance"
    else
      fail "/$skill missing error handling guidance (error handling/if fail/retry/abort)"
    fi
  else
    skip "/$skill not found"
  fi
done

# ── 5. Red-flags table: /forge should contain the rationalization table ──

path="$ROOT/skills/forge/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qi 'red flag' "$path"; then
    pass "/forge SKILL.md contains red-flags rationalization table"
  else
    fail "/forge SKILL.md missing red-flags rationalization table ('Red Flag' not found)"
  fi
else
  skip "/forge not found"
fi

# ── 6. Red-flags table: /forge covers the /verify skip pattern ──

path="$ROOT/skills/forge/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -q 'looks fine' "$path"; then
    pass "/forge red-flags table includes the /verify skip rationalization"
  else
    fail "/forge red-flags table missing the /verify skip rationalization ('looks fine' not found)"
  fi
else
  skip "/forge not found"
fi

# ── 7. /architect requires evidence before claiming architecture doc is complete ──

path="$ROOT/skills/architect/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qiE 'head -5|show evidence' "$path"; then
    pass "/architect requires evidence before claiming architecture doc is complete"
  else
    fail "/architect missing evidence requirement before claiming architecture doc is complete"
  fi
else
  skip "/architect not found"
fi

# ── 8. /ship requires showing PR URL as evidence before claiming shipped ──

path="$ROOT/skills/ship/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qiE 'gh pr view|PR URL' "$path"; then
    pass "/ship requires showing PR URL as evidence before claiming shipped"
  else
    fail "/ship missing PR URL evidence requirement before claiming shipped"
  fi
else
  skip "/ship not found"
fi

# ── 9. /brainstorm contains problem-framing step ──

path="$ROOT/skills/brainstorm/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qi 'right problem' "$path"; then
    pass "/brainstorm contains problem-framing step"
  else
    fail "/brainstorm missing problem-framing step ('right problem' not found)"
  fi
else
  skip "/brainstorm not found"
fi

# ── 10. /review-response contains anti-sycophancy gate ──

path="$ROOT/skills/review/response/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qi 'sycophancy\|push back\|performatively' "$path"; then
    pass "/review-response contains anti-sycophancy guardrails"
  else
    fail "/review-response missing anti-sycophancy guardrails"
  fi
else
  skip "/review-response not found"
fi

# ── 11. /think contains --auto flag documentation ──

path="$ROOT/skills/think/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -q '\-\-auto' "$path"; then
    pass "/think contains --auto workflow automation flag"
  else
    fail "/think missing --auto flag documentation"
  fi
else
  skip "/think not found"
fi

# ── 12. /evolve references telemetry data ──

path="$ROOT/skills/evolve/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -q 'telemetry' "$path"; then
    pass "/evolve references telemetry data source"
  else
    fail "/evolve missing telemetry data source reference"
  fi
else
  skip "/evolve not found"
fi

# ── 13. /build contains vertical slice ordering guidance ──

path="$ROOT/skills/build/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qi 'vertical slice' "$path"; then
    pass "/build contains vertical slice ordering guidance"
  else
    fail "/build missing vertical slice ordering guidance"
  fi
else
  skip "/build not found"
fi

# ── 14. /build contains anti-pattern callout against horizontal layering ──

path="$ROOT/skills/build/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qiE 'anti.?pattern.*all models|Do NOT plan as' "$path"; then
    pass "/build contains anti-pattern callout against horizontal layering"
  else
    fail "/build missing anti-pattern callout against horizontal layer ordering"
  fi
else
  skip "/build not found"
fi

# ── 15. /build contains mocking discipline (system boundaries only) ──

path="$ROOT/skills/build/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qi 'mock.*system boundar' "$path" && grep -qi 'never mock internal' "$path"; then
    pass "/build contains mocking discipline (system boundaries + never mock internals)"
  else
    fail "/build missing mocking discipline guidance"
  fi
else
  skip "/build not found"
fi

# ── 16. /build contains post-TDD refactor checkpoint ──

path="$ROOT/skills/build/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qi 'Quick Refactor' "$path"; then
    pass "/build contains post-TDD refactor checkpoint (Step 4c.1)"
  else
    fail "/build missing post-TDD refactor checkpoint"
  fi
else
  skip "/build not found"
fi

# ── 17. /brainstorm contains --grill flag ──

path="$ROOT/skills/brainstorm/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -q '\-\-grill' "$path"; then
    pass "/brainstorm contains --grill flag"
  else
    fail "/brainstorm missing --grill flag"
  fi
else
  skip "/brainstorm not found"
fi

# ── 18. /brainstorm grill mode has interrogation loop with recommended answers ──

path="$ROOT/skills/brainstorm/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qi 'recommended answer' "$path" && grep -qi 'one question at a time' "$path"; then
    pass "/brainstorm grill mode has recommended answers and one-at-a-time questioning"
  else
    fail "/brainstorm grill mode missing recommended answer or one-at-a-time questioning pattern"
  fi
else
  skip "/brainstorm not found"
fi

# ── 19. /brainstorm grill mode has question cap ──

path="$ROOT/skills/brainstorm/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -qiE '10 question|default cap' "$path"; then
    pass "/brainstorm grill mode has 10-question cap"
  else
    fail "/brainstorm grill mode missing question cap"
  fi
else
  skip "/brainstorm not found"
fi

# ── 20. /brainstorm grill mode produces artifact with grill format ──

path="$ROOT/skills/brainstorm/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -q 'Decisions Confirmed' "$path" && grep -q 'Risks Identified' "$path"; then
    pass "/brainstorm grill artifact format includes Decisions Confirmed and Risks Identified"
  else
    fail "/brainstorm grill artifact missing required sections (Decisions Confirmed / Risks Identified)"
  fi
else
  skip "/brainstorm not found"
fi

# ── 21. /autopilot Step 9 uses jq for memory writes (not raw echo) ──

path="$ROOT/skills/autopilot/SKILL.md"
if [[ -f "$path" ]]; then
  if grep -q 'jq -n -c' "$path"; then
    pass "/autopilot Step 9 uses jq for safe JSON construction"
  else
    fail "/autopilot Step 9 missing jq usage for memory writes"
  fi

  # Check that raw echo with JSON is NOT present
  if grep -qE "echo '\{" "$path"; then
    fail "/autopilot Step 9 still contains raw echo with JSON (contract violation)"
  else
    pass "/autopilot Step 9 does not use raw echo with JSON"
  fi
else
  skip "/autopilot not found"
fi

# ── 22. artifact-schema.md contains grill brainstorm format ──

path="$ROOT/docs/artifact-schema.md"
if [[ -f "$path" ]]; then
  if grep -q 'Grill Mode' "$path" && grep -q 'Decisions Confirmed' "$path"; then
    pass "artifact-schema.md contains grill brainstorm artifact format"
  else
    fail "artifact-schema.md missing grill brainstorm artifact format"
  fi
else
  skip "docs/artifact-schema.md not found"
fi

print_test_summary
