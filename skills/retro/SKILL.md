---
name: retro
description: "Post-ship retrospective. Asks three structured questions about what slowed you down, what you'd do differently, and what FORGE should remember. Stores structured retro data that /evolve consumes."
argument-hint: "[optional: project name or session context]"
allowed-tools: Read Grep Glob Bash Write
---

# /retro — Post-Ship Retrospective

You run after `/ship` completes a cycle. You collect structured feedback that `/evolve` uses to improve FORGE skills.

## Step 1: Gather Context

Understand what just happened:

```bash
# Recent commits (the work that was just shipped)
git log --oneline -20

# Check for architecture doc
ls -t .forge/architecture/*.md 2>/dev/null | head -1

# Check for verify report
cat .forge/verify/report.md 2>/dev/null | head -5
```

Also read `$ARGUMENTS` for any context the user provided.

Detect the project name:
```bash
basename "$(pwd)"
```

## Step 2: Ask Three Questions

Present each question and wait for the user's response. Do not rush — give them space to reflect.

### Question 1: What slowed us down?

```
FORGE /retro — Question 1 of 3

What slowed us down?

Think about: bottlenecks, unclear requirements, wrong assumptions,
tools that didn't work, phases that felt wasteful.

(Type your answer, or "skip" to move on)
```

### Question 2: What would we do differently?

```
FORGE /retro — Question 2 of 3

What would we do differently next time?

Think about: architecture decisions you'd change, phases you'd skip
or add, tools you'd switch, approaches that didn't work.

(Type your answer, or "skip" to move on)
```

### Question 3: What should FORGE remember?

```
FORGE /retro — Question 3 of 3

What should FORGE remember from this session?

Think about: decisions worth carrying forward, anti-patterns discovered,
workflow preferences that worked well, things to never repeat.

(Type your answer, or "skip" to move on)
```

## Step 3: Score FORGE Skills

Based on the session context and user answers, rate each FORGE skill that was used in this cycle:

```
FORGE /retro — Skill ratings

Rate each skill used in this cycle (1-5, or skip):

  /think     — Did it classify correctly?        [1-5 or skip]
  /architect — Was the architecture doc useful?   [1-5 or skip]
  /build     — Did TDD flow work smoothly?       [1-5 or skip]
  /verify    — Did verification catch real issues? [1-5 or skip]
  /ship      — Did security audit + PR work well? [1-5 or skip]

(Enter as: "think:4 architect:5 build:3 verify:skip ship:4")
```

Parse the ratings. For any skill rated 1-2, ask a follow-up:
```
/[skill] rated [score] — What went wrong specifically?
```

## Step 4: Build Retro Document

Compile everything into a structured JSON document:

```json
{
  "date": "YYYY-MM-DD",
  "project": "[project name]",
  "session_summary": "[1-2 sentence summary of what was built]",
  "questions": {
    "what_slowed_us": "[user's answer or null if skipped]",
    "what_differently": "[user's answer or null if skipped]",
    "what_to_remember": "[user's answer or null if skipped]"
  },
  "skill_ratings": {
    "think": { "score": 4, "feedback": null },
    "architect": { "score": 5, "feedback": null },
    "build": { "score": 2, "feedback": "TDD loop was too strict for config changes" },
    "verify": null,
    "ship": { "score": 4, "feedback": null }
  },
  "decisions_to_remember": [
    "[extracted from question 3 — things worth storing in memory]"
  ],
  "improvements_suggested": [
    "[extracted from questions 1-2 — concrete improvement ideas for skills]"
  ]
}
```

## Step 5: Save Retro

```bash
# Ensure retros directory exists
mkdir -p ~/.forge/retros
```

Save to `~/.forge/retros/[YYYY-MM-DD]_[project].json`:

```bash
# If multiple retros on the same day for the same project, append a counter
DATE=$(date +%Y-%m-%d)
PROJECT="[project name]"
BASE="$HOME/.forge/retros/${DATE}_${PROJECT}"
TARGET="${BASE}.json"
COUNTER=1
while [ -f "$TARGET" ]; do
  TARGET="${BASE}_${COUNTER}.json"
  COUNTER=$((COUNTER + 1))
done
```

Write the JSON document to `$TARGET`.

## Step 6: Store Memories

If the user provided answers to Question 3 ("what should FORGE remember"), invoke `/memory-remember` with those decisions. This ensures retro insights feed directly into the memory bank.

## Step 7: Summary

```
FORGE /retro — Complete

Retro saved: ~/.forge/retros/[filename].json
Skills rated: [count]
Decisions stored: [count] (via /memory-remember)
Improvements noted: [count] (available for /evolve)

Low-rated skills:
  /[skill] — [score]: [feedback summary]

Run /evolve to apply improvements based on this and past retros.
```

## Rules

- Never skip the three questions — but accept "skip" as a valid answer
- Never fabricate user answers — only record what they actually said
- Skill ratings are optional — the user can skip any or all
- Always save the retro file even if all questions are skipped (the skill ratings alone are valuable)
- Invoke `/memory-remember` for Question 3 answers — don't just note them
- The retro JSON must be valid, parseable JSON — `/evolve` depends on it
- Do not suggest changes to skills during retro — that's `/evolve`'s job
