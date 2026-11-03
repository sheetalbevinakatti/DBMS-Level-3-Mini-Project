import { readFile } from "node:fs/promises";
import path from "node:path";
import mysql from "mysql2/promise";

async function executeFile(connection: mysql.Connection, filePath: string): Promise<void> {
  const contents = await readFile(filePath, "utf8");
  let delimiter = ";";
  let buffer = "";

  for (const line of contents.split(/\r?\n/)) {
    const directive = line.match(/^\s*DELIMITER\s+(\S+)\s*$/i);
    if (directive) {
      if (buffer.trim()) {
        throw new Error(`Unexpected SQL before DELIMITER directive in ${filePath}.`);
      }
      delimiter = directive[1];
      continue;
    }

    buffer += `${line}\n`;
    let delimiterIndex = buffer.indexOf(delimiter);
    while (delimiterIndex >= 0) {
      const statement = buffer.slice(0, delimiterIndex).trim();
      buffer = buffer.slice(delimiterIndex + delimiter.length);
      if (statement) await connection.query(statement);
      delimiterIndex = buffer.indexOf(delimiter);
    }
  }

  if (buffer.trim()) await connection.query(buffer.trim());
}

async function main(): Promise<void> {
  const { MYSQL_HOST } = process.env;
  const setupUser = process.env.MYSQL_SETUP_USER ?? process.env.MYSQL_USER;
  const setupPassword = process.env.MYSQL_SETUP_PASSWORD ?? process.env.MYSQL_PASSWORD;
  if (!MYSQL_HOST || !setupUser || !setupPassword) {
    throw new Error("Set MYSQL_HOST and the MySQL setup credentials before setting up the database.");
  }

  const port = Number(process.env.MYSQL_PORT ?? "3306");
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("MYSQL_PORT must be a valid TCP port.");
  }

  const files = [
    path.resolve(process.cwd(), "..", "database", "schema.sql"),
    path.resolve(process.cwd(), "..", "database", "procedures.sql"),
    path.resolve(process.cwd(), "..", "database", "triggers.sql"),
    path.resolve(process.cwd(), "..", "database", "seed.sql"),
  ];
  const connection = await mysql.createConnection({
    host: MYSQL_HOST,
    port,
    user: setupUser,
    password: setupPassword,
    multipleStatements: false,
    charset: "utf8mb4",
  });

  try {
    for (const file of files) {
      await executeFile(connection, file);
      console.log(`Applied ${path.relative(process.cwd(), file)}`);
    }
  } finally {
    await connection.end();
  }
}

main().catch((error: unknown) => {
  console.error("Database setup failed.", error);
  process.exitCode = 1;
});
