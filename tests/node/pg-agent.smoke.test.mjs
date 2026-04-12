import test from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const binPath = resolve(rootDir, "bin/pg-agent.mjs");

test(
  "optional smoke test against PG_TEST_URL",
  { skip: !process.env.PG_TEST_URL },
  async () => {
    const result = await runCli(
      [
        "query",
        "--sql",
        "select current_database() as database_name",
      ],
      { PG_URL: process.env.PG_TEST_URL },
    );

    assert.equal(result.code, 0, result.stderr);
    assert.equal(result.stdoutJson.truncated, false);
    assert.ok(Array.isArray(result.stdoutJson.rows));
  },
);

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
      });
    });
  });
}
