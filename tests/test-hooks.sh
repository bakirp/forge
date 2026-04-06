#!/usr/bin/env bash
set -euo pipefail

# FORGE test: hooks infrastructure
# Run from project root: bash tests/test-hooks.sh

RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
RST='\033[0m'

FAILS=0
SKIPS=0

pass() { printf "${GRN}PASS${RST}: %s\n" "$1"; }
fail() { printf "${RED}FAIL${RST}: %s\n" "$1"; FAILS=$((FAILS + 1)); }
skip() { printf "${YEL}SKIP${RST}: %s\n" "$1"; SKIPS=$((SKIPS + 1)); }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── 1. hooks/ directory exists ──
if [[ -d "$ROOT/hooks" ]]; then
  pass "hooks/ directory exists"
else
  fail "hooks/ directory missing"
fi

# ── 2. hooks.json exists and is valid JSON ──
HOOKS_FILE="$ROOT/hooks/hooks.json"
if [[ -f "$HOOKS_FILE" ]]; then
  pass "hooks/hooks.json exists"
else
  fail "hooks/hooks.json missing"
fi

if python3 -c "import json; json.load(open('$HOOKS_FILE'))" 2>/dev/null; then
  pass "hooks.json is valid JSON"
else
  fail "hooks.json is not valid JSON"
fi

# ── 3. hooks.json has SessionStart event ──
if grep -q '"SessionStart"' "$HOOKS_FILE"; then
  pass "hooks.json defines SessionStart event"
else
  fail "hooks.json missing SessionStart event"
fi

# ── 4. hooks.json references session-start script ──
if grep -q 'session-start' "$HOOKS_FILE"; then
  pass "hooks.json references session-start script"
else
  fail "hooks.json does not reference session-start script"
fi

# ── 5. session-start script exists and is executable ──
SESSION_SCRIPT="$ROOT/hooks/session-start"
if [[ -f "$SESSION_SCRIPT" ]]; then
  pass "hooks/session-start exists"
else
  fail "hooks/session-start missing"
fi

if [[ -x "$SESSION_SCRIPT" ]]; then
  pass "hooks/session-start is executable"
else
  fail "hooks/session-start is not executable"
fi

# ── 6. session-start script produces valid JSON output ──
# Set CLAUDE_PLUGIN_ROOT for the test
export CLAUDE_PLUGIN_ROOT="$ROOT"
OUTPUT=$("$SESSION_SCRIPT" 2>/dev/null || true)
if python3 -c "import json, sys; json.loads(sys.argv[1])" "$OUTPUT" 2>/dev/null; then
  pass "session-start produces valid JSON"
else
  fail "session-start does not produce valid JSON (output: ${OUTPUT:0:100})"
fi

# ── 7. session-start output contains FORGE skill names ──
if echo "$OUTPUT" | grep -q '/think'; then
  pass "session-start output mentions /think"
else
  fail "session-start output does not mention /think"
fi

if echo "$OUTPUT" | grep -q '/build'; then
  pass "session-start output mentions /build"
else
  fail "session-start output does not mention /build"
fi

# ── Summary ──
echo ""
echo "hooks tests: $((9 - FAILS - SKIPS)) passed, $FAILS failed, $SKIPS skipped"
[[ $FAILS -eq 0 ]] && exit 0 || exit 1
