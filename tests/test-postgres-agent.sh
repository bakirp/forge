#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"

AGENT="$ROOT/agents/postgres-agent.md"

if [[ -f "$AGENT" ]]; then
  pass "agents/postgres-agent.md exists"
else
  fail "agents/postgres-agent.md missing"
  print_test_summary 1
fi

fm=$(sed -n '2,/^---$/p' "$AGENT" | sed '$d')

required_fields=(name description tools model)
all_ok=true
for field in "${required_fields[@]}"; do
  if ! echo "$fm" | grep -q "^${field}:"; then
    fail "postgres-agent missing required field: $field"
    all_ok=false
  fi
done

if $all_ok; then
  pass "postgres-agent has all required frontmatter fields"
fi

if echo "$fm" | grep -q '^model: opus'; then
  pass "postgres-agent uses model: opus"
else
  fail "postgres-agent does not use model: opus"
fi

tools_line=$(echo "$fm" | grep '^tools:')
if echo "$tools_line" | grep -q 'Edit'; then
  fail "postgres-agent has Edit tool (should be read-only)"
else
  pass "postgres-agent does not have Edit tool"
fi

if grep -q 'node \./bin/pg-agent\.mjs' "$AGENT"; then
  pass "postgres-agent references the pg-agent CLI"
else
  fail "postgres-agent does not reference the pg-agent CLI"
fi

if grep -qi 'never use MCP' "$AGENT"; then
  pass "postgres-agent forbids MCP"
else
  fail "postgres-agent does not forbid MCP"
fi

if grep -q 'LIMIT' "$AGENT"; then
  pass "postgres-agent prefers bounded queries"
else
  fail "postgres-agent does not mention LIMIT"
fi

if grep -q 'PG_URL' "$AGENT" && grep -q 'PG\*' "$AGENT"; then
  pass "postgres-agent documents environment-based connection input"
else
  fail "postgres-agent does not document environment-based connection input"
fi

if grep -q 'semicolon-style Npgsql string' "$AGENT"; then
  pass "postgres-agent documents unsupported semicolon connection strings"
else
  fail "postgres-agent does not document unsupported semicolon connection strings"
fi

print_test_summary 8
