  
**FORGE**

The Claude Code Skill Framework That Rewrites Itself

Execution Plan  ·  v1.0  ·  April 2026

*gstack ships Garry Tan's brain.  Superpowers ships Jesse Vincent's methodology.*

***FORGE ships yours — and keeps shipping a better version of it every sprint.***

# **Executive Summary**

FORGE is a Claude Code skill framework with three capabilities no existing tool has: architectural decision memory that survives across projects, adaptive phase depth that eliminates unnecessary ceremony on simple tasks, and self-evolving skills that rewrite themselves based on your own usage patterns.

This plan covers four sprints across 12 weeks. The result is a production-ready, MIT-licensed Claude Code plugin with a GitHub repo, a working /evolve skill, and an active early-adopter community.

| 4 Sprints Foundation → Ship | 12 Weeks Total timeline | 7 Skills /think /architect /build/verify /ship /memory /evolve | MIT License Free forever |
| :---: | :---: | :---: | :---: |

# **What FORGE Is**

## **Relationship to Claude Code native features**

Claude Code shipped Agent Teams (Feb 2026), Auto-Memory, Session Sharing, and built-in subagents with worktrees. FORGE does not compete with these — it orchestrates them.

* Claude Code provides the engine.  FORGE provides the process.

* Agent Teams \= generic parallel execution.  FORGE gives each agent a role, checklist, and exit gate.

* Auto-Memory \= shallow preference recall.  FORGE memory \= architectural decisions and anti-patterns across projects.

* /evolve \= no equivalent anywhere.  Skills rewrite themselves from your retro data.

## **The 7 core skills**

| Command | What it does | Key mechanic | Phase | Sprint |
| :---- | :---- | :---- | :---- | :---- |
| **/think** | Adaptive entry point | Reads task complexity, routes to right depth, spawns Agent Teams with roles | Planning | Sprint 1 |
| **/architect** | Lock architecture before build | Checks memory bank first, locks data flow \+ API contracts \+ test strategy | Planning | Sprint 1 |
| **/build** | TDD-enforced subagent execution | Tests must fail first. 2-stage review per task. Smart model routing. | Build | Sprint 2 |
| **/verify** | Cross-platform browser QA | Playwright, domain-aware: web / API / data pipeline modes | QA | Sprint 2 |
| **/ship** | Security audit \+ PR \+ deploy | OWASP \+ STRIDE scan, auto-fix critical issues, canary option | Ship | Sprint 2 |
| **/memory** | Cross-project decision memory | /remember /recall /forget — JSONL bank, injected at session start | All | Sprint 3 |
| **/evolve** | Self-rewriting skills | Meta-agent reviews retros, proposes skill rewrites, applies low-risk changes | Retro | Sprint 4 |

# **Sprint 1 — Foundation  (Weeks 1–3)**

Goal: Repo structure, CLAUDE.md, root SKILL.md, /think, and /architect are working end-to-end. Someone can clone and run a real session.

| Sprint 1  ·  🏗  Foundation    Weeks 1–3    MVP |  |  |  |
| :---- | :---- | :---- | :---- |
| **Step** | **Task** | **Deliverable** | **Owner** |
| **1.1** | Create GitHub repo — forge — with MIT license, README (from our session), .gitignore, and folder structure: /skills, /bin, /docs | Public GitHub repo | You |
| **1.2** | Write root SKILL.md — the bootstrap file Claude reads at session start. Must: state FORGE philosophy, list all skills, inject memory bank summary, set proactive mode. | SKILL.md v1 | You \+ Claude |
| **1.3** | Write CLAUDE.md template — the project config file. Includes gstack/Superpowers conflict resolution: use FORGE /verify not mcp\_\_claude-in-chrome\_\_\*, never use Superpowers browser. | CLAUDE.md template | You \+ Claude |
| **1.4** | Build /think skill. Logic: (a) read task description, (b) classify complexity \[tiny / feature / epic\], (c) route: tiny → /build direct, feature → /architect first, epic → Agent Teams spawn with roles. | skills/think/SKILL.md | You \+ Claude |
| **1.5** | Build /architect skill. Must: query memory bank before planning, produce locked architecture doc (data flow, API contracts, edge cases, test strategy), feed output path to /build. | skills/architect/SKILL.md | You \+ Claude |
| **1.6** | Build setup script. Install: git clone → ./setup. Must check for Bun v1.0+, create \~/.forge/sessions dir, symlink skills to Claude Code, write initial CLAUDE.md if missing. | setup (bash) | You |
| **1.7** | Test end-to-end: clone fresh, run setup, open Claude Code, start a real session with /think on a small real task. Fix anything that breaks. | Working v0.1.0 session | You |
| **1.8** | Write ARCHITECTURE.md explaining why each design decision was made — esp. why no binary for v1, why JSONL for memory, why Playwright over MCP tools for browser. | ARCHITECTURE.md | You |

### **Sprint 1 — Definition of Done**

* \`git clone && ./setup\` works in under 60 seconds on macOS and Linux

* \`/think\` correctly classifies tiny / feature / epic and routes without manual input

* \`/architect\` produces a locked architecture doc that /build can consume directly

* Root SKILL.md injects correctly at session start — confirmed in Claude Code

* Repo is public, README renders correctly on GitHub

# **Sprint 2 — Build Loop  (Weeks 4–6)**

Goal: /build, /verify, and /ship are working. A full think → architect → build → verify → ship cycle completes on a real project without manual intervention between phases.

| Sprint 2  ·  ⚙️  Build Loop    Weeks 4–6    Core loop |  |  |  |
| :---- | :---- | :---- | :---- |
| **Step** | **Task** | **Deliverable** | **Owner** |
| **2.1** | Build /build skill. Requirements: (a) reads /architect output doc, (b) enforces TDD — tests must fail before implementation, (c) runs subagents in isolated git worktrees via Agent Teams, (d) 2-stage review per task: spec compliance then code quality, (e) smart model routing: Haiku for simple tasks, Sonnet/Opus for complex. | skills/build/SKILL.md | You \+ Claude |
| **2.2** | Build /verify skill. Requirements: (a) Playwright-based browser testing — no macOS lock-in, (b) domain detection: web app → real browser flows, API → contract validation, data pipeline → output diff, (c) annotated screenshots on every failure, (d) produces pass/fail report that /ship reads. | skills/verify/SKILL.md | You \+ Claude |
| **2.3** | Build /ship skill. Requirements: (a) reads /verify report — blocks if failures, (b) runs OWASP Top 10 \+ STRIDE threat model check, (c) auto-fixes critical security issues before PR, (d) creates PR with human-readable release summary from git log, (e) canary deploy flag. | skills/ship/SKILL.md | You \+ Claude |
| **2.4** | Integrate Agent Teams into /think routing for "epic" complexity. When epic detected: spawn CEO agent (product scope), Eng agent (architecture), Security agent (threat model). Each agent gets its own FORGE checklist, not just a generic prompt. | Updated /think with Agent Teams | You \+ Claude |
| **2.5** | Write token budget warning into /build. Before spawning subagents, estimate token cost (tasks × avg tokens per task). If projected \> 40k tokens, show estimate and ask confirmation. Suggest Haiku routing for tasks below complexity threshold. | Token warning in /build | You |
| **2.6** | End-to-end test on a real project. Use FORGE itself to build a new feature for FORGE. Run the full think → architect → build → verify → ship cycle. Record what breaks. | Test report \+ bug list | You |
| **2.7** | Fix all bugs from 2.6. Tag v0.2.0. Write CHANGELOG entry for Sprint 2\. | v0.2.0 tagged | You |

### **Sprint 2 — Definition of Done**

* Full cycle (think → architect → build → verify → ship) runs on a real project without manual phase switching

* TDD enforced: Claude cannot proceed to implementation if no failing test exists

* /verify works on Linux and Windows, not just macOS

* Token budget warning appears before any run projected to exceed 40k tokens

* /ship blocks on /verify failure — no exceptions

# **Sprint 3 — Memory  (Weeks 7–9)**

Goal: /memory is working. Decisions made in a session persist across projects. At session start, relevant memories are injected automatically. The knowledge base compounds.

| Sprint 3  ·  🧠  Memory    Weeks 7–9    Most original |  |  |  |
| :---- | :---- | :---- | :---- |
| **Step** | **Task** | **Deliverable** | **Owner** |
| **3.1** | Design the memory data model. Each entry: { id, project, date, category, decision, rationale, anti\_patterns, tags, confidence }. Categories: architecture, stack-choice, security, workflow, anti-pattern. Store as JSONL at \~/.forge/memory.jsonl. | Memory schema doc | You \+ Claude |
| **3.2** | Build /remember skill. Triggered at end of /architect and /retro. Extracts decisions from session context. Formats into memory schema. Appends to memory.jsonl. Deduplicates by semantic similarity (keyword matching for v1, vector embed for v2). | skills/memory/remember/SKILL.md | You \+ Claude |
| **3.3** | Build /recall skill. Triggered at start of /architect (automatic) and on-demand. Reads memory.jsonl, filters by tags \+ project relevance, injects top 5 most relevant entries into context. Formats as "Past decision: \[decision\] — Rationale: \[rationale\]". | skills/memory/recall/SKILL.md | You \+ Claude |
| **3.4** | Build /forget skill. On-demand. Lists memory entries matching a search term. User selects entries to delete. Confirms before deletion. Also: auto-prune entries older than 6 months with confidence \< 0.5 (marked stale by /evolve). | skills/memory/forget/SKILL.md | You \+ Claude |
| **3.5** | Inject memory summary into root SKILL.md session start. At session open: read memory.jsonl, summarize last 3 relevant decisions for current project context, inject as "FORGE remembers:" block. Max 300 tokens to keep context lean. | Session-start memory injection | You |
| **3.6** | Test memory across 3 different projects. Verify: (a) decisions from project A surface correctly in project B when relevant, (b) unrelated memories do not pollute context, (c) /forget correctly prunes without side effects. | Cross-project memory test report | You |
| **3.7** | Write docs/memory-guide.md — explains what gets remembered, how to review your memory bank, when to use /forget, and how to export your memory to share with teammates. | docs/memory-guide.md | You |

### **Sprint 3 — Definition of Done**

* Decision made in project A surfaces automatically in project B when architecturally relevant

* /recall injects in under 2 seconds with no visible latency to user

* Memory injection at session start stays under 300 tokens

* /forget works without corrupting memory.jsonl

* Zero false positives in cross-project memory test (irrelevant memories not surfaced)

# **Sprint 4 — Evolve \+ Launch  (Weeks 10–12)**

Goal: /evolve is working, FORGE v1.0.0 is tagged, repo is public, first 100 GitHub stars, and early adopter feedback is incorporated.

| Sprint 4  ·  🚀  Evolve \+ Launch    Weeks 10–12    Most original |  |  |  |
| :---- | :---- | :---- | :---- |
| **Step** | **Task** | **Deliverable** | **Owner** |
| **4.1** | Build /evolve skill — the meta-agent. After each completed project cycle: (a) reads /retro output \+ session logs, (b) scores each skill: did it help? did it slow things down? (c) proposes targeted rewrites as diffs, (d) auto-applies changes rated "low-risk" (formatting, wording), (e) flags "high-risk" changes for human review. | skills/evolve/SKILL.md | You \+ Claude |
| **4.2** | Build /retro skill — feeds /evolve. After /ship: asks 3 questions: What slowed us down? What would we do differently? What should FORGE remember? Stores structured retro in \~/.forge/retros/\[date\].json. | skills/retro/SKILL.md | You \+ Claude |
| **4.3** | Run /evolve on FORGE itself after Sprint 3\. Let it review the first 3 sprints and propose skill improvements. Apply low-risk changes. Document what it changed and why — this becomes the launch story. | First self-evolution log | You |
| **4.4** | Write comprehensive docs: getting-started.md, skills-reference.md, memory-guide.md, evolve-guide.md, contributing.md, CLAUDE-md-template.md. Add GitHub Actions for CI (lint skills, validate SKILL.md schema). | Full docs suite \+ CI | You |
| **4.5** | Tag v1.0.0. Submit to Anthropic Claude Code plugin marketplace. Write launch post: "I built a Claude Code framework that rewrites its own skills after every sprint" — include the first self-evolution log as evidence. | v1.0.0 \+ marketplace submission | You |
| **4.6** | Launch on Hacker News (Show HN), X/Twitter thread, and Claude Code community Discord. Target: 200+ GitHub stars in first week. Respond to every issue and PR in first 48 hours. | Public launch | You |
| **4.7** | Collect feedback for 2 weeks. Build issues list for v1.1. Priority: cross-platform bugs, /evolve false positives, memory recall accuracy. Ship v1.1 patch within 14 days of launch. | v1.1 patch \+ community | You |

### **Sprint 4 — Definition of Done**

* /evolve successfully rewrites at least one skill after Sprint 3 retro — and the rewrite is measurably better

* v1.0.0 is tagged, public, and submitted to Anthropic marketplace

* 100+ GitHub stars within 7 days of launch

* All 7 skills documented with examples in docs/

* GitHub Actions CI passes on every push

# **Technical Architecture**

## **Repository structure**

forge/├── SKILL.md              ← root bootstrap (Claude reads this first)├── CLAUDE.md             ← project config template├── ARCHITECTURE.md       ← design decisions├── setup                 ← bash install script├── skills/│   ├── think/SKILL.md│   ├── architect/SKILL.md│   ├── build/SKILL.md│   ├── verify/SKILL.md│   ├── ship/SKILL.md│   ├── memory/│   │   ├── SKILL.md      ← memory hub│   │   ├── remember/SKILL.md│   │   ├── recall/SKILL.md│   │   └── forget/SKILL.md│   ├── retro/SKILL.md│   └── evolve/SKILL.md   ← meta-skill├── docs/│   ├── getting-started.md│   ├── skills-reference.md│   ├── memory-guide.md│   └── evolve-guide.md└── .github/    └── workflows/ci.yml  ← lint \+ validate skills

## **Technology decisions**

* **No binary:** Pure Markdown skills — no binary for v1. Portable to Cursor/Codex/Gemini CLI later (like Superpowers).

* **Memory storage:** JSONL at \~/.forge/memory.jsonl — human-readable, grep-able, git-trackable if user wants.

* **Browser testing:** Playwright via npx — no daemon, no macOS lock-in. Cold start accepted for v1; optimize in v2.

* **Parallelism:** Claude Code Agent Teams for /think epic routing — leverage platform, don't rebuild it.

* **CI:** GitHub Actions for CI — validate SKILL.md has required fields: name, description, triggers, steps.

# **Risks & Mitigations**

| Risk | Impact | Mitigation |
| :---- | :---- | :---- |
| Anthropic ships /evolve-equivalent natively | **Medium** | FORGE's /evolve is personalised to your own retro data — platform memory will be generic. Differentiation survives. |
| Agent Teams exits experimental and breaks /think routing | **Medium** | Wrap Agent Teams calls in try/catch. Fallback to sequential subagents. Monitor Anthropic changelog weekly. |
| /evolve produces bad skill rewrites and breaks FORGE | **High** | Auto-apply only "low-risk" changes (wording, formatting). All structural changes require explicit human approval. Keep git history of all skill versions. |
| Memory bank grows too large and pollutes context | **Medium** | Hard cap: inject max 5 memories, max 300 tokens. Auto-prune entries older than 6 months with low confidence. /forget is always available. |
| gstack or Superpowers ships memory natively before Sprint 3 | **Low** | FORGE's cross-project architectural memory is a different category from gstack's /retro or Superpowers' skill logging. Monitor both repos weekly. |
| No adoption — nobody installs it | **High** | Launch with the self-evolution story, not a feature list. "FORGE rewrote its own skills after sprint 3" is a headline. Ship v0.1 early to 5 trusted users for feedback before v1.0 launch. |
| Scope creep — trying to build everything at once | **High** | This plan is the scope. /think, /architect, /build, /verify, /ship, /memory, /evolve — nothing else in v1. Defer team coordination, vector search, and cross-platform binary to v2. |

# **What NOT to Build in v1**

Scope discipline is the difference between shipping and abandoning. These features are explicitly deferred to v2 or later.

* **✗  Defer:** Team coordination — Claude Code Session Sharing covers basic team use. Real team features (shared memory bank, conflict detection) are v2.

* **✗  Defer:** Vector embedding for memory recall — keyword \+ tag matching is enough for v1. Vector search is a dependency, a complexity, and a cost. Add in v2 if recall accuracy is a real complaint.

* **✗  Defer:** Persistent Chromium daemon (like gstack) — npx playwright is fine for v1. The 3-second cold start is acceptable. Optimize only if /verify speed becomes a real user complaint.

* **✗  Defer:** Windows binary — pure Markdown skills work on Windows already. A binary is v2 if there's demand.

* **✗  Defer:** Custom skill marketplace — let the community fork and PR first. A marketplace is infrastructure for a community that doesn't exist yet.

* **✗  Defer:** Cursor / Codex / Gemini CLI support — pure Markdown skills are portable in theory. Add host-specific adapters in v1.1 based on user requests.

# **First Week — Start Here**

Everything else in this plan is future-you's problem. This is what you do in the next 7 days.

**Day 1**

* Create the GitHub repo (name: forge). Add MIT license, the README we already wrote, and an empty /skills folder.

* Ask Claude: "Write the root SKILL.md for FORGE — the bootstrap file that Claude Code reads at session start."

**Day 2–3**

* Write the /think skill with Claude. Test it on 3 real tasks: one tiny, one feature, one epic. Does it route correctly?

* Write the CLAUDE.md template. Test it in a real Claude Code session.

**Day 4–5**

* Write the /architect skill. Run it on a real feature you want to build. Does the output feed cleanly into a coding session?

* Write the setup script. Test: clone → setup → open Claude Code → /think. Time it. Should be under 60 seconds.

**Day 6–7**

* Tag v0.1.0. Share the repo with 2–3 trusted developer friends. Ask them to clone and run /think on a real task. Watch silently.

* Write down every moment of friction. That list is your Sprint 2 backlog.

***The best Claude Code framework is the one that knows how you work.***

*Ship the first version. Let FORGE learn from you. Then ship a better one.*