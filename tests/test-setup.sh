#!/usr/bin/env bash
set -euo pipefail

# FORGE test: setup script structure (Claude and Codex install paths)
# Run from project root: bash tests/test-setup.sh

source "$(dirname "$0")/lib/test-helpers.sh"
SETUP="$ROOT/setup"

# ── 1. Setup script exists and is executable ──

if [ -f "$SETUP" ]; then
  pass "setup script exists"
  if [ -x "$SETUP" ]; then
    pass "setup script is executable"
  else
    fail "setup script is not executable (missing +x)"
  fi
else
  fail "setup script does not exist"
  echo "Cannot continue without setup script."
  exit 1
fi

# ── 2. Setup detects Claude Code host ──

if grep -qiE 'claude|CLAUDE_CODE' "$SETUP"; then
  pass "setup detects Claude Code host"
else
  fail "setup does not detect Claude Code host"
fi

# ── 3. Setup detects Codex host ──

if grep -qiE 'codex|CODEX' "$SETUP"; then
  pass "setup detects Codex host"
else
  fail "setup does not detect Codex host"
fi

# ── 4. Setup detects Cursor host ──

if grep -qiE 'cursor|CURSOR' "$SETUP"; then
  pass "setup detects Cursor host"
else
  fail "setup does not detect Cursor host"
fi

# ── 5. Claude is checked FIRST (priority over Codex) ──

CLAUDE_LINE=$(grep -niE '\.claude|CLAUDE_CODE' "$SETUP" | head -1 | cut -d: -f1)
CODEX_LINE=$(grep -niE 'codex|CODEX' "$SETUP" | head -1 | cut -d: -f1)

if [ -n "$CLAUDE_LINE" ] && [ -n "$CODEX_LINE" ]; then
  if [ "$CLAUDE_LINE" -lt "$CODEX_LINE" ]; then
    pass "Claude detection appears before Codex (line $CLAUDE_LINE < $CODEX_LINE)"
  else
    fail "Codex detection appears before Claude (Claude=$CLAUDE_LINE, Codex=$CODEX_LINE)"
  fi
else
  fail "Could not determine detection order (Claude=$CLAUDE_LINE, Codex=$CODEX_LINE)"
fi

# ── 6. Setup creates ~/.forge/ directory structure ──

if grep -qE 'mkdir.*\.(forge|FORGE)|FORGE_HOME' "$SETUP"; then
  pass "setup creates ~/.forge/ directory structure"
else
  fail "setup does not create ~/.forge/ directory"
fi

# ── 7. Setup creates memory bank file ──

if grep -q 'memory.jsonl' "$SETUP"; then
  pass "setup references memory.jsonl"
else
  fail "setup does not reference memory.jsonl"
fi

# ── 8. Setup installs skills (loop over skills directory) ──

if grep -qE 'skills/\*|skill_dir|SKILL\.md' "$SETUP"; then
  pass "setup contains skill installation logic"
else
  fail "setup missing skill installation loop"
fi

# ── 9. Setup handles nested skills ──

if grep -qiE 'nested|sub.*skill|skill_name.*nested_name' "$SETUP"; then
  pass "setup handles nested skills"
else
  fail "setup does not handle nested skills"
fi

# ── 10. host-detect.sh script exists and is executable ──

HOST_DETECT="$ROOT/scripts/host-detect.sh"
if [ -f "$HOST_DETECT" ]; then
  pass "scripts/host-detect.sh exists"
  if [ -x "$HOST_DETECT" ]; then
    pass "scripts/host-detect.sh is executable"
  else
    fail "scripts/host-detect.sh is not executable"
  fi
else
  fail "scripts/host-detect.sh does not exist"
fi

# ── 11. Setup script passes bash -n syntax check ──

if bash -n "$SETUP" 2>/dev/null; then
  pass "setup passes bash -n syntax check"
else
  fail "setup has syntax errors (bash -n failed)"
fi

print_test_summary
