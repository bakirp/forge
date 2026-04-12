# PostgreSQL Agent Adapter

Use `bin/pg-agent.mjs` when an agent needs read-only PostgreSQL access without MCP.
The CLI is a self-contained bundle with no `npm install` required.

## Rebuild (dev only)

```bash
bun build bin/pg-agent.mjs --outfile bin/pg-agent.mjs --target node --format esm --external pg-native
```

## Commands

```bash
node bin/pg-agent.mjs inspect --schema public
node bin/pg-agent.mjs describe --schema public --table users
node bin/pg-agent.mjs query --sql "select id, email from public.users order by id limit 20"
```

Connection precedence:

1. `--url`
2. `PG_URL`
3. Standard `PG*` environment variables supported by `pg`

Prefer environment variables over putting credentials directly in shell history:

```bash
export PG_URL='postgresql://readonly_user:...@db.example.com/app'
node bin/pg-agent.mjs inspect --schema analytics
```

## Agent Snippet

Use this instruction in Claude Code, Codex, or similar coding agents:

```text
For PostgreSQL access, use `node ./bin/pg-agent.mjs` instead of MCP.
Inspect schema before writing queries.
Prefer bounded SELECTs with LIMIT unless you are aggregating.
Do not request or run INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, TRUNCATE, GRANT, or REVOKE.
Pass credentials via PG_URL or PG* environment variables, not inline in the prompt.
```

## Parent-Agent Invocation

If you want to use this through a prompt-defined agent instead of MCP, use the reusable agent definition at `agents/postgres-agent.md`.

Parent agent responsibilities:

- keep database credentials in `PG_URL` or standard `PG*` environment variables
- pass only the analysis task in the prompt
- let the Postgres agent inspect schema before it queries

Typical orchestration prompt:

```text
Spawn `postgres-agent` with the task:
"Inspect the public schema, describe the users and orders tables, then find the top 10 most recent paid orders. Return the SQL you used and summarize the result."
```

## Safety Model

- Only `SELECT`, `WITH`, `SHOW`, and `EXPLAIN` are accepted.
- Queries run inside a read-only transaction.
- The adapter sets local `statement_timeout`, `lock_timeout`, and `idle_in_transaction_session_timeout`.
- Result rows are truncated to `1000` by default.
- Real safety should still come from a dedicated read-only database role with least-privilege grants.
