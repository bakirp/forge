---
name: document-release
description: "Post-ship documentation sync. Reads the shipped PR and updates README, CHANGELOG, API docs, and other documentation to reflect what was released. Use after shipping — triggered by 'update the docs', 'sync documentation', 'update changelog', 'docs are stale'."
argument-hint: "[optional: PR number or version tag]"
allowed-tools: Read Grep Glob Write Edit Bash
---

# /document-release — Post-Ship Documentation Sync

Automatically update project documentation to reflect what was just shipped.

## Step 1 — Identify Release

Determine the release to document from `$ARGUMENTS`:

- If a **PR number** is provided: `gh pr view <number> --json title,body,files,mergedAt`
- If a **version tag** is provided: `git log <tag>..HEAD --oneline` or `git show <tag>`
- If **no argument**: detect the most recent merged PR via `gh pr list --state merged --limit 1 --json number,title`

Store the PR title, body, merged date, and list of changed files for subsequent steps.

## Step 2 — Gather Release Context

Collect everything needed to write accurate documentation:

1. Read the **PR body** for feature descriptions, breaking changes, and migration notes.
2. Pull the **commit history** for the PR: `gh pr view <number> --json commits`.
3. Check if an **architecture doc** exists for this feature (search `docs/`, `ARCHITECTURE.md`, or arch docs referenced in the PR).
4. Get the **full changed files list**: `gh pr view <number> --json files` and categorize them:
   - Source code changes (features, fixes)
   - Configuration changes
   - Existing documentation changes
   - New files added

## Step 3 — Identify Docs to Update

Scan the project for documentation that may be stale after this release:

- **README.md** — features list, installation instructions, usage examples, API examples
- **CHANGELOG.md** — add entry if not already updated by `/ship`
- **API docs** — OpenAPI specs (`openapi.yaml`, `swagger.json`), JSDoc, or generated docs if API routes or contracts changed
- **docs/ directory** — any guides, tutorials, or references that mention changed features
- **CLAUDE.md** — if workflow conventions or skill behavior changed

For each file, determine:
- Does it reference anything that changed in this release?
- Is the file missing information about new features?
- Are there version numbers or dates that need updating?

Flag any file where staleness is uncertain rather than guessing.

## Step 4 — Apply Updates

For each documentation file that needs updating:

1. **Show the proposed change** before applying it — display the diff or describe the edit.
2. Wait for user approval before modifying each file.
3. Make **targeted edits** — do not rewrite entire files. Use the Edit tool for surgical changes.
4. Specific update patterns:
   - **CHANGELOG.md**: Add a new entry at the top under the correct version heading. Use human-readable descriptions, not raw commit messages. Group by: Added, Changed, Fixed, Removed.
   - **README.md**: Update feature lists, badge versions, example code, and installation steps as needed.
   - **API docs**: Update endpoint descriptions, request/response schemas, and examples.
   - **Guides**: Update step-by-step instructions that reference changed behavior.

## Step 5 — Report

After all updates are applied, output the summary:

```
FORGE /document-release — Complete

Release: [PR title or version]
Docs updated:
- README.md: [what changed]
- CHANGELOG.md: [what changed]
- [other files]: [what changed]

Docs reviewed but unchanged:
- [files that were checked but needed no updates]

Commit these documentation changes separately from the feature work.
Suggested commit message: docs: update for [version or PR title]
```

## Rules

- **Never modify source code** — this skill touches documentation only. If you find a source code issue, flag it but do not fix it.
- **Show changes before applying** — let the user approve each documentation edit. Never silently update docs.
- **If unsure whether a doc is stale, flag it** — present the question to the user rather than guessing. False positives are better than silent staleness.
- **CHANGELOG entries must be human-readable** — summarize what changed and why, not raw git log output. Write for the end user, not the developer.
- **Commit doc changes separately** — documentation updates should be their own commit with a message like `docs: update for [version]`, not mixed into feature commits.
- **Preserve existing doc style** — match the tone, formatting, and structure of existing documentation. Do not impose a new style.
- **Respect doc generators** — if docs are auto-generated (e.g., from JSDoc or OpenAPI), update the source, not the generated output.
