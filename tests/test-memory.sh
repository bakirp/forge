#!/usr/bin/env bash
set -euo pipefail

# FORGE test: memory system (append, dedup, ranking, prune safety, invalid JSON)
# Run from project root: bash tests/test-memory.sh

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
FIXTURES="$ROOT/tests/fixtures"
TMPWORK="${TMPDIR:-/tmp}/forge-test-memory-$$"
mkdir -p "$TMPWORK"
trap 'rm -rf "$TMPWORK"' EXIT

# ── 1. Valid JSONL fixture: every line is valid JSON ──

if command -v jq &>/dev/null; then
  all_valid=true
  line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if ! echo "$line" | jq empty 2>/dev/null; then
      fail "memory-valid.jsonl line $line_num is not valid JSON"
      all_valid=false
    fi
  done < "$FIXTURES/memory-valid.jsonl"
  if $all_valid; then
    pass "memory-valid.jsonl — all lines are valid JSON"
  fi
else
  skip "jq not installed — cannot validate JSON lines"
fi

# ── 2. Dedup removes duplicates ──

if command -v python3 &>/dev/null; then
  cp "$FIXTURES/memory-duplicates.jsonl" "$TMPWORK/memory.jsonl"
  BEFORE=$(wc -l < "$TMPWORK/memory.jsonl" | tr -d ' ')

  # Temporarily override HOME so memory-dedup.sh reads our test file
  HOME_ORIG="$HOME"
  export HOME="$TMPWORK"
  mkdir -p "$TMPWORK/.forge"
  cp "$FIXTURES/memory-duplicates.jsonl" "$TMPWORK/.forge/memory.jsonl"

  BEFORE=$(wc -l < "$TMPWORK/.forge/memory.jsonl" | tr -d ' ')
  bash "$ROOT/scripts/memory-dedup.sh" >/dev/null 2>&1
  AFTER=$(wc -l < "$TMPWORK/.forge/memory.jsonl" | tr -d ' ')
  export HOME="$HOME_ORIG"

  if [ "$AFTER" -lt "$BEFORE" ]; then
    pass "memory-dedup.sh reduces line count ($BEFORE → $AFTER)"
  else
    fail "memory-dedup.sh did not reduce duplicates ($BEFORE → $AFTER)"
  fi
else
  skip "python3 not installed — cannot test dedup"
fi

# ── 3. Dedup keeps most recent entry ──

if command -v python3 &>/dev/null && command -v jq &>/dev/null; then
  # After dedup (run above), check that the kept architecture entry has the later timestamp
  export HOME="$TMPWORK"
  if [ -f "$TMPWORK/.forge/memory.jsonl" ]; then
    arch_ts=$(grep '"architecture"' "$TMPWORK/.forge/memory.jsonl" | jq -r '.timestamp // empty' 2>/dev/null | head -1)
    if [ "$arch_ts" = "2025-01-10T12:00:00Z" ]; then
      pass "memory-dedup.sh keeps most recent entry (timestamp: $arch_ts)"
    elif [ -n "$arch_ts" ]; then
      fail "memory-dedup.sh kept older entry (timestamp: $arch_ts, expected 2025-01-10T12:00:00Z)"
    else
      skip "Could not extract timestamp from deduped file"
    fi
  fi
  export HOME="$HOME_ORIG"
else
  skip "jq or python3 not installed — cannot test dedup recency"
fi

# ── 4. Dedup --dry-run makes no changes ──

if command -v python3 &>/dev/null; then
  export HOME="$TMPWORK"
  cp "$FIXTURES/memory-duplicates.jsonl" "$TMPWORK/.forge/memory.jsonl"
  BEFORE_HASH=$(md5sum "$TMPWORK/.forge/memory.jsonl" 2>/dev/null || md5 -q "$TMPWORK/.forge/memory.jsonl" 2>/dev/null || echo "no-md5")

  bash "$ROOT/scripts/memory-dedup.sh" --dry-run >/dev/null 2>&1
  AFTER_HASH=$(md5sum "$TMPWORK/.forge/memory.jsonl" 2>/dev/null || md5 -q "$TMPWORK/.forge/memory.jsonl" 2>/dev/null || echo "no-md5-after")
  export HOME="$HOME_ORIG"

  if [ "$BEFORE_HASH" != "no-md5" ] && [ "$BEFORE_HASH" = "$AFTER_HASH" ]; then
    pass "memory-dedup.sh --dry-run does not modify file"
  elif [ "$BEFORE_HASH" = "no-md5" ]; then
    skip "md5 not available — cannot verify dry-run"
  else
    fail "memory-dedup.sh --dry-run modified the file"
  fi
else
  skip "python3 not installed — cannot test dry-run"
fi

# ── 5. Ranking: project match scores higher ──

if [ -x "$ROOT/scripts/memory-rank.sh" ]; then
  export HOME="$TMPWORK"
  cp "$FIXTURES/memory-valid.jsonl" "$TMPWORK/.forge/memory.jsonl"
  OUTPUT=$(bash "$ROOT/scripts/memory-rank.sh" "architecture events" "webapp" 5 2>/dev/null || true)
  export HOME="$HOME_ORIG"

  if [ -n "$OUTPUT" ]; then
    # First result should be from "webapp" project
    FIRST_LINE=$(echo "$OUTPUT" | head -1)
    if echo "$FIRST_LINE" | grep -qi "webapp"; then
      pass "memory-rank.sh ranks project-matched entries first"
    else
      fail "memory-rank.sh did not rank project match first: $FIRST_LINE"
    fi
  else
    skip "memory-rank.sh produced no output — may need jq or python3"
  fi
else
  skip "scripts/memory-rank.sh not executable — cannot test ranking"
fi

# ── 6. Ranking: tag overlap scores higher ──

if [ -x "$ROOT/scripts/memory-rank.sh" ]; then
  export HOME="$TMPWORK"
  cp "$FIXTURES/memory-valid.jsonl" "$TMPWORK/.forge/memory.jsonl"
  OUTPUT=$(bash "$ROOT/scripts/memory-rank.sh" "security secrets" "" 5 2>/dev/null || true)
  export HOME="$HOME_ORIG"

  if [ -n "$OUTPUT" ]; then
    FIRST_LINE=$(echo "$OUTPUT" | head -1)
    if echo "$FIRST_LINE" | grep -qi "security"; then
      pass "memory-rank.sh ranks tag-matched entries higher"
    else
      fail "memory-rank.sh did not rank tag match first: $FIRST_LINE"
    fi
  else
    skip "memory-rank.sh produced no output for tag test"
  fi
else
  skip "scripts/memory-rank.sh not executable — cannot test tag ranking"
fi

# ── 7. Prune safety: empty file does not crash ──

if command -v python3 &>/dev/null; then
  export HOME="$TMPWORK"
  : > "$TMPWORK/.forge/memory.jsonl"  # empty file

  if bash "$ROOT/scripts/memory-dedup.sh" >/dev/null 2>&1; then
    pass "memory-dedup.sh handles empty file without crashing"
  else
    fail "memory-dedup.sh crashed on empty file"
  fi

  if bash "$ROOT/scripts/memory-rank.sh" "test query" "" 5 >/dev/null 2>&1; then
    pass "memory-rank.sh handles empty file without crashing"
  else
    fail "memory-rank.sh crashed on empty file"
  fi
  export HOME="$HOME_ORIG"
else
  skip "python3 not installed — cannot test empty file handling"
fi

# ── 8. Invalid JSON handling: dedup does not crash on bad lines ──

if command -v python3 &>/dev/null; then
  export HOME="$TMPWORK"
  cp "$FIXTURES/memory-invalid.jsonl" "$TMPWORK/.forge/memory.jsonl"

  if bash "$ROOT/scripts/memory-dedup.sh" >/dev/null 2>&1; then
    pass "memory-dedup.sh does not crash on invalid JSON lines"
  else
    fail "memory-dedup.sh crashed on file with invalid JSON lines"
  fi

  # Verify valid lines are preserved
  VALID_COUNT=$(grep -c '"decision"' "$TMPWORK/.forge/memory.jsonl" 2>/dev/null || echo "0")
  if [ "$VALID_COUNT" -ge 3 ]; then
    pass "memory-dedup.sh preserves valid entries alongside invalid lines ($VALID_COUNT valid)"
  else
    fail "memory-dedup.sh lost valid entries (expected >=3, got $VALID_COUNT)"
  fi
  export HOME="$HOME_ORIG"
else
  skip "python3 not installed — cannot test invalid JSON handling"
fi

# ── 9. /memory-remember skill uses safe JSON construction ──

REMEMBER="$ROOT/skills/memory/remember/SKILL.md"
if [ -f "$REMEMBER" ]; then
  if grep -q 'jq' "$REMEMBER" && grep -q 'python3' "$REMEMBER"; then
    pass "/memory-remember uses jq with python3 fallback for JSON construction"
  elif grep -q 'jq' "$REMEMBER"; then
    fail "/memory-remember uses jq but has no python3 fallback"
  else
    fail "/memory-remember does not use jq for safe JSON construction"
  fi
else
  skip "/memory-remember skill not found"
fi

# ── 10. /memory-remember validates after append ──

if [ -f "$REMEMBER" ]; then
  if grep -qE 'jq empty|validate|Validate' "$REMEMBER"; then
    pass "/memory-remember validates JSON after appending"
  else
    fail "/memory-remember does not validate JSON after appending"
  fi
else
  skip "/memory-remember skill not found"
fi

# ── Summary ──

echo ""
echo "──────────────────────────────"
printf "Failures: %d  Skipped: %d\n" "$FAILS" "$SKIPS"
exit "$FAILS"
