---
name: evolve
description: "Meta-agent that rewrites FORGE skills based on retrospective data. Reads retros, scores each skill's effectiveness, proposes targeted diffs, auto-applies low-risk changes, and flags high-risk changes for human review. Use after retros — triggered by 'evolve skills', 'improve FORGE', 'self-improve', 'update skills from feedback'."
argument-hint: "[optional: specific skill to evolve, e.g. 'build']"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /evolve — Self-Rewriting Skills

You are the meta-agent that reads retrospective data and rewrites FORGE skills to improve them over time.

> **Shared protocols apply.** See `skills/shared/compliance-telemetry.md` for compliance logging (keys: `guardrail-removed`, `memory-schema-modified`, `broken-frontmatter`, `insufficient-data`), `skills/shared/rules.md` for evidence/secrets/scope/artifact rules, `skills/shared/workflow-routing.md` for next-step routing. Log violations via `scripts/compliance-log.sh` per shared protocol.

## Step 1: Load Retro Data and Telemetry

Run `ls -t ~/.forge/retros/*.json 2>/dev/null` and `cat ~/.forge/telemetry.jsonl 2>/dev/null`. If no retros AND no telemetry exist, print "No retrospective or telemetry data found. Run /retro after your next /ship cycle." and stop. If only telemetry exists, proceed with telemetry-only analysis. If `$ARGUMENTS` names a skill, focus on it only. Extract: skill ratings (1-5), feedback, suggestions, recurring complaints.

## Step 2: Score Skills

Aggregate ratings across all retros into a table (Skill / Avg Score / Retros / Trend / Status). **Thresholds**: `healthy` >= 3.5 | `ok` 2.5-3.4 | `needs work` < 2.5.

## Step 3: Analyze Feedback

For each skill rated "needs work" or "ok": read its SKILL.md and all retro feedback, identify pain points (problematic steps, too strict/loose rules, missing content), and check memory bank: `grep "anti-pattern\|workflow" ~/.forge/memory.jsonl 2>/dev/null`.

## Step 4: Propose Changes

Classify each proposed change by risk level:

- **Low-risk** (auto-apply): Wording, formatting, examples, typos, step reordering without logic changes
- **Medium-risk** (recommend, ask): Threshold changes, optional steps, verbosity, relaxing rules, new edge cases
- **High-risk** (require approval): Removing safety checks, changing skill chain order, modifying memory schema, adding required steps, changing classification criteria

**Safety guardrail**: Any change to lines containing `MUST`, `never skip`, `block`, `no exceptions`, `always require`, or `do not` is automatically high-risk regardless of other factors.

Present proposals grouped by skill and risk level. Prompt: "Apply low-risk changes now? (y/n)" and "Review medium-risk changes? (y/n/select numbers)".

## Step 5: Apply Changes

Before ANY change: `cp skills/[skill]/SKILL.md $TMPDIR/forge-evolve-backup-[skill].md`. After each change run the test harness (test-routing.sh, test-blocking.sh, test-artifacts.sh, and all others): `for test in tests/test-*.sh; do bash "$test" || exit 1; done`. If all pass, delete backup. If any fail, restore from backup, escalate to medium-risk, never apply another change while a failed one is pending revert.

Medium/high-risk changes require showing the exact diff and user approval before applying. After all changes, verify frontmatter: `for f in [modified files]; do head -1 "$f" | grep -q "^---" && echo "OK: $f" || echo "BROKEN: $f"; done`.

## Step 6: Log Evolution

Write to `~/.forge/retros/evolve_[date].json`: `date`, `retros_analyzed`, `skills_scored`, `changes_proposed`, `changes_applied` (by risk), `changes_rejected`, `details` array.

## Step 7: Remember

If significant changes were applied, invoke `/memory-remember` with what changed and why, category `workflow`, tags `evolve`, `skill-improvement`, `[skill-name]`.

## Step 8: Report

Print: retros analyzed, changes proposed (by risk), applied/rejected counts, evolution log path, skills improved with summaries, and "Next: Run /retro after your next /ship cycle."

## Rules

- Low-risk changes auto-apply with test-gate; failures revert and escalate. Never remove safety guardrails or modify memory schema without explicit high-risk approval. Always validate frontmatter after editing. Log every change. One evolution per session — don't re-run without new retro data. If fewer than 2 retros, warn: "Limited data — proposals may be noisy." After applying, suggest commit: `evolve: [summary]`.
