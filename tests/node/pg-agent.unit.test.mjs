import test from "node:test";
import assert from "node:assert/strict";

import {
  DEFAULTS,
  EXIT_CODES,
  PgAgentError,
  analyzeSql,
  executeReadOnlyQuery,
  formatQueryResult,
  parseCliArgs,
  resolveConnectionConfig,
  validateReadOnlySql,
} from "../../scripts/lib/pg-agent.mjs";

test("resolveConnectionConfig prefers --url over PG_URL", () => {
  const config = resolveConnectionConfig(
    { url: "postgresql://from-option/db" },
    { PG_URL: "postgresql://from-env/db" },
  );

  assert.equal(config.connectionString, "postgresql://from-option/db");
  assert.equal(config.application_name, DEFAULTS.applicationName);
});

test("resolveConnectionConfig falls back to standard PG environment variables", () => {
  const config = resolveConnectionConfig({}, { PGHOST: "127.0.0.1", PGUSER: "forge" });

  assert.deepEqual(config, { application_name: DEFAULTS.applicationName });
});

test("resolveConnectionConfig rejects missing connection details", () => {
  assert.throws(
    () => resolveConnectionConfig({}, {}),
    (error) =>
      error instanceof PgAgentError &&
      error.exitCode === EXIT_CODES.INVALID_USAGE &&
      error.errorCode === "INVALID_CONNECTION_CONFIG",
  );
});

test("parseCliArgs applies defaults for inspect", () => {
  const parsed = parseCliArgs(["inspect"], { PG_URL: "postgresql://db/app" });

  assert.equal(parsed.command, "inspect");
  assert.equal(parsed.options.schema, DEFAULTS.schema);
  assert.equal(parsed.connectionConfig.connectionString, "postgresql://db/app");
});

test("parseCliArgs validates query options", () => {
  const parsed = parseCliArgs(
    [
      "query",
      "--sql",
      "select 1",
      "--max-rows",
      "25",
      "--statement-timeout",
      "4000",
      "--lock-timeout",
      "250",
      "--idle-timeout",
      "4500",
    ],
    { PG_URL: "postgresql://db/app" },
  );

  assert.equal(parsed.options.maxRows, 25);
  assert.equal(parsed.options.statementTimeoutMs, 4000);
  assert.equal(parsed.options.lockTimeoutMs, 250);
  assert.equal(parsed.options.idleInTransactionSessionTimeoutMs, 4500);
});

test("parseCliArgs rejects missing required command options", () => {
  assert.throws(
    () => parseCliArgs(["describe"], { PG_URL: "postgresql://db/app" }),
    (error) =>
      error instanceof PgAgentError &&
      error.exitCode === EXIT_CODES.INVALID_USAGE &&
      error.errorCode === "MISSING_TABLE",
  );

  assert.throws(
    () => parseCliArgs(["query"], { PG_URL: "postgresql://db/app" }),
    (error) =>
      error instanceof PgAgentError &&
      error.exitCode === EXIT_CODES.INVALID_USAGE &&
      error.errorCode === "MISSING_SQL",
  );
});

test("analyzeSql ignores semicolons in strings, comments, and dollar quotes", () => {
  const analysis = analyzeSql(`
    -- leading comment;
    SELECT ';' AS literal,
           $$value;still-inside$$ AS dollar_text
    /* block ; comment */
  `);

  assert.equal(analysis.statementCount, 1);
  assert.equal(analysis.tokens[0], "SELECT");
});

test("validateReadOnlySql allows supported read-only statements", () => {
  for (const sql of [
    "select * from users",
    "with recent as (select 1) select * from recent",
    "show statement_timeout",
    "explain analyze select 1",
  ]) {
    assert.equal(validateReadOnlySql(sql).ok, true, sql);
  }
});

test("validateReadOnlySql rejects unsupported or multiple statements", () => {
  const unsupported = validateReadOnlySql("delete from users");
  assert.equal(unsupported.ok, false);
  assert.equal(unsupported.errorCode, "UNSUPPORTED_SQL");

  const multi = validateReadOnlySql("select 1; select 2");
  assert.equal(multi.ok, false);
  assert.equal(multi.errorCode, "MULTI_STATEMENT_SQL");
});

test("formatQueryResult truncates rows and preserves rowCount", () => {
  const result = formatQueryResult(
    {
      fields: [{ name: "id", dataTypeID: 23 }],
      rows: [{ id: 1 }, { id: 2 }, { id: 3 }],
      rowCount: 3,
    },
    2,
    42,
  );

  assert.deepEqual(result.fields, [{ name: "id", dataTypeId: 23 }]);
  assert.deepEqual(result.rows, [{ id: 1 }, { id: 2 }]);
  assert.equal(result.rowCount, 3);
  assert.equal(result.truncated, true);
  assert.equal(result.elapsedMs, 42);
});

test("executeReadOnlyQuery applies guardrail settings and rolls back", async () => {
  const calls = [];
  const client = {
    async query(sql, params) {
      calls.push({ sql, params });

      if (sql === "SELECT set_config($1, $2, true)") {
        return { rows: [], fields: [], rowCount: 1 };
      }

      if (sql === "SELECT 1 AS id") {
        return {
          fields: [{ name: "id", dataTypeID: 23 }],
          rows: [{ id: 1 }],
          rowCount: 1,
        };
      }

      return { rows: [], fields: [], rowCount: 0 };
    },
  };

  const result = await executeReadOnlyQuery(client, "SELECT 1 AS id", {
    statementTimeoutMs: 4500,
    lockTimeoutMs: 900,
    idleInTransactionSessionTimeoutMs: 6000,
    maxRows: 5,
  });

  assert.equal(result.rowCount, 1);
  assert.deepEqual(
    calls.map((entry) => entry.sql),
    [
      "BEGIN TRANSACTION READ ONLY",
      "SELECT set_config($1, $2, true)",
      "SELECT set_config($1, $2, true)",
      "SELECT set_config($1, $2, true)",
      "SELECT 1 AS id",
      "ROLLBACK",
    ],
  );
  assert.deepEqual(calls[1].params, ["statement_timeout", "4500"]);
  assert.deepEqual(calls[2].params, ["lock_timeout", "900"]);
  assert.deepEqual(calls[3].params, [
    "idle_in_transaction_session_timeout",
    "6000",
  ]);
});
