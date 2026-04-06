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
EVIDENCE_OPTIONAL=(think architect)

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

for skill in "${EVIDENCE_OPTIONAL[@]}"; do
  path="$ROOT/skills/$skill/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -qi 'evidence before claims' "$path"; then
      pass "/$skill contains 'evidence before claims'"
    else
      warn "/$skill does not contain 'evidence before claims' (optional for this skill)"
    fi
  else
    skip "/$skill not found"
  fi
done

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

# ── Summary ──

echo ""
echo "──────────────────────────────"
printf "Failures: %d  Skipped: %d\n" "$FAILS" "$SKIPS"
exit "$FAILS"
