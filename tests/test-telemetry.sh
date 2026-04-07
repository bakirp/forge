#!/usr/bin/env bash
set -euo pipefail

# FORGE test: telemetry infrastructure
# Run from project root: bash tests/test-telemetry.sh

source "$(dirname "$0")/lib/test-helpers.sh"
TELEMETRY_SCRIPT="$ROOT/scripts/telemetry.sh"

# Use temp dir for test isolation
TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"

cleanup() { rm -rf "$TEST_HOME"; }
trap cleanup EXIT

# ── 1. telemetry.sh exists and is executable ──
if [[ -f "$TELEMETRY_SCRIPT" ]]; then
  pass "scripts/telemetry.sh exists"
else
  fail "scripts/telemetry.sh missing"
fi

if [[ -x "$TELEMETRY_SCRIPT" ]]; then
  pass "scripts/telemetry.sh is executable"
else
  fail "scripts/telemetry.sh is not executable"
fi

# ── 2. telemetry.sh creates ~/.forge/ directory ──
bash "$TELEMETRY_SCRIPT" think completed tiny
if [[ -d "$TEST_HOME/.forge" ]]; then
  pass "telemetry creates ~/.forge/ directory"
else
  fail "telemetry does not create ~/.forge/ directory"
fi

# ── 3. telemetry.sh creates telemetry.jsonl ──
TFILE="$TEST_HOME/.forge/telemetry.jsonl"
if [[ -f "$TFILE" ]]; then
  pass "telemetry creates telemetry.jsonl"
else
  fail "telemetry does not create telemetry.jsonl"
fi

# ── 4. each line is valid JSON ──
ALL_VALID=true
while IFS= read -r line; do
  if ! python3 -c "import json, sys; json.loads(sys.argv[1])" "$line" 2>/dev/null; then
    ALL_VALID=false
    break
  fi
done < "$TFILE"

if $ALL_VALID; then
  pass "telemetry entries are valid JSON"
else
  fail "telemetry entry is not valid JSON"
fi

# ── 5. entry has required fields ──
FIRST_LINE=$(head -1 "$TFILE")
HAS_FIELDS=true
for field in skill timestamp project outcome; do
  if ! echo "$FIRST_LINE" | python3 -c "import json, sys; d=json.loads(sys.stdin.read()); assert '$field' in d" 2>/dev/null; then
    HAS_FIELDS=false
    fail "telemetry entry missing field: $field"
  fi
done

if $HAS_FIELDS; then
  pass "telemetry entry has all required fields (skill, timestamp, project, outcome)"
fi

# ── 6. classification field is optional ──
bash "$TELEMETRY_SCRIPT" build completed
SECOND_LINE=$(tail -1 "$TFILE")
if echo "$SECOND_LINE" | python3 -c "import json, sys; d=json.loads(sys.stdin.read()); assert 'classification' not in d" 2>/dev/null; then
  pass "classification field is optional (omitted when not provided)"
else
  fail "classification field present when not provided"
fi

# ── 7. classification field present when provided ──
if echo "$FIRST_LINE" | python3 -c "import json, sys; d=json.loads(sys.stdin.read()); assert d.get('classification') == 'tiny'" 2>/dev/null; then
  pass "classification field correct when provided (tiny)"
else
  fail "classification field incorrect when provided"
fi

# ── 8. multiple appends work ──
bash "$TELEMETRY_SCRIPT" review completed
bash "$TELEMETRY_SCRIPT" ship blocked
LINE_COUNT=$(wc -l < "$TFILE" | tr -d ' ')
if [[ "$LINE_COUNT" -eq 4 ]]; then
  pass "multiple appends work (4 entries)"
else
  fail "expected 4 entries, got $LINE_COUNT"
fi

# ── 9. core skills reference telemetry in their SKILL.md ──
for skill in think build review ship; do
  SKILL_FILE="$ROOT/skills/$skill/SKILL.md"
  if grep -q "telemetry.sh" "$SKILL_FILE" 2>/dev/null; then
    pass "$skill/SKILL.md references telemetry.sh"
  else
    fail "$skill/SKILL.md does not reference telemetry.sh"
  fi
done

print_test_summary 13
