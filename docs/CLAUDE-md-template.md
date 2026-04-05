# CLAUDE.md Template

Copy this template to the root of any project where you use FORGE. Customize the sections for your project's conventions.

---

```markdown
# [Project Name]

[One-sentence description of the project]

## Stack

- Language: [e.g., TypeScript, Python, Go]
- Framework: [e.g., Next.js, FastAPI, Gin]
- Database: [e.g., PostgreSQL, SQLite, none]
- Testing: [e.g., Vitest, pytest, go test]
- Package manager: [e.g., npm, bun, pip, go modules]

## Commands

```
# Install dependencies
[command]

# Run dev server
[command]

# Run tests
[command]

# Run linter
[command]
```

## Project Structure

```
src/
  [describe key directories and their purpose]
tests/
  [describe test organization]
```

## Conventions

- [Naming conventions — e.g., camelCase for functions, PascalCase for types]
- [File organization — e.g., one component per file, colocate tests]
- [Error handling — e.g., return errors don't throw, use Result types]
- [API patterns — e.g., RESTful routes, GraphQL schema-first]

## FORGE Overrides

Use this section to customize FORGE behavior for this project:

- [e.g., /verify should use "api" mode — this is a pure API project]
- [e.g., /build should use pytest, not the auto-detected test runner]
- [e.g., /ship should create draft PRs by default]
- [e.g., Skip /architect for tasks in the /scripts directory — they're always tiny]
```

---

## Notes

- FORGE reads `CLAUDE.md` at session start and respects project conventions
- FORGE augments your project rules — it never overrides them
- The "FORGE Overrides" section is optional — only add it if you need to customize behavior
- Keep this file concise — Claude reads it every session, so every line costs context tokens
