---
name: document-release
description: "Post-ship documentation sync. Reads the shipped PR and updates README, CHANGELOG, API docs, and other documentation to reflect what was released. Use after shipping — triggered by 'update the docs', 'sync documentation', 'update changelog', 'docs are stale'."
argument-hint: "[optional: PR number or version tag]"
allowed-tools: Read Grep Glob Write Edit Bash
---

# /document-release — Post-Ship Documentation Sync

## Step 1 — Identify Release

From `$ARGUMENTS`:
- **PR number**: `gh pr view <number> --json title,body,files,mergedAt`
- **Version tag**: `git log <tag>..HEAD --oneline` or `git show <tag>`
- **No argument**: `gh pr list --state merged --limit 1 --json number,title`

Store PR title, body, merged date, and changed files list.

## Step 2 — Gather Release Context

Read PR body for feature descriptions, breaking changes, migration notes. Pull commit history (`gh pr view <number> --json commits`). Check `docs/` and `ARCHITECTURE.md` for references. Categorize changed files: source, config, docs, new files.

## Step 3 — Identify Docs to Update

Scan for potentially stale documentation:
- **README.md** — features list, installation, usage/API examples
- **CHANGELOG.md** — add entry if not already updated by `/ship`
- **API docs** — OpenAPI specs, JSDoc, generated docs if API routes changed
- **docs/** — guides, tutorials, references mentioning changed features
- **CLAUDE.md** — if workflow conventions or skill behavior changed

For each: does it reference changed items, is it missing new feature info, do version numbers need updating? Flag uncertain staleness rather than guessing.

## Step 4 — Apply Updates

Show proposed changes before applying; wait for user approval per file. Use targeted edits via Edit tool. Patterns:
- **CHANGELOG.md**: New entry at top under correct version; grouped by Added/Changed/Fixed/Removed.
- **README.md**: Update feature lists, badge versions, examples, installation steps.
- **API docs / Guides**: Update endpoint descriptions, schemas, instructions referencing changed behavior.

## Step 5 — Report

```
FORGE /document-release — Complete
Release: [PR title or version]
Docs updated: [file — what changed] per file
Docs reviewed but unchanged: [list]
Suggested commit: docs: update for [version or PR title]
```

## Rules & Compliance

- **Docs only** — never modify source code; flag source issues without fixing.
- **Show changes before applying** — never silently update docs. Flag uncertain staleness.
- **CHANGELOG entries must be human-readable** — summarize for end users, not raw git log.
- **Commit separately** — `docs: update for [version]`, never mix into feature commits.
- **Preserve style** — match tone, formatting, structure. If docs are auto-generated, update the source.

Follow `skills/shared/compliance-telemetry.md`. Log via `scripts/compliance-log.sh`. Keys: `source-code-modified` (critical) — source changed during docs-only skill; `silent-update` (major) — docs updated without showing user; `mixed-commit` (major) — doc changes mixed into feature commit.

After document-release, recommend `/retro`. See `skills/shared/rules.md` and `skills/shared/workflow-routing.md`.
