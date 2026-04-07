#!/usr/bin/env bash
set -euo pipefail

# FORGE test: skill handover optimization
# Tests model routing, phase isolation, build report, telemetry phase-transition,
# and subagent definitions introduced in the handover optimization.
# Run from project root: bash tests/test-handover.sh

source "$(dirname "$0")/lib/test-helpers.sh"
TELEMETRY_SCRIPT="$ROOT/scripts/telemetry.sh"

# ── Setup ──
TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"
cleanup() { rm -rf "$TEST_HOME"; }
trap cleanup EXIT

# ═══════════════════════════════════════════════════
# SECTION 1: Subagent Definitions
# ═══════════════════════════════════════════════════

# ── 1. All forge-* agent files exist ──

AGENTS=(forge-reviewer forge-verifier forge-shipper forge-builder)
for agent in "${AGENTS[@]}"; do
  AGENT_FILE="$ROOT/agents/$agent.md"
  if [[ -f "$AGENT_FILE" ]]; then
    pass "agents/$agent.md exists"
  else
    fail "agents/$agent.md missing"
  fi
done

# ── 2. Agent files have required frontmatter fields ──

AGENT_REQUIRED_FIELDS=(name description tools model)
for agent in "${AGENTS[@]}"; do
  AGENT_FILE="$ROOT/agents/$agent.md"
  if [[ ! -f "$AGENT_FILE" ]]; then continue; fi

  fm=$(sed -n '2,/^---$/p' "$AGENT_FILE" | sed '$d')
  all_ok=true
  for field in "${AGENT_REQUIRED_FIELDS[@]}"; do
    if ! echo "$fm" | grep -q "^${field}:"; then
      fail "agents/$agent.md missing required field: $field"
      all_ok=false
    fi
  done
  if $all_ok; then
    pass "agents/$agent.md has all required frontmatter fields"
  fi
done

# ── 3. Agent files reference correct skills ──

AGENT_SKILL_PAIRS="forge-reviewer:forge:review forge-verifier:forge:verify forge-shipper:forge:ship forge-builder:forge:build"
for pair in $AGENT_SKILL_PAIRS; do
  agent="${pair%%:*}"
  # Extract skill (everything after first colon)
  expected_skill="${pair#*:}"
  AGENT_FILE="$ROOT/agents/$agent.md"
  if [[ -f "$AGENT_FILE" ]]; then
    if grep -q "$expected_skill" "$AGENT_FILE"; then
      pass "agents/$agent.md references skill $expected_skill"
    else
      fail "agents/$agent.md does not reference skill $expected_skill"
    fi
  fi
done

# ── 4. forge-reviewer is read-only (no Edit tool) ──

REVIEWER="$ROOT/agents/forge-reviewer.md"
if [[ -f "$REVIEWER" ]]; then
  fm=$(sed -n '2,/^---$/p' "$REVIEWER" | sed '$d')
  tools_line=$(echo "$fm" | grep '^tools:')
  if echo "$tools_line" | grep -q 'Edit'; then
    fail "forge-reviewer has Edit tool (should be read-only)"
  else
    pass "forge-reviewer does not have Edit tool (read-only)"
  fi
fi

# ── 5. forge-verifier is read-only (no Edit tool) ──

VERIFIER="$ROOT/agents/forge-verifier.md"
if [[ -f "$VERIFIER" ]]; then
  fm=$(sed -n '2,/^---$/p' "$VERIFIER" | sed '$d')
  tools_line=$(echo "$fm" | grep '^tools:')
  if echo "$tools_line" | grep -q 'Edit'; then
    fail "forge-verifier has Edit tool (should be read-only)"
  else
    pass "forge-verifier does not have Edit tool (read-only)"
  fi
fi

# ── 6. forge-builder does NOT have Agent tool (prevents nesting) ──

BUILDER="$ROOT/agents/forge-builder.md"
if [[ -f "$BUILDER" ]]; then
  fm=$(sed -n '2,/^---$/p' "$BUILDER" | sed '$d')
  tools_line=$(echo "$fm" | grep '^tools:')
  if echo "$tools_line" | grep -q 'Agent'; then
    fail "forge-builder has Agent tool (should not — prevents nesting)"
  else
    pass "forge-builder does not have Agent tool (nesting prevention)"
  fi
fi

# ── 7. Agent model assignments match routing table ──

AGENT_MODEL_PAIRS="forge-reviewer:opus forge-verifier:opus forge-shipper:opus forge-builder:opus"
for pair in $AGENT_MODEL_PAIRS; do
  agent="${pair%%:*}"
  expected_model="${pair#*:}"
  AGENT_FILE="$ROOT/agents/$agent.md"
  if [[ -f "$AGENT_FILE" ]]; then
    fm=$(sed -n '2,/^---$/p' "$AGENT_FILE" | sed '$d')
    if echo "$fm" | grep -q "^model: $expected_model"; then
      pass "agents/$agent.md uses model: $expected_model"
    else
      fail "agents/$agent.md does not use model: $expected_model"
    fi
  fi
done

# ═══════════════════════════════════════════════════
# SECTION 2: Model Routing in /think
# ═══════════════════════════════════════════════════

THINK="$ROOT/skills/think/SKILL.md"

# ── 8. /think contains model routing table ──

if grep -q 'Model Routing' "$THINK"; then
  pass "/think contains Model Routing section"
else
  fail "/think missing Model Routing section"
fi

# ── 9. /think routing table references all phases ──

for phase in think architect build review verify ship; do
  if grep -qi "/$phase" "$THINK" | head -1 && grep -q "$phase" "$THINK"; then
    pass "/think routing references /$phase"
  else
    fail "/think routing missing /$phase"
  fi
done

# ═══════════════════════════════════════════════════
# SECTION 3: Phase Isolation in Skills
# ═══════════════════════════════════════════════════

# ── 10. Post-build skills have Step 0 context detection ──

for skill in review verify ship build; do
  SKILL_FILE="$ROOT/skills/$skill/SKILL.md"
  if grep -qi 'Step 0.*Context Detection\|Step 0.*Execution Mode\|Context Detection.*Isolated.*Inline' "$SKILL_FILE"; then
    pass "/$skill has Step 0 context/mode detection"
  else
    fail "/$skill missing Step 0 context/mode detection"
  fi
done

# ── 11. /think has Phase Isolation section ──

if grep -q 'Phase Isolation' "$THINK"; then
  pass "/think contains Phase Isolation section"
else
  fail "/think missing Phase Isolation section"
fi

# ── 12. /think Phase Isolation references subagent confirmation ──

if grep -qiE 'confirm.*spawn|spawn.*confirm' "$THINK"; then
  pass "/think requires confirmation before subagent spawn"
else
  fail "/think missing confirmation gate before subagent spawn"
fi

# ═══════════════════════════════════════════════════
# SECTION 4: Build Report (Handoff Artifact)
# ═══════════════════════════════════════════════════

BUILD="$ROOT/skills/build/SKILL.md"

# ── 13. /build contains Step 6.5 for build report ──

if grep -q 'Step 6.5' "$BUILD"; then
  pass "/build contains Step 6.5 (Build Report)"
else
  fail "/build missing Step 6.5 (Build Report)"
fi

# ── 14. /build report references .forge/build/report.md ──

if grep -q '\.forge/build/report\.md' "$BUILD"; then
  pass "/build references .forge/build/report.md"
else
  fail "/build does not reference .forge/build/report.md"
fi

# ── 15. /build report contains required handoff fields ──

HANDOFF_FIELDS=("commit_sha" "tree_hash" "Files Modified" "Test Results" "Architecture Deviations" "User Decisions")
build_ok=true
for field in "${HANDOFF_FIELDS[@]}"; do
  if ! grep -q "$field" "$BUILD"; then
    fail "/build report missing handoff field: $field"
    build_ok=false
  fi
done
if $build_ok; then
  pass "/build report contains all required handoff fields"
fi

# ── 16. Post-build skills reference build report ──

for skill in review verify ship; do
  SKILL_FILE="$ROOT/skills/$skill/SKILL.md"
  if grep -q '\.forge/build/report\.md\|build report' "$SKILL_FILE"; then
    pass "/$skill references build report"
  else
    fail "/$skill does not reference build report"
  fi
done

# ═══════════════════════════════════════════════════
# SECTION 5: Telemetry Phase-Transition
# ═══════════════════════════════════════════════════

# ── 17. telemetry.sh supports phase-transition command ──

if grep -q 'phase-transition' "$TELEMETRY_SCRIPT"; then
  pass "telemetry.sh supports phase-transition command"
else
  fail "telemetry.sh missing phase-transition command"
fi

# ── 18. phase-transition produces valid JSON ──

bash "$TELEMETRY_SCRIPT" phase-transition test-skill 5000 12
TFILE="$TEST_HOME/.forge/telemetry.jsonl"
LAST_LINE=$(tail -1 "$TFILE")
if echo "$LAST_LINE" | python3 -c "import json, sys; json.loads(sys.stdin.read())" 2>/dev/null; then
  pass "phase-transition produces valid JSON"
else
  fail "phase-transition produces invalid JSON"
fi

# ── 19. phase-transition entry has required fields ──

PT_OK=true
for field in type skill timestamp project token_estimate tool_calls artifacts; do
  if ! echo "$LAST_LINE" | python3 -c "import json, sys; d=json.loads(sys.stdin.read()); assert '$field' in d" 2>/dev/null; then
    fail "phase-transition missing field: $field"
    PT_OK=false
  fi
done
if $PT_OK; then
  pass "phase-transition has all required fields"
fi

# ── 20. phase-transition type field is correct ──

if echo "$LAST_LINE" | python3 -c "import json, sys; d=json.loads(sys.stdin.read()); assert d['type'] == 'phase-transition'" 2>/dev/null; then
  pass "phase-transition type field is 'phase-transition'"
else
  fail "phase-transition type field incorrect"
fi

# ── 21. All core skills reference phase-transition telemetry ──

for skill in think architect build review verify ship; do
  SKILL_FILE="$ROOT/skills/$skill/SKILL.md"
  if grep -q 'phase-transition' "$SKILL_FILE"; then
    pass "/$skill references phase-transition telemetry"
  else
    fail "/$skill missing phase-transition telemetry reference"
  fi
done

# ── 22. Standard telemetry still works after phase-transition addition ──

bash "$TELEMETRY_SCRIPT" think completed tiny
STANDARD_LINE=$(tail -1 "$TFILE")
if echo "$STANDARD_LINE" | python3 -c "import json, sys; d=json.loads(sys.stdin.read()); assert d.get('skill') == 'think' and d.get('outcome') == 'completed'" 2>/dev/null; then
  pass "standard telemetry still works after phase-transition addition"
else
  fail "standard telemetry broken after phase-transition addition"
fi

# ═══════════════════════════════════════════════════
# SECTION 6: Autopilot Integration
# ═══════════════════════════════════════════════════

AUTOPILOT="$ROOT/skills/autopilot/SKILL.md"

# ── 23. /autopilot references isolated review/verify/ship ──

if [[ -f "$AUTOPILOT" ]]; then
  for agent in forge-reviewer forge-verifier forge-shipper; do
    if grep -q "$agent" "$AUTOPILOT"; then
      pass "/autopilot references $agent"
    else
      fail "/autopilot does not reference $agent"
    fi
  done
else
  skip "/autopilot not found"
fi

# ── 24. /autopilot references build report ──

if [[ -f "$AUTOPILOT" ]]; then
  if grep -q '\.forge/build/report\.md\|build report\|Build Report' "$AUTOPILOT"; then
    pass "/autopilot references build report artifact"
  else
    fail "/autopilot does not reference build report artifact"
  fi
fi

# ── 25. /autopilot has phase-transition telemetry ──

if [[ -f "$AUTOPILOT" ]]; then
  if grep -q 'phase-transition' "$AUTOPILOT"; then
    pass "/autopilot references phase-transition telemetry"
  else
    fail "/autopilot missing phase-transition telemetry"
  fi
fi

# ═══════════════════════════════════════════════════
# SECTION 7: Cross-Artifact Consistency
# ═══════════════════════════════════════════════════

# ── 26. Build report path consistent across all files ──

BUILD_REPORT_PATH=".forge/build/report.md"
consistent=true
for skill in build review verify ship; do
  SKILL_FILE="$ROOT/skills/$skill/SKILL.md"
  if grep -q "$BUILD_REPORT_PATH" "$SKILL_FILE" 2>/dev/null; then
    : # ok
  elif grep -qi "build report\|Build Report" "$SKILL_FILE" 2>/dev/null; then
    : # referenced by name, acceptable
  else
    fail "/$skill does not reference build report path or name"
    consistent=false
  fi
done
if $consistent; then
  pass "Build report path/reference consistent across skills"
fi

# ── 27. /build Step 0 mentions subagent mode limitations ──

if grep -qi 'cannot spawn.*subagent\|Skip Step 5' "$BUILD"; then
  pass "/build Step 0 documents subagent mode limitations"
else
  fail "/build Step 0 missing subagent mode limitation documentation"
fi

print_test_summary
