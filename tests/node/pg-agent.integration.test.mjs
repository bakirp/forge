import test from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { PGlite } from "@electric-sql/pglite";
import { PGLiteSocketServer } from "@electric-sql/pglite-socket";

const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const binPath = resolve(rootDir, "bin/pg-agent.mjs");

let db;
let server;
let databaseUrl;

test.before(async () => {
  db = await PGlite.create("memory://");
  await db.exec(`
    CREATE TABLE public.users (
      id integer PRIMARY KEY,
      email text NOT NULL
    );
    INSERT INTO public.users (id, email)
    VALUES (1, 'ada@example.com'), (2, 'linus@example.com');

    CREATE SCHEMA analytics;
    CREATE TABLE analytics.events (
      id integer PRIMARY KEY,
      kind text NOT NULL
    );
  `);

  server = new PGLiteSocketServer({
    db,
    host: "127.0.0.1",
    port: 0,
    maxConnections: 4,
  });
  await server.start();
  databaseUrl = `postgresql://postgres@${server.getServerConn()}/postgres?sslmode=disable`;
});

test.after(async () => {
  await server?.stop();
  await db?.close();
});

test("inspect lists tables for the requested schema", async () => {
  const result = await runCli(["inspect", "--schema", "analytics", "--url", databaseUrl]);

  assert.equal(result.code, 0, result.stderr);
  assert.deepEqual(result.stdoutJson, {
    schema: "analytics",
    tables: [{ name: "events" }],
  });
});

test("describe returns column metadata", async () => {
  const result = await runCli(
    ["describe", "--table", "users", "--url", databaseUrl],
  );

  assert.equal(result.code, 0, result.stderr);
  assert.equal(result.stdoutJson.schema, "public");
  assert.equal(result.stdoutJson.table, "users");
  assert.deepEqual(result.stdoutJson.columns, [
    {
      name: "id",
      dataType: "integer",
      isNullable: false,
      defaultValue: null,
      ordinalPosition: 1,
    },
    {
      name: "email",
      dataType: "text",
      isNullable: false,
      defaultValue: null,
      ordinalPosition: 2,
    },
  ]);
});

test("query returns JSON rows and truncation metadata", async () => {
  const result = await runCli(
    [
      "query",
      "--sql",
      "select id, email from public.users order by id",
      "--max-rows",
      "1",
    ],
    { PG_URL: databaseUrl },
  );

  assert.equal(result.code, 0, result.stderr);
  assert.deepEqual(result.stdoutJson.fields, [
    { name: "id", dataTypeId: 23 },
    { name: "email", dataTypeId: 25 },
  ]);
  assert.equal(result.stdoutJson.rowCount, 2);
  assert.equal(result.stdoutJson.truncated, true);
  assert.equal(result.stdoutJson.rows.length, 1);
  assert.match(String(result.stdoutJson.elapsedMs), /^\d+$/);
});

test("query rejects unsupported write statements before execution", async () => {
  const result = await runCli(
    ["query", "--sql", "delete from public.users", "--url", databaseUrl],
  );

  assert.equal(result.code, 4);
  assert.equal(result.stderrJson.error.code, "UNSUPPORTED_SQL");
});

test("query rejects multiple statements", async () => {
  const result = await runCli(
    ["query", "--sql", "select 1; select 2", "--url", databaseUrl],
  );

  assert.equal(result.code, 4);
  assert.equal(result.stderrJson.error.code, "MULTI_STATEMENT_SQL");
});

async function runCli(args, extraEnv = {}) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(process.execPath, [binPath, ...args], {
      cwd: rootDir,
      env: {
        ...process.env,
        ...extraEnv,
      },
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");

    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });

    child.on("error", reject);
    child.on("close", (code) => {
      resolvePromise({
        code: code ?? 0,
        stdout,
        stderr,
        stdoutJson: stdout.trim() ? JSON.parse(stdout) : null,
        stderrJson: stderr.trim() ? JSON.parse(stderr) : null,
      });
    });
  });
}
