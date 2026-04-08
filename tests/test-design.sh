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

  for section in "Anti-Pattern" "Aesthetic Direction" "Accessibility Baseline" "State Coverage" "Design Token" "AI Design Fingerprints" "Usability Heuristics" "Review Angles"; do
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

for sub in consult explore review audit polish; do
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

for sub in consult explore review audit polish; do
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

for file in "$DESIGN/SKILL.md" "$DESIGN/consult/SKILL.md" "$DESIGN/explore/SKILL.md" "$DESIGN/review/SKILL.md" "$DESIGN/audit/SKILL.md" "$DESIGN/polish/SKILL.md" "$PRINCIPLES"; do
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

for file in "$DESIGN/SKILL.md" "$DESIGN/consult/SKILL.md" "$DESIGN/explore/SKILL.md" "$DESIGN/review/SKILL.md" "$DESIGN/audit/SKILL.md" "$DESIGN/polish/SKILL.md"; do
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

check_words "$DESIGN/SKILL.md" 600 "hub"
check_words "$DESIGN/consult/SKILL.md" 1000 "consult"
check_words "$DESIGN/explore/SKILL.md" 800 "explore"
check_words "$DESIGN/review/SKILL.md" 1100 "review"
check_words "$DESIGN/audit/SKILL.md" 1100 "audit"
check_words "$DESIGN/polish/SKILL.md" 1000 "polish"
check_words "$PRINCIPLES" 1100 "principles"

# ── 7. Hub routes match existing sub-skill directories ──

if [[ -f "$DESIGN/SKILL.md" ]]; then
  for sub in consult explore review audit polish; do
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

# ── 10. Domain reference files exist ──

for ref in typography.md color-and-contrast.md interaction-design.md motion-design.md responsive-design.md; do
  if [[ -f "$DESIGN/references/$ref" ]]; then
    pass "reference $ref exists"
  else
    fail "reference $ref not found"
  fi
done

# ── 11. Audit and polish reference domain-specific files ──

if [[ -f "$DESIGN/audit/SKILL.md" ]]; then
  if grep -q 'interaction-design.md' "$DESIGN/audit/SKILL.md" && grep -q 'responsive-design.md' "$DESIGN/audit/SKILL.md"; then
    pass "/design-audit references interaction-design.md and responsive-design.md"
  else
    fail "/design-audit missing domain reference files"
  fi
fi

if [[ -f "$DESIGN/polish/SKILL.md" ]]; then
  if grep -q 'typography.md' "$DESIGN/polish/SKILL.md" && grep -q 'color-and-contrast.md' "$DESIGN/polish/SKILL.md"; then
    pass "/design-polish references typography.md and color-and-contrast.md"
  else
    fail "/design-polish missing domain reference files"
  fi
fi

# ── 12. Review skill has usability heuristics and review angles ──

if [[ -f "$DESIGN/review/SKILL.md" ]]; then
  if grep -qi 'Usability Heuristics' "$DESIGN/review/SKILL.md"; then
    pass "/design-review has Usability Heuristics step"
  else
    fail "/design-review missing Usability Heuristics step"
  fi

  if grep -qi 'Review Angle' "$DESIGN/review/SKILL.md"; then
    pass "/design-review has Review Angles step"
  else
    fail "/design-review missing Review Angles step"
  fi

  if grep -qi 'AI.*[Ss]lop\|AI Design Fingerprint' "$DESIGN/review/SKILL.md"; then
    pass "/design-review has AI slop/fingerprint detection"
  else
    fail "/design-review missing AI slop/fingerprint detection"
  fi
fi

print_test_summary
