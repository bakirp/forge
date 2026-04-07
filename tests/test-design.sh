#!/usr/bin/env bash
set -euo pipefail

# FORGE test: design skill system structural compliance
# Run from project root: bash tests/test-design.sh

source "$(dirname "$0")/lib/test-helpers.sh"
DESIGN="$ROOT/skills/design"
PRINCIPLES="$DESIGN/references/principles.md"

# ── 1. principles.md exists and has required sections ──

if [[ -f "$PRINCIPLES" ]]; then
  pass "principles.md exists"

  for section in "Anti-Pattern" "Aesthetic Direction" "Accessibility Baseline" "State Coverage" "Design Token"; do
    if grep -qi "$section" "$PRINCIPLES"; then
      pass "principles.md contains '$section' section"
    else
      fail "principles.md missing '$section' section"
    fi
  done
else
  fail "principles.md not found at $PRINCIPLES"
fi

# ── 2. Each sub-skill references principles.md via explicit Read ──

for sub in consult explore review; do
  path="$DESIGN/$sub/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -q 'skills/design/references/principles.md' "$path"; then
      pass "/design-$sub references principles.md"
    else
      fail "/design-$sub missing explicit Read of principles.md"
    fi
  else
    skip "/design-$sub not found"
  fi
done

# ── 3. Each sub-skill has a Rules section with quality gate ──

for sub in consult explore review; do
  path="$DESIGN/$sub/SKILL.md"
  if [[ -f "$path" ]]; then
    if grep -qi 'quality gate\|anti-pattern blocklist' "$path"; then
      pass "/design-$sub has quality gate in Rules"
    else
      fail "/design-$sub missing quality gate in Rules section"
    fi
  else
    skip "/design-$sub not found"
  fi
done

# ── 4. No framework-specific references ──

BANNED_TERMS="React|Vue|Svelte|Angular|Tailwind|styled-components|Next\.js|Nuxt"

for file in "$DESIGN/SKILL.md" "$DESIGN/consult/SKILL.md" "$DESIGN/explore/SKILL.md" "$DESIGN/review/SKILL.md" "$PRINCIPLES"; do
  if [[ -f "$file" ]]; then
    basename=$(basename "$(dirname "$file")")/$(basename "$file")
    if grep -qE "$BANNED_TERMS" "$file"; then
      fail "$basename contains framework-specific reference"
    else
      pass "$basename has no framework-specific references"
    fi
  fi
done

# ── 5. Frontmatter compliance: all SKILL.md have required fields ──

for file in "$DESIGN/SKILL.md" "$DESIGN/consult/SKILL.md" "$DESIGN/explore/SKILL.md" "$DESIGN/review/SKILL.md"; do
  if [[ -f "$file" ]]; then
    basename=$(basename "$(dirname "$file")")/$(basename "$file")
    missing=""
    for field in "name:" "description:" "argument-hint:" "allowed-tools:"; do
      if ! grep -q "$field" "$file"; then
        missing="$missing $field"
      fi
    done
    if [[ -z "$missing" ]]; then
      pass "$basename frontmatter complete"
    else
      fail "$basename frontmatter missing:$missing"
    fi
  fi
done

# ── 6. Word count within budget ──

check_words() {
  local file="$1" max="$2" label="$3"
  if [[ -f "$file" ]]; then
    count=$(wc -w < "$file" | tr -d ' ')
    if [[ "$count" -le "$max" ]]; then
      pass "$label word count ($count <= $max)"
    else
      fail "$label word count ($count > $max limit)"
    fi
  fi
}

check_words "$DESIGN/SKILL.md" 400 "hub"
check_words "$DESIGN/consult/SKILL.md" 800 "consult"
check_words "$DESIGN/explore/SKILL.md" 700 "explore"
check_words "$DESIGN/review/SKILL.md" 800 "review"
check_words "$PRINCIPLES" 600 "principles"

# ── 7. Hub routes match existing sub-skill directories ──

if [[ -f "$DESIGN/SKILL.md" ]]; then
  for sub in consult explore review; do
    if grep -q "$sub" "$DESIGN/SKILL.md" && [[ -d "$DESIGN/$sub" ]]; then
      pass "hub routes to /$sub and directory exists"
    else
      fail "hub route/$sub mismatch"
    fi
  done
fi

# ── 8. Anti-pattern blocklist covers all 8 dimensions ──

if [[ -f "$PRINCIPLES" ]]; then
  count=0
  for dim in "Typography" "Color" "Layout" "Motion" "Content" "Interaction" "Images" "Forms"; do
    if grep -qi "$dim" "$PRINCIPLES"; then
      count=$((count + 1))
    fi
  done
  if [[ "$count" -eq 8 ]]; then
    pass "anti-pattern blocklist covers all 8 dimensions"
  else
    fail "anti-pattern blocklist covers only $count/8 dimensions"
  fi
fi

# ── 9. Aesthetic direction table has entries ──

if [[ -f "$PRINCIPLES" ]]; then
  dir_count=$(grep -c '| .* |' "$PRINCIPLES" | head -1 || echo "0")
  if [[ "$dir_count" -ge 12 ]]; then
    pass "aesthetic direction table has $dir_count entries (>= 12)"
  else
    fail "aesthetic direction table has $dir_count entries (expected >= 12)"
  fi
fi

print_test_summary
