#!/usr/bin/env bash
set -euo pipefail

# FORGE test: skill routing structure
# Run from project root: bash tests/test-routing.sh

source "$(dirname "$0")/lib/test-helpers.sh"

# ── 1. Every SKILL.md has valid YAML frontmatter with all 4 required fields ──

REQUIRED_FIELDS=(name description argument-hint allowed-tools)

while IFS= read -r skill_file; do
  rel="${skill_file#"$ROOT/"}"
  # Check for opening and closing frontmatter delimiters
  if ! head -1 "$skill_file" | grep -q '^---'; then
    fail "$rel missing opening frontmatter delimiter"
    continue
  fi
  # Extract frontmatter (between first and second ---)
  fm=$(sed -n '2,/^---$/p' "$skill_file" | sed '$d')
  all_ok=true
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$fm" | grep -q "^${field}:"; then
      fail "$rel missing required field: $field"
      all_ok=false
    fi
  done

  if $all_ok; then
    pass "$rel has all 4 required frontmatter fields"
  fi
done < <(find "$ROOT" -name SKILL.md -not -path '*/.git/*')

# ── 2. Root SKILL.md (bootstrap) exists and references key skills ──

ROOT_SKILL="$ROOT/skills/forge/SKILL.md"
if [[ -f "$ROOT_SKILL" ]]; then
  pass "Root SKILL.md exists"
  for cmd in think architect build verify ship memory evolve; do
    if grep -qi "/$cmd" "$ROOT_SKILL"; then
      pass "Root SKILL.md references /$cmd"
    else
      fail "Root SKILL.md does not reference /$cmd"
    fi
  done
else
  fail "Root SKILL.md does not exist"
fi

# ── 3. /think contains complexity classification keywords ──

THINK="$ROOT/skills/think/SKILL.md"
if [[ -f "$THINK" ]]; then
  for level in tiny feature epic; do
    if grep -qi "$level" "$THINK"; then
      pass "/think contains complexity level: $level"
    else
      fail "/think missing complexity level: $level"
    fi
  done
else
  fail "/think SKILL.md does not exist"
fi

# ── 4. /think should contain debug-related routing keywords ──

if [[ -f "$THINK" ]]; then
  if grep -qiE 'debug|diagnos|investigat|troubleshoot' "$THINK"; then
    pass "/think contains debug-routing keywords"
  else
    fail "/think does not contain debug-routing keywords (debug/diagnose/investigate)"
  fi
fi

# ── 5. All skills listed in the Skills table actually exist as files ──
#    Only match the command column pattern: "| `/name`" in the Skills table

KNOWN_SKILLS=(think architect build verify ship memory evolve retro autopilot)
for ref in "${KNOWN_SKILLS[@]}"; do
  skill_dir="$ROOT/skills/$ref"
  if [[ -f "$skill_dir/SKILL.md" ]]; then
    pass "Skill /$ref has SKILL.md"
  else
    fail "Skill /$ref has no SKILL.md at skills/$ref/SKILL.md"
  fi
done

# ── 6. No orphan skills (exist but not reachable from root) ──

# Collect top-level skill directory names (exclude memory sub-skills)
existing=""
while IFS= read -r f; do
  s=$(echo "$f" | sed "s|$ROOT/skills/||;s|/SKILL.md||")
  existing="$existing $s"
done < <(find "$ROOT/skills" -maxdepth 2 -name SKILL.md -not -path '*/memory/*')

for skill in $existing; do
  if grep -qiE "/$skill[ |)\`]" "$ROOT_SKILL"; then
    pass "Skill /$skill is reachable from root SKILL.md"
  else
    fail "Orphan skill /$skill exists but is not referenced in root SKILL.md"
  fi
done

# ── 7. /think has disambiguation logic for ambiguous tasks ──

if [[ -f "$THINK" ]]; then
  if grep -qiE 'tiebreaker|disambiguat|ambiguous.*ask|ambiguous' "$THINK"; then
    pass "/think contains disambiguation logic"
  else
    fail "/think missing disambiguation logic (tiebreaker/disambiguate/ambiguous)"
  fi
fi

# ── 8. /review has sub-command routing ──

REVIEW="$ROOT/skills/review/SKILL.md"
if [[ -f "$REVIEW" ]]; then
  if grep -qiE 'review-request|review-response' "$REVIEW"; then
    pass "/review has sub-command routing (review-request/review-response)"
  else
    fail "/review missing sub-command routing (review-request/review-response)"
  fi
else
  fail "/review SKILL.md does not exist"
fi

print_test_summary
