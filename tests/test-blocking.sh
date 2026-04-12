#!/usr/bin/env bash
set -euo pipefail

# FORGE test: blocking / gate logic in skill files
# Run from project root: bash tests/test-blocking.sh

source "$(dirname "$0")/lib/test-helpers.sh"

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

  if grep -q 'resolve-feature-name' "$SHIP" && grep -q '\.forge/verify/' "$SHIP"; then
    pass "/ship uses resolve-feature-name for .forge/verify/ artifacts"
  else
    fail "/ship does not use resolve-feature-name pattern for verify artifacts"
  fi
fi

# ── 2. /ship blocks on /review failures ──

if require_skill ship; then
  if grep -q 'resolve-feature-name' "$SHIP" && grep -q '\.forge/review/' "$SHIP"; then
    pass "/ship uses resolve-feature-name for .forge/review/ artifacts"
  else
    fail "/ship does not use resolve-feature-name pattern for review artifacts"
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

# ── 8. /review has runtime behavior analysis step ──

if [[ -f "$REVIEW" ]]; then
  if grep -qiE 'runtime behavior|what happens when this.*execut|how.*behaves at runtime' "$REVIEW"; then
    pass "/review has runtime behavior analysis step"
  else
    fail "/review missing runtime behavior analysis step"
  fi

  if grep -qiE 'reason about runtime.*not just structure|not just.*structur' "$REVIEW"; then
    pass "/review has rule: reason about runtime, not just structure"
  else
    fail "/review missing rule: reason about runtime, not just structure"
  fi
fi

# ── 10. /debug skill (may not exist yet) ──

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

# ── 11. /ship STALE blocking for review report ──

if require_skill ship; then
  if grep -q 'STALE' "$SHIP"; then
    pass "/ship blocks with STALE when review report commit_sha is outdated"
  else
    fail "/ship missing STALE blocking logic for review report commit_sha"
  fi
fi

# ── 12. /ship STALE blocking for verify report ──

if require_skill ship; then
  if grep -q 'STALE' "$SHIP" && grep -q 'resolve-feature-name' "$SHIP"; then
    pass "/ship blocks with STALE when report commit_sha is outdated (feature-named artifacts)"
  else
    fail "/ship missing STALE blocking for feature-named reports"
  fi
fi

# ── 13. /ship marks reports stale after auto-fix and requires re-run ──

if require_skill ship; then
  if grep -qiE 'auto.fix' "$SHIP" && grep -qiE 'stale' "$SHIP"; then
    pass "/ship marks reports stale after auto-fix and requires re-run"
  else
    fail "/ship missing auto-fix staleness requirement (re-run /review and /verify after auto-fix)"
  fi
fi

# ── 14. /build contains checkpoint after each subagent ──

if require_skill build; then
  if grep -qi 'checkpoint' "$BUILD"; then
    pass "/build contains checkpoint after each subagent before proceeding"
  else
    fail "/build missing checkpoint after each subagent"
  fi
fi

# ── 15. /build Stage 1 architecture compliance blocks merge ──

if require_skill build; then
  if grep -q 'Architecture Compliance' "$BUILD" && grep -q 'BLOCK merge' "$BUILD"; then
    pass "/build blocks merge on architecture compliance failure (Stage 1)"
  else
    fail "/build missing Architecture Compliance block-merge gate (Stage 1)"
  fi
fi

# ── 16. /build two-stage verification requires both stages to pass ──

if require_skill build; then
  if grep -q 'Stage 1' "$BUILD" && grep -q 'Stage 2' "$BUILD" && grep -q 'BLOCK merge' "$BUILD"; then
    pass "/build requires both architecture compliance and test suite to pass"
  else
    fail "/build missing two-stage verification (Stage 1 + Stage 2 with BLOCK merge)"
  fi
fi

print_test_summary
