#!/usr/bin/env bash
set -euo pipefail

# FORGE test: blocking / gate logic in skill files
# Run from project root: bash tests/test-blocking.sh

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

# Helper: check if a skill file exists, printing SKIP if not
require_skill() {
  local name="$1" path="$ROOT/skills/$1/SKILL.md"
  if [[ ! -f "$path" ]]; then
    skip "/$name not yet created — skipping its blocking tests"
    return 1
  fi
  return 0
}

# ── 1. /ship blocks on /verify failures ──

SHIP="$ROOT/skills/ship/SKILL.md"
if require_skill ship; then
  if grep -qi 'verify' "$SHIP" && grep -qiE 'block|BLOCKED|not proceed|not allowed' "$SHIP"; then
    pass "/ship contains blocking logic for /verify"
  else
    fail "/ship missing blocking logic for /verify failures"
  fi

  if grep -q '\.forge/verify/report\.md' "$SHIP"; then
    pass "/ship references .forge/verify/report.md"
  else
    fail "/ship does not reference .forge/verify/report.md"
  fi
fi

# ── 2. /ship blocks on /review failures ──

if require_skill ship; then
  if grep -q '\.forge/review/report\.md' "$SHIP"; then
    pass "/ship references .forge/review/report.md"
  else
    fail "/ship does not reference .forge/review/report.md (review gate not yet wired)"
  fi

  if grep -qiE 'review.*block|review.*gate|review.*report' "$SHIP"; then
    pass "/ship contains review-gate logic"
  else
    fail "/ship missing review-gate logic (/review blocking not yet wired)"
  fi
fi

# ── 3. /verify contains "Blocked" output pattern ──

VERIFY="$ROOT/skills/verify/SKILL.md"
if require_skill verify; then
  if grep -qiE 'block' "$VERIFY"; then
    pass "/verify contains 'Blocked' output pattern"
  else
    fail "/verify missing 'Blocked' output pattern"
  fi
fi

# ── 4. /build contains TDD enforcement ──

BUILD="$ROOT/skills/build/SKILL.md"
if require_skill build; then
  if grep -qiE 'tests MUST fail|tests must fail|MUST fail' "$BUILD"; then
    pass "/build contains TDD enforcement ('tests MUST fail')"
  else
    fail "/build missing TDD enforcement ('tests MUST fail' or equivalent)"
  fi
fi

# ── 5. /evolve contains approval requirement (no auto-apply for risky changes) ──

EVOLVE="$ROOT/skills/evolve/SKILL.md"
if require_skill evolve; then
  if grep -qiE 'approval|explicit.*approv|user.*approv|require.*approv' "$EVOLVE"; then
    pass "/evolve requires approval for non-trivial changes"
  else
    fail "/evolve missing approval requirement — risks unconditional auto-apply"
  fi

  if grep -qiE 'auto.apply.*low.risk|low.risk.*auto' "$EVOLVE"; then
    pass "/evolve limits auto-apply to low-risk changes only"
  else
    fail "/evolve does not clearly limit auto-apply to low-risk changes"
  fi
fi

# ── 6. Each blocking skill has a BLOCKED output format ──

for skill in ship verify; do
  path="$ROOT/skills/$skill/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -qE 'BLOCKED|— Blocked' "$path"; then
      pass "/$skill has BLOCKED output format"
    else
      fail "/$skill missing BLOCKED output format"
    fi
  fi
done

# ── 7. /review skill blocking tests (may not exist yet) ──

REVIEW="$ROOT/skills/review/SKILL.md"
if [[ -f "$REVIEW" ]]; then
  if grep -qiE 'FAIL|NEEDS_CHANGES|ERROR' "$REVIEW"; then
    pass "/review contains verdict output patterns (FAIL/NEEDS_CHANGES/ERROR)"
  else
    fail "/review missing verdict output patterns"
  fi
else
  skip "/review not yet created — skipping review blocking tests"
fi

# ── 8. /debug skill (may not exist yet) ──

DEBUG="$ROOT/skills/debug/SKILL.md"
if [[ -f "$DEBUG" ]]; then
  if grep -qiE 'block|BLOCKED|report' "$DEBUG"; then
    pass "/debug contains report or blocking pattern"
  else
    fail "/debug missing report or blocking pattern"
  fi
else
  skip "/debug not yet created — skipping debug blocking tests"
fi

# ── Summary ──

echo ""
echo "──────────────────────────────"
printf "Failures: %d  Skipped: %d\n" "$FAILS" "$SKIPS"
exit "$FAILS"
