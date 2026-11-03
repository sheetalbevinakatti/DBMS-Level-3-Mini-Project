import { NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { z } from "zod";
import { requireUser } from "@/lib/auth";
import { getPool } from "@/lib/db";
import { errorResponse, HttpError, readJsonBody } from "@/lib/http";
import { searchInventionVectors } from "@/lib/qdrant";

export const runtime = "nodejs";

const searchSchema = z.object({
  query: z.string().trim().min(3).max(1000),
});

type CatalogRow = RowDataPacket & {
  invention_id: string;
  title: string;
  abstract: string | null;
  description: string | null;
  category: string;
  created_by: string;
  inventors: string | null;
  patent_count: string;
};

type PatentRow = RowDataPacket & { invention_id: string; patent_id: string };

export async function POST(request: Request) {
  try {
    const user = await requireUser();
    const parsed = searchSchema.safeParse(await readJsonBody(request));
    if (!parsed.success) throw new HttpError(400, "Enter a search phrase with at least 3 characters.");

    const points = await searchInventionVectors(parsed.data.query, 10);
    const ids = points
      .filter((point) => Number.isSafeInteger(point.id) && point.id > 0)
      .map((point) => point.id);
    const scoreById = new Map(
      points.map((point) => [point.id, Math.max(0, Math.min(1, point.score))]),
    );

    const connection = await getPool().getConnection();
    let searchId = 0;
    let inventions: CatalogRow[] = [];
    try {
      await connection.beginTransaction();
      const [searchResult] = await connection.execute<import("mysql2").ResultSetHeader>(
        `INSERT INTO searches (user_id, query_text, search_method)
         VALUES (?, ?, 'SEMANTIC')`,
        [user.userId, parsed.data.query],
      );
      searchId = Number(searchResult.insertId);

      if (ids.length > 0) {
        const placeholders = ids.map(() => "?").join(", ");
        const [catalogRows] = await connection.query<CatalogRow[]>(
          `SELECT invention_id, title, abstract, description, category,
                  created_by, inventors, patent_count
           FROM v_invention_catalog
           WHERE invention_id IN (${placeholders})`,
          ids,
        );
        const byId = new Map(catalogRows.map((row) => [Number(row.invention_id), row]));
        inventions = ids
          .map((id) => byId.get(id))
          .filter((row): row is CatalogRow => row !== undefined)
          .sort((left, right) =>
            (scoreById.get(Number(right.invention_id)) ?? 0) -
            (scoreById.get(Number(left.invention_id)) ?? 0),
          );

        const [patentRows] = await connection.query<PatentRow[]>(
          `SELECT i.invention_id, p.patent_id
           FROM inventions AS i
           JOIN patent_applications AS pa ON pa.invention_id = i.invention_id
           JOIN patents AS p ON p.application_id = pa.application_id
           WHERE i.invention_id IN (${placeholders})
           ORDER BY p.patent_id`,
          ids,
        );
        const inventionRank = new Map(
          inventions.map((row, index) => [Number(row.invention_id), index]),
        );
        patentRows.sort(
          (left, right) =>
            (inventionRank.get(Number(left.invention_id)) ?? Number.MAX_SAFE_INTEGER) -
            (inventionRank.get(Number(right.invention_id)) ?? Number.MAX_SAFE_INTEGER),
        );
        let rank = 0;
        for (const patent of patentRows) {
          const inventionId = Number(patent.invention_id);
          await connection.execute(
            `INSERT INTO search_results (search_id, patent_id, similarity_score, result_rank)
             VALUES (?, ?, ?, ?)`,
            [searchId, Number(patent.patent_id), scoreById.get(inventionId) ?? 0, ++rank],
          );
        }
      }

      const summary = `Semantic search returned ${inventions.length} matching invention${inventions.length === 1 ? "" : "s"}.`;
      const conclusion = inventions.length
        ? "Review the closest matching abstracts and issued patent claims before deciding whether an invention is distinct."
        : "Try broader terms or different technical synonyms, then compare the matching patent records.";
      await connection.execute(
        "INSERT INTO analyses (search_id, analysis_summary, conclusion) VALUES (?, ?, ?)",
        [searchId, summary, conclusion],
      );
      await connection.commit();
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }

    return NextResponse.json({
      searchId,
      results: inventions.map((row) => ({
        ...row,
        invention_id: Number(row.invention_id),
        patent_count: Number(row.patent_count),
        similarity: scoreById.get(Number(row.invention_id)) ?? 0,
      })),
    });
  } catch (error) {
    return errorResponse(error);
  }
}
