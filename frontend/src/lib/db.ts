import mysql, { type Pool, type RowDataPacket } from "mysql2/promise";

let pool: Pool | undefined;

export function getPool(): Pool {
  if (!pool) {
    const host = process.env.MYSQL_HOST;
    const user = process.env.MYSQL_USER;
    const password = process.env.MYSQL_PASSWORD;
    const database = process.env.MYSQL_DATABASE;

    if (!host || !user || !password || !database) {
      throw new Error("MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, and MYSQL_DATABASE must be configured.");
    }

    const port = Number(process.env.MYSQL_PORT ?? "3306");
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
      throw new Error("MYSQL_PORT must be a valid TCP port.");
    }

    pool = mysql.createPool({
      host,
      port,
      user,
      password,
      database,
      charset: "utf8mb4",
      connectionLimit: 10,
      waitForConnections: true,
      queueLimit: 0,
      supportBigNumbers: true,
      bigNumberStrings: true,
      dateStrings: true,
    });
  }
  return pool;
}

export type DbRow = RowDataPacket;
