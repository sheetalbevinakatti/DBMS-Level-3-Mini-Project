import { NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { z } from "zod";
import { requireAdmin, requireUser } from "@/lib/auth";
import { getPool } from "@/lib/db";
import { errorResponse, HttpError, readJsonBody } from "@/lib/http";
import { upsertInventionVector } from "@/lib/qdrant";

export const runtime = "nodejs";

const inventionSchema = z.object({
  title: z.string().trim().min(3).max(200),
  abstract: z.string().trim().max(5000).nullable().optional(),
  description: z.string().trim().max(10000).nullable().optional(),
  category: z.string().trim().min(2).max(100),
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
  created_at: string;
};

export async function GET() {
  try {
    await requireUser();
    const [rows] = await getPool().query<CatalogRow[]>(
      `SELECT invention_id, title, abstract, description, category,
              created_by, inventors, patent_count, created_at
       FROM v_invention_catalog
       ORDER BY created_at DESC, invention_id DESC`,
    );
    return NextResponse.json({
      inventions: rows.map((row) => ({
        ...row,
        invention_id: Number(row.invention_id),
        created_by: row.created_by,
        patent_count: Number(row.patent_count),
      })),
    });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function POST(request: Request) {
  try {
    const user = await requireAdmin();
    const parsed = inventionSchema.safeParse(await readJsonBody(request));
    if (!parsed.success) throw new HttpError(400, "Check the invention fields and try again.");
    const invention = {
      title: parsed.data.title,
      abstract: parsed.data.abstract ?? null,
      description: parsed.data.description ?? null,
      category: parsed.data.category,
    };

    const [result] = await getPool().execute<{ insertId: number | bigint } & import("mysql2").ResultSetHeader>(
      `INSERT INTO inventions (title, abstract, description, category, created_by)
       VALUES (?, ?, ?, ?, ?)`,
      [invention.title, invention.abstract, invention.description, invention.category, user.userId],
    );
    const inventionId = Number(result.insertId);
    try {
      await upsertInventionVector({ ...invention, invention_id: inventionId });
    } catch (error) {
      console.error("Invention was saved but vector indexing failed.", error);
      return NextResponse.json(
        { error: "The invention was saved, but semantic indexing failed. Run the vector indexing command." },
        { status: 503 },
      );
    }
    return NextResponse.json({ invention_id: inventionId }, { status: 201 });
  } catch (error) {
    return errorResponse(error);
  }
}
