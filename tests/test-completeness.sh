#!/usr/bin/env bash
set -euo pipefail

# FORGE test: completeness checks across core skills
# Run from project root: bash tests/test-completeness.sh

RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
RST='\033[0m'

FAILS=0
SKIPS=0

pass() { printf "${GRN}PASS${RST}: %s\n" "$1"; }
fail() { printf "${RED}FAIL${RST}: %s\n" "$1"; FAILS=$((FAILS + 1)); }
skip() { printf "${YEL}SKIP${RST}: %s\n" "$1"; SKIPS=$((SKIPS + 1)); }
warn() { printf "${YEL}WARN${RST}: %s\n" "$1"; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── 1. Evidence-before-claims: core skills should contain the principle ──

EVIDENCE_REQUIRED=(build review verify ship)

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

DIR_CREATION_SKILLS=(architect review verify browse ship)

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

# ── Summary ──

echo ""
echo "──────────────────────────────"
printf "Failures: %d  Skipped: %d\n" "$FAILS" "$SKIPS"
exit "$FAILS"
