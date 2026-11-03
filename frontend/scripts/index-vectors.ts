import type { RowDataPacket } from "mysql2";
import { getPool } from "@/lib/db";
import { upsertInventionVector } from "@/lib/qdrant";

type InventionRow = RowDataPacket & {
  invention_id: string;
  title: string;
  abstract: string | null;
  description: string | null;
  category: string;
};

async function main(): Promise<void> {
  const [rows] = await getPool().query<InventionRow[]>(
    `SELECT invention_id, title, abstract, description, category
     FROM inventions ORDER BY invention_id`,
  );
  for (const row of rows) {
    await upsertInventionVector({
      invention_id: Number(row.invention_id),
      title: row.title,
      abstract: row.abstract,
      description: row.description,
      category: row.category,
    });
    console.log(`Indexed invention ${row.invention_id}: ${row.title}`);
  }
  console.log(`Indexed ${rows.length} inventions.`);
  await getPool().end();
}

main().catch(async (error: unknown) => {
  console.error("Vector indexing failed.", error);
  await getPool().end().catch((closeError: unknown) => {
    console.error("Failed to close the MySQL connection pool.", closeError);
  });
  process.exitCode = 1;
});
