#!/usr/bin/env bash
set -euo pipefail

# FORGE test: artifact contract consistency
# Run from project root: bash tests/test-artifacts.sh

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

# Helper: check skill file exists, print SKIP if not
require_skill() {
  local name="$1" path
  if [[ "$name" == "root" ]]; then
    path="$ROOT/SKILL.md"
  else
    path="$ROOT/skills/$name/SKILL.md"
  fi
  if [[ ! -f "$path" ]]; then
    skip "/$name not yet created — skipping its artifact tests"
    return 1
  fi
  return 0
}

# ── 1. Every skill that writes an artifact references a .forge/ path ──

WRITER_SKILLS=(architect build verify ship retro evolve)
for skill in "${WRITER_SKILLS[@]}"; do
  path="$ROOT/skills/$skill/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -q '\.forge/' "$path"; then
      pass "/$skill references a .forge/ artifact path"
    else
      fail "/$skill writes artifacts but has no .forge/ path reference"
    fi
  else
    skip "/$skill not yet created"
  fi
done

# ── 2. /architect references .forge/architecture/ ──

if require_skill architect; then
  path="$ROOT/skills/architect/SKILL.md"
  if grep -q '\.forge/architecture/' "$path"; then
    pass "/architect references .forge/architecture/"
  else
    fail "/architect does not reference .forge/architecture/"
  fi
fi

# ── 3. /verify references .forge/verify/report.md ──

if require_skill verify; then
  path="$ROOT/skills/verify/SKILL.md"
  if grep -q '\.forge/verify/report\.md' "$path"; then
    pass "/verify references .forge/verify/report.md"
  else
    fail "/verify does not reference .forge/verify/report.md"
  fi
fi

# ── 4. /review references .forge/review/report.md ──

if require_skill review; then
  path="$ROOT/skills/review/SKILL.md"
  if grep -q '\.forge/review/report\.md' "$path"; then
    pass "/review references .forge/review/report.md"
  else
    fail "/review does not reference .forge/review/report.md"
  fi
else
  skip "/review not yet created — cannot check .forge/review/report.md reference"
fi

# ── 5. /debug references .forge/debug/report.md ──

if require_skill debug; then
  path="$ROOT/skills/debug/SKILL.md"
  if grep -q '\.forge/debug/report\.md' "$path"; then
    pass "/debug references .forge/debug/report.md"
  else
    fail "/debug does not reference .forge/debug/report.md"
  fi
else
  skip "/debug not yet created — cannot check .forge/debug/report.md reference"
fi

# ── 6. Run manifest path .forge/runs/ is referenced in root SKILL.md ──

ROOT_SKILL="$ROOT/skills/forge/SKILL.md"
if grep -q '\.forge/runs/' "$ROOT_SKILL"; then
  pass "Root SKILL.md references .forge/runs/ (run manifest)"
else
  fail "Root SKILL.md does not reference .forge/runs/ (run manifest not yet wired)"
fi

# ── 7. No skill references a project-local .forge/ path outside the known schema ──
#    Known project-local artifact dirs: architecture, verify, review, debug, runs
#    Paths under ~/.forge/ (retros, memory.jsonl) are user-home paths, not project artifacts.

KNOWN_PATHS="architecture|verify|review|debug|runs|browse|brainstorm|design|benchmark|releases|worktrees|deploy|autopilot|context"

all_clean=true
while IFS= read -r skill_file; do
  rel="${skill_file#"$ROOT/"}"
  # Extract unique project-local .forge/<subdir> refs (exclude ~/. and $HOME/.)
  subdirs=$(grep -oE '[^~$/]\.forge/[a-z][-a-z]*/' "$skill_file" 2>/dev/null \
    | sed -E 's|.*\.forge/([^/]+)/.*|\1|' | sort -u || true)
  for subdir in $subdirs; do
    if ! echo "$subdir" | grep -qE "^($KNOWN_PATHS)$"; then
      fail "$rel references unknown project artifact path: .forge/$subdir/"
      all_clean=false
    fi
  done
done < <(find "$ROOT" -name SKILL.md -not -path '*/.git/*')

if $all_clean; then
  pass "All project-local .forge/ references match the known artifact schema"
fi

# ── 8. Cross-check: /ship reads the same verify report path that /verify writes ──

if require_skill verify && require_skill ship; then
  V_PATH=$(grep -oE '\.forge/verify/report\.md' "$ROOT/skills/verify/SKILL.md" | head -1)
  S_PATH=$(grep -oE '\.forge/verify/report\.md' "$ROOT/skills/ship/SKILL.md" | head -1)
  if [[ -n "$V_PATH" && "$V_PATH" == "$S_PATH" ]]; then
    pass "/verify write path matches /ship read path ($V_PATH)"
  else
    fail "/verify and /ship disagree on verify report path"
  fi
fi

# ── 9. Cross-skill format contracts: /verify and /review contain "## Status:" ──

VERIFY_FILE="$ROOT/skills/verify/SKILL.md"
REVIEW_FILE="$ROOT/skills/review/SKILL.md"
SHIP_FILE="$ROOT/skills/ship/SKILL.md"

if [[ -f "$VERIFY_FILE" ]]; then
  if grep -q '## Status:' "$VERIFY_FILE"; then
    pass "/verify SKILL.md contains '## Status:'"
  else
    fail "/verify SKILL.md missing '## Status:' format"
  fi
fi

if [[ -f "$REVIEW_FILE" ]]; then
  if grep -q '## Status:' "$REVIEW_FILE"; then
    pass "/review SKILL.md contains '## Status:'"
  else
    fail "/review SKILL.md missing '## Status:' format"
  fi
fi

if [[ -f "$SHIP_FILE" ]]; then
  if grep -qi 'Status:' "$SHIP_FILE"; then
    pass "/ship SKILL.md references 'Status:'"
  else
    fail "/ship SKILL.md does not reference 'Status:' (cannot parse verify/review reports)"
  fi
fi

# ── 10. /architect contains all fields that /build parses in Step 1 ──

ARCH_FILE="$ROOT/skills/architect/SKILL.md"
if [[ -f "$ARCH_FILE" ]]; then
  ARCH_FIELDS=(Component "API contracts" "Test strategy" "Edge cases" Dependencies)
  arch_ok=true
  for field in "${ARCH_FIELDS[@]}"; do
    if grep -qi "$field" "$ARCH_FILE"; then
      pass "/architect contains '$field' (parsed by /build)"
    else
      fail "/architect missing '$field' (or variant) — /build Step 1 expects it"
      arch_ok=false
    fi
  done
else
  fail "/architect SKILL.md does not exist"
fi

# ── 11. /browse report path referenced in both /browse and /verify ──

BROWSE_FILE="$ROOT/skills/browse/SKILL.md"
if [[ -f "$BROWSE_FILE" && -f "$VERIFY_FILE" ]]; then
  BROWSE_PATH=".forge/browse/report.md"
  if grep -q "$BROWSE_PATH" "$BROWSE_FILE"; then
    pass "/browse references $BROWSE_PATH"
  else
    fail "/browse does not reference $BROWSE_PATH"
  fi
  if grep -q "$BROWSE_PATH" "$VERIFY_FILE"; then
    pass "/verify references $BROWSE_PATH"
  else
    fail "/verify does not reference $BROWSE_PATH"
  fi
else
  skip "/browse or /verify not found — skipping browse report path cross-check"
fi

# ── 12. /review SKILL.md stamps commit_sha into report artifact ──

if require_skill review; then
  if grep -q 'commit_sha' "$REVIEW_FILE"; then
    pass "/review SKILL.md stamps commit_sha into report artifact"
  else
    fail "/review SKILL.md does not stamp commit_sha into report artifact"
  fi
fi

# ── 13. /verify SKILL.md stamps commit_sha into report artifact ──

if require_skill verify; then
  if grep -q 'commit_sha' "$VERIFY_FILE"; then
    pass "/verify SKILL.md stamps commit_sha into report artifact"
  else
    fail "/verify SKILL.md does not stamp commit_sha into report artifact"
  fi
fi

# ── 14. artifact schema defines commit_sha field ──

SCHEMA_FILE="$ROOT/docs/artifact-schema.md"
if [[ -f "$SCHEMA_FILE" ]]; then
  if grep -q 'commit_sha' "$SCHEMA_FILE"; then
    pass "artifact schema defines commit_sha field"
  else
    fail "artifact schema does not define commit_sha field"
  fi
else
  skip "docs/artifact-schema.md not found — skipping commit_sha schema check"
fi

# ── 15. artifact-check.sh validates commit_sha freshness against HEAD ──

ARTIFACT_CHECK="$ROOT/scripts/artifact-check.sh"
if [[ -f "$ARTIFACT_CHECK" ]]; then
  if grep -q 'commit_sha' "$ARTIFACT_CHECK" && grep -q 'STALE' "$ARTIFACT_CHECK"; then
    pass "artifact-check.sh validates commit_sha freshness against HEAD"
  else
    fail "artifact-check.sh does not validate commit_sha freshness (missing commit_sha or STALE)"
  fi
else
  skip "scripts/artifact-check.sh not found — skipping commit_sha freshness check"
fi

# ── 16. /review stamps both commit_sha and tree_hash into report ──

if require_skill review; then
  if grep -q 'commit_sha' "$REVIEW_FILE" && grep -q 'tree_hash' "$REVIEW_FILE"; then
    pass "/review stamps both commit_sha and tree_hash into report"
  else
    fail "/review SKILL.md missing commit_sha or tree_hash stamp"
  fi
fi

# ── 17. /verify stamps both commit_sha and tree_hash into report ──

if require_skill verify; then
  if grep -q 'commit_sha' "$VERIFY_FILE" && grep -q 'tree_hash' "$VERIFY_FILE"; then
    pass "/verify stamps both commit_sha and tree_hash into report"
  else
    fail "/verify SKILL.md missing commit_sha or tree_hash stamp"
  fi
fi

# ── Summary ──

echo ""
echo "──────────────────────────────"
printf "Failures: %d  Skipped: %d\n" "$FAILS" "$SKIPS"
exit "$FAILS"
