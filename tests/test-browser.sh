#!/usr/bin/env bash
set -euo pipefail

# FORGE test: browser skill contracts (/browse and /verify web mode)
# Run from project root: bash tests/test-browser.sh

source "$(dirname "$0")/lib/test-helpers.sh"

BROWSE="$ROOT/skills/browse/SKILL.md"
VERIFY="$ROOT/skills/verify/SKILL.md"

# ── 1. /browse references Playwright ──

if [ -f "$BROWSE" ]; then
  if grep -qi 'playwright' "$BROWSE"; then
    pass "/browse references Playwright"
  else
    fail "/browse does not reference Playwright"
  fi
else
  fail "/browse SKILL.md does not exist"
fi

# ── 2. /browse produces report at .forge/browse/report.md ──

if [ -f "$BROWSE" ]; then
  if grep -q '\.forge/browse/report\.md' "$BROWSE"; then
    pass "/browse produces report at .forge/browse/report.md"
  else
    fail "/browse does not reference .forge/browse/report.md"
  fi
fi

# ── 3. /browse captures screenshots on failure ──

if [ -f "$BROWSE" ]; then
  if grep -qi 'screenshot' "$BROWSE"; then
    pass "/browse captures screenshots on failure"
  else
    fail "/browse does not mention screenshot capture"
  fi
fi

# ── 4. /browse has BLOCKED output for missing Playwright ──

if [ -f "$BROWSE" ]; then
  if grep -qE 'BLOCKED' "$BROWSE"; then
    pass "/browse has BLOCKED output for missing Playwright"
  else
    fail "/browse missing BLOCKED output pattern"
  fi
fi

# ── 5. /browse rejects non-Playwright fallbacks ──

if [ -f "$BROWSE" ]; then
  if grep -qiE 'no.*(MCP|curl|wget|fallback)|not.*fall.*back|ONLY.*browser.*automation' "$BROWSE"; then
    pass "/browse rejects non-Playwright fallbacks"
  else
    fail "/browse does not explicitly reject non-Playwright fallbacks"
  fi
fi

# ── 6. /verify delegates to /browse for web domain ──

if [ -f "$VERIFY" ]; then
  if grep -qiE '/browse|browse' "$VERIFY"; then
    pass "/verify delegates to /browse for web domain"
  else
    fail "/verify does not reference /browse delegation"
  fi
else
  fail "/verify SKILL.md does not exist"
fi

# ── 7. /verify reads browse report ──

if [ -f "$VERIFY" ]; then
  if grep -qiE '\.forge/browse|browse.*report' "$VERIFY"; then
    pass "/verify reads browse report"
  else
    fail "/verify does not reference browse report"
  fi
fi

# ── 8. /browse report has deterministic structure (Status, Flows, Summary) ──

if [ -f "$BROWSE" ]; then
  has_status=false has_flows=false has_summary=false
  grep -qi 'Status:' "$BROWSE" && has_status=true
  grep -qiE 'Flows Tested|Flows tested' "$BROWSE" && has_flows=true
  grep -qi '## Summary' "$BROWSE" && has_summary=true

  if $has_status && $has_flows && $has_summary; then
    pass "/browse report template has deterministic structure (Status, Flows, Summary)"
  else
    fail "/browse report template missing sections (status=$has_status, flows=$has_flows, summary=$has_summary)"
  fi
fi

# ── 9. /browse test file goes in .forge/browse/ ──

if [ -f "$BROWSE" ]; then
  if grep -q '\.forge/browse/' "$BROWSE"; then
    pass "/browse test files go in .forge/browse/"
  else
    fail "/browse does not reference .forge/browse/ for test files"
  fi
fi

# ── 10. /verify has runtime behavior pre-check step ──

if [ -f "$VERIFY" ]; then
  if grep -qiE 'runtime behavior|what happens when this.*runs|how it behaves at runtime' "$VERIFY"; then
    pass "/verify has runtime behavior pre-check step"
  else
    fail "/verify missing runtime behavior pre-check"
  fi
fi

# ── 11. /browse never skips testing for unfamiliar project types ──

if [ -f "$BROWSE" ]; then
  if grep -qiE 'never skip|nothing to test|not.*skip' "$BROWSE"; then
    pass "/browse never skips testing for unfamiliar project types"
  else
    fail "/browse missing rule against skipping testing"
  fi
fi

# ── 12. /browse resolves URL adaptively ──

if [ -f "$BROWSE" ]; then
  if grep -qiE 'URL Resolution|determine the base URL' "$BROWSE"; then
    pass "/browse has adaptive URL resolution"
  else
    fail "/browse missing URL resolution logic"
  fi
fi

# ── 13. /verify requires functional testing, not just structural checks ──

if [ -f "$VERIFY" ]; then
  if grep -qiE 'functional testing.*never optional|never declare PASS based on structural checks' "$VERIFY"; then
    pass "/verify requires functional testing, not just structural checks"
  else
    fail "/verify missing rule: functional testing is never optional"
  fi
fi

print_test_summary
