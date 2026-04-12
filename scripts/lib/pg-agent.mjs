import { performance } from "node:perf_hooks";

import pg from "pg";

const { Client } = pg;

export const EXIT_CODES = Object.freeze({
  OK: 0,
  INVALID_USAGE: 2,
  CONNECTION_FAILED: 3,
  UNSAFE_SQL: 4,
  QUERY_FAILED: 5,
});

export const DEFAULTS = Object.freeze({
  schema: "public",
  maxRows: 1000,
  statementTimeoutMs: 5000,
  lockTimeoutMs: 1000,
  idleInTransactionSessionTimeoutMs: 10000,
  applicationName: "forge-pg-agent",
});

const ALLOWED_TOP_LEVEL = new Set(["SELECT", "WITH", "SHOW", "EXPLAIN"]);
const IDENTIFIER_RE = /[A-Za-z_]/;
const IDENTIFIER_PART_RE = /[A-Za-z0-9_$]/;
const STANDARD_PG_ENV_KEYS = [
  "PGHOST",
  "PGHOSTADDR",
  "PGPORT",
  "PGUSER",
  "PGPASSWORD",
  "PGDATABASE",
  "PGSERVICE",
  "PGSERVICEFILE",
  "PGPASSFILE",
  "PGSSLMODE",
  "PGAPPNAME",
];

export class PgAgentError extends Error {
  constructor(message, exitCode, errorCode, details) {
    super(message);
    this.name = "PgAgentError";
    this.exitCode = exitCode;
    this.errorCode = errorCode;
    this.details = details;
  }
}

export function buildUsage() {
  return [
    "Usage:",
    "  node bin/pg-agent.mjs inspect [--schema <name>] [--url <postgres-url>]",
    "  node bin/pg-agent.mjs describe [--schema <name>] --table <name> [--url <postgres-url>]",
    "  node bin/pg-agent.mjs query --sql \"<statement>\" [--max-rows <n>] [--statement-timeout <ms>] [--lock-timeout <ms>] [--idle-timeout <ms>] [--url <postgres-url>]",
    "",
    "Connection precedence:",
    "  1. --url",
    "  2. PG_URL",
    "  3. Standard PG* environment variables supported by pg",
    "",
    "Success output is JSON on stdout. Errors are JSON on stderr.",
  ].join("\n");
}

export function hasStandardPgEnv(env = process.env) {
  return STANDARD_PG_ENV_KEYS.some((key) => {
    const value = env[key];
    return typeof value === "string" && value.length > 0;
  });
}

export function resolveConnectionConfig(options = {}, env = process.env) {
  const connectionString = options.url ?? env.PG_URL;
  if (!connectionString && !hasStandardPgEnv(env)) {
    throw new PgAgentError(
      "Provide --url, PG_URL, or standard PG* environment variables.",
      EXIT_CODES.INVALID_USAGE,
      "INVALID_CONNECTION_CONFIG",
    );
  }

  const config = {};

  if (connectionString) {
    config.connectionString = connectionString;
  }

  if (!env.PGAPPNAME) {
    config.application_name = DEFAULTS.applicationName;
  }

  return config;
}

export function parseCliArgs(argv, env = process.env) {
  const args = [...argv];

  if (args.length === 0 || args[0] === "--help" || args[0] === "-h") {
    return { help: true, text: buildUsage() };
  }

  const command = args.shift();
  if (!["inspect", "describe", "query"].includes(command)) {
    throw new PgAgentError(
      `Unknown command: ${command}`,
      EXIT_CODES.INVALID_USAGE,
      "UNKNOWN_COMMAND",
      { command },
    );
  }

  const options = {
    schema: DEFAULTS.schema,
    maxRows: DEFAULTS.maxRows,
    statementTimeoutMs: DEFAULTS.statementTimeoutMs,
    lockTimeoutMs: DEFAULTS.lockTimeoutMs,
    idleInTransactionSessionTimeoutMs:
      DEFAULTS.idleInTransactionSessionTimeoutMs,
  };

  while (args.length > 0) {
    const token = args.shift();

    if (token === "--help" || token === "-h") {
      return { help: true, text: buildUsage() };
    }

    if (!token.startsWith("--")) {
      throw new PgAgentError(
        `Unexpected argument: ${token}`,
        EXIT_CODES.INVALID_USAGE,
        "UNEXPECTED_ARGUMENT",
        { token },
      );
    }

    const key = token.slice(2);
    switch (key) {
      case "url":
        options.url = requireValue(args, token);
        break;
      case "schema":
        options.schema = requireValue(args, token);
        break;
      case "table":
        options.table = requireValue(args, token);
        break;
      case "sql":
        options.sql = requireValue(args, token);
        break;
      case "max-rows":
        options.maxRows = parsePositiveInteger(requireValue(args, token), token);
        break;
      case "statement-timeout":
        options.statementTimeoutMs = parsePositiveInteger(
          requireValue(args, token),
          token,
        );
        break;
      case "lock-timeout":
        options.lockTimeoutMs = parsePositiveInteger(
          requireValue(args, token),
          token,
        );
        break;
      case "idle-timeout":
        options.idleInTransactionSessionTimeoutMs = parsePositiveInteger(
          requireValue(args, token),
          token,
        );
        break;
      default:
        throw new PgAgentError(
          `Unknown option: ${token}`,
          EXIT_CODES.INVALID_USAGE,
          "UNKNOWN_OPTION",
          { option: token },
        );
    }
  }

  validateCommandOptions(command, options);

  return {
    command,
    options,
    connectionConfig: resolveConnectionConfig(options, env),
  };
}

export function validateCommandOptions(command, options) {
  if (command === "describe" && !options.table) {
    throw new PgAgentError(
      "describe requires --table <name>.",
      EXIT_CODES.INVALID_USAGE,
      "MISSING_TABLE",
    );
  }

  if (command === "query" && !options.sql) {
    throw new PgAgentError(
      "query requires --sql \"<statement>\".",
      EXIT_CODES.INVALID_USAGE,
      "MISSING_SQL",
    );
  }

  if (command !== "query") {
    for (const disallowed of [
      "sql",
      "maxRows",
      "statementTimeoutMs",
      "lockTimeoutMs",
      "idleInTransactionSessionTimeoutMs",
    ]) {
      if (
        disallowed in options &&
        options[disallowed] !== undefined &&
        options[disallowed] !== DEFAULTS[keyForDefault(disallowed)]
      ) {
        throw new PgAgentError(
          `${command} does not accept ${toFlagName(disallowed)}.`,
          EXIT_CODES.INVALID_USAGE,
          "INVALID_OPTION_FOR_COMMAND",
          { command, option: toFlagName(disallowed) },
        );
      }
    }
  }

  if (command !== "describe" && options.table) {
    throw new PgAgentError(
      `${command} does not accept --table.`,
      EXIT_CODES.INVALID_USAGE,
      "INVALID_OPTION_FOR_COMMAND",
      { command, option: "--table" },
    );
  }
}

function keyForDefault(optionKey) {
  if (optionKey === "statementTimeoutMs") {
    return "statementTimeoutMs";
  }
  if (optionKey === "lockTimeoutMs") {
    return "lockTimeoutMs";
  }
  if (optionKey === "idleInTransactionSessionTimeoutMs") {
    return "idleInTransactionSessionTimeoutMs";
  }
  if (optionKey === "maxRows") {
    return "maxRows";
  }
  return optionKey;
}

function toFlagName(optionKey) {
  switch (optionKey) {
    case "maxRows":
      return "--max-rows";
    case "statementTimeoutMs":
      return "--statement-timeout";
    case "lockTimeoutMs":
      return "--lock-timeout";
    case "idleInTransactionSessionTimeoutMs":
      return "--idle-timeout";
    default:
      return `--${optionKey}`;
  }
}

function requireValue(args, flag) {
  const value = args.shift();
  if (!value) {
    throw new PgAgentError(
      `${flag} requires a value.`,
      EXIT_CODES.INVALID_USAGE,
      "MISSING_OPTION_VALUE",
      { option: flag },
    );
  }
  return value;
}

function parsePositiveInteger(value, flag) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isSafeInteger(parsed) || parsed <= 0) {
    throw new PgAgentError(
      `${flag} expects a positive integer.`,
      EXIT_CODES.INVALID_USAGE,
      "INVALID_INTEGER",
      { option: flag, value },
    );
  }
  return parsed;
}

export function analyzeSql(sql) {
  const tokens = [];
  let statementCount = 0;
  let currentStatementHasContent = false;
  let state = "normal";
  let blockDepth = 0;
  let dollarTag = null;

  for (let i = 0; i < sql.length; i += 1) {
    const char = sql[i];
    const next = sql[i + 1];

    if (state === "single") {
      if (char === "'" && next === "'") {
        i += 1;
        continue;
      }
      if (char === "'") {
        state = "normal";
      }
      continue;
    }

    if (state === "double") {
      if (char === '"' && next === '"') {
        i += 1;
        continue;
      }
      if (char === '"') {
        state = "normal";
      }
      continue;
    }

    if (state === "line-comment") {
      if (char === "\n") {
        state = "normal";
      }
      continue;
    }

    if (state === "block-comment") {
      if (char === "/" && next === "*") {
        blockDepth += 1;
        i += 1;
        continue;
      }
      if (char === "*" && next === "/") {
        blockDepth -= 1;
        i += 1;
        if (blockDepth === 0) {
          state = "normal";
        }
      }
      continue;
    }

    if (state === "dollar-quote") {
      if (dollarTag && sql.startsWith(dollarTag, i)) {
        i += dollarTag.length - 1;
        state = "normal";
        dollarTag = null;
      }
      continue;
    }

    if (char === "'" && state === "normal") {
      currentStatementHasContent = true;
      state = "single";
      continue;
    }

    if (char === '"' && state === "normal") {
      currentStatementHasContent = true;
      state = "double";
      continue;
    }

    if (char === "-" && next === "-") {
      state = "line-comment";
      i += 1;
      continue;
    }

    if (char === "/" && next === "*") {
      state = "block-comment";
      blockDepth = 1;
      i += 1;
      continue;
    }

    if (char === "$") {
      const tag = readDollarTag(sql, i);
      if (tag) {
        currentStatementHasContent = true;
        state = "dollar-quote";
        dollarTag = tag;
        i += tag.length - 1;
        continue;
      }
    }

    if (char === ";") {
      if (currentStatementHasContent) {
        statementCount += 1;
        currentStatementHasContent = false;
      }
      continue;
    }

    if (IDENTIFIER_RE.test(char)) {
      let j = i + 1;
      while (j < sql.length && IDENTIFIER_PART_RE.test(sql[j])) {
        j += 1;
      }

      if (tokens.length < 16) {
        tokens.push(sql.slice(i, j).toUpperCase());
      }

      currentStatementHasContent = true;
      i = j - 1;
      continue;
    }

    if (!/\s/.test(char)) {
      currentStatementHasContent = true;
    }
  }

  if (currentStatementHasContent) {
    statementCount += 1;
  }

  return { statementCount, tokens };
}

function readDollarTag(sql, startIndex) {
  if (sql[startIndex] !== "$") {
    return null;
  }

  let i = startIndex + 1;
  while (i < sql.length && /[A-Za-z0-9_]/.test(sql[i])) {
    i += 1;
  }

  if (sql[i] !== "$") {
    return null;
  }

  return sql.slice(startIndex, i + 1);
}

export function validateReadOnlySql(sql) {
  if (typeof sql !== "string" || sql.trim().length === 0) {
    return {
      ok: false,
      errorCode: "EMPTY_SQL",
      message: "SQL must be a non-empty string.",
    };
  }

  const analysis = analyzeSql(sql);
  if (analysis.statementCount === 0) {
    return {
      ok: false,
      errorCode: "EMPTY_SQL",
      message: "SQL must include one statement.",
    };
  }

  if (analysis.statementCount > 1) {
    return {
      ok: false,
      errorCode: "MULTI_STATEMENT_SQL",
      message: "Only one SQL statement is allowed.",
      analysis,
    };
  }

  const firstToken = analysis.tokens[0];
  if (!ALLOWED_TOP_LEVEL.has(firstToken)) {
    return {
      ok: false,
      errorCode: "UNSUPPORTED_SQL",
      message: `Only SELECT, WITH, SHOW, and EXPLAIN statements are allowed. Received ${firstToken ?? "UNKNOWN"}.`,
      analysis,
    };
  }

  return { ok: true, analysis };
}

export async function inspectSchema(client, schema = DEFAULTS.schema) {
  const result = await client.query(
    `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = $1
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `,
    [schema],
  );

  return {
    schema,
    tables: result.rows.map((row) => ({ name: row.table_name })),
  };
}

export async function describeTable(
  client,
  schema = DEFAULTS.schema,
  table,
) {
  const result = await client.query(
    `
      SELECT
        column_name,
        CASE
          WHEN data_type = 'USER-DEFINED' THEN udt_schema || '.' || udt_name
          ELSE data_type
        END AS data_type,
        is_nullable = 'YES' AS is_nullable,
        column_default,
        ordinal_position
      FROM information_schema.columns
      WHERE table_schema = $1
        AND table_name = $2
      ORDER BY ordinal_position
    `,
    [schema, table],
  );

  return {
    schema,
    table,
    columns: result.rows.map((row) => ({
      name: row.column_name,
      dataType: row.data_type,
      isNullable: row.is_nullable,
      defaultValue: row.column_default,
      ordinalPosition: row.ordinal_position,
    })),
  };
}

export function formatQueryResult(result, maxRows, elapsedMs) {
  const rows = result.rows ?? [];
  const truncated = rows.length > maxRows;

  return {
    fields: (result.fields ?? []).map((field) => ({
      name: field.name,
      dataTypeId: field.dataTypeID,
    })),
    rows: truncated ? rows.slice(0, maxRows) : rows,
    rowCount: typeof result.rowCount === "number" ? result.rowCount : rows.length,
    truncated,
    elapsedMs,
  };
}

export async function executeReadOnlyQuery(client, sql, options = {}) {
  const validation = validateReadOnlySql(sql);
  if (!validation.ok) {
    throw new PgAgentError(
      validation.message,
      EXIT_CODES.UNSAFE_SQL,
      validation.errorCode,
      validation.analysis ? { analysis: validation.analysis } : undefined,
    );
  }

  const startedAt = performance.now();
  let beganTransaction = false;

  try {
    await client.query("BEGIN TRANSACTION READ ONLY");
    beganTransaction = true;

    await setLocalConfig(
      client,
      "statement_timeout",
      String(options.statementTimeoutMs ?? DEFAULTS.statementTimeoutMs),
    );
    await setLocalConfig(
      client,
      "lock_timeout",
      String(options.lockTimeoutMs ?? DEFAULTS.lockTimeoutMs),
    );
    await setLocalConfig(
      client,
      "idle_in_transaction_session_timeout",
      String(
        options.idleInTransactionSessionTimeoutMs ??
          DEFAULTS.idleInTransactionSessionTimeoutMs,
      ),
    );

    const result = await client.query(sql);
    const elapsedMs = Math.round(performance.now() - startedAt);
    return formatQueryResult(
      result,
      options.maxRows ?? DEFAULTS.maxRows,
      elapsedMs,
    );
  } finally {
    if (beganTransaction) {
      await client.query("ROLLBACK").catch(() => {});
    }
  }
}

async function setLocalConfig(client, key, value) {
  await client.query("SELECT set_config($1, $2, true)", [key, value]);
}

export async function connectClient(connectionConfig) {
  const client = new Client(connectionConfig);

  try {
    await client.connect();
    return client;
  } catch (error) {
    await client.end().catch(() => {});
    throw new PgAgentError(
      error.message,
      EXIT_CODES.CONNECTION_FAILED,
      "CONNECTION_FAILED",
      { cause: error.code ?? error.name },
    );
  }
}

export async function runCommand(parsed) {
  const client = await connectClient(parsed.connectionConfig);

  try {
    switch (parsed.command) {
      case "inspect":
        return await inspectSchema(client, parsed.options.schema);
      case "describe":
        return await describeTable(
          client,
          parsed.options.schema,
          parsed.options.table,
        );
      case "query":
        return await executeReadOnlyQuery(
          client,
          parsed.options.sql,
          parsed.options,
        );
      default:
        throw new PgAgentError(
          `Unsupported command: ${parsed.command}`,
          EXIT_CODES.INVALID_USAGE,
          "UNKNOWN_COMMAND",
        );
    }
  } catch (error) {
    if (error instanceof PgAgentError) {
      throw error;
    }

    throw new PgAgentError(
      error.message,
      EXIT_CODES.QUERY_FAILED,
      "QUERY_FAILED",
      { cause: error.code ?? error.name },
    );
  } finally {
    await client.end().catch(() => {});
  }
}

export function normalizeError(error) {
  if (error instanceof PgAgentError) {
    return {
      exitCode: error.exitCode,
      payload: {
        error: {
          code: error.errorCode,
          message: error.message,
          ...(error.details ? { details: error.details } : {}),
        },
      },
    };
  }

  return {
    exitCode: EXIT_CODES.QUERY_FAILED,
    payload: {
      error: {
        code: "QUERY_FAILED",
        message: error instanceof Error ? error.message : String(error),
      },
    },
  };
}

export async function runCli(argv, env = process.env, io = process) {
  try {
    const parsed = parseCliArgs(argv, env);
    if (parsed.help) {
      io.stdout.write(`${parsed.text}\n`);
      return EXIT_CODES.OK;
    }

    const result = await runCommand(parsed);
    io.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
    return EXIT_CODES.OK;
  } catch (error) {
    const normalized = normalizeError(error);
    io.stderr.write(`${JSON.stringify(normalized.payload, null, 2)}\n`);
    return normalized.exitCode;
  }
}
