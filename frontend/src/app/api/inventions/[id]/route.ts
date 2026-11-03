import { NextResponse } from "next/server";
import { z } from "zod";
import { requireAdmin } from "@/lib/auth";
import { getPool } from "@/lib/db";
import { errorResponse, HttpError, readJsonBody } from "@/lib/http";
import { removeInventionVector, upsertInventionVector } from "@/lib/qdrant";

export const runtime = "nodejs";

const inventionSchema = z.object({
  title: z.string().trim().min(3).max(200),
  abstract: z.string().trim().max(5000).nullable().optional(),
  description: z.string().trim().max(10000).nullable().optional(),
  category: z.string().trim().min(2).max(100),
});

type RouteContext = { params: Promise<{ id: string }> };
type InventionRow = {
  invention_id: string;
  title: string;
  abstract: string | null;
  description: string | null;
  category: string;
};

async function getId(context: RouteContext): Promise<number> {
  await requireAdmin();
  const { id } = await context.params;
  const inventionId = Number(id);
  if (!Number.isSafeInteger(inventionId) || inventionId < 1) {
    throw new HttpError(400, "Invalid invention ID.");
  }
  return inventionId;
}

export async function PATCH(request: Request, context: RouteContext) {
  try {
    const inventionId = await getId(context);
    const parsed = inventionSchema.safeParse(await readJsonBody(request));
    if (!parsed.success) throw new HttpError(400, "Check the invention fields and try again.");

    const invention = {
      title: parsed.data.title,
      abstract: parsed.data.abstract ?? null,
      description: parsed.data.description ?? null,
      category: parsed.data.category,
    };
    const [result] = await getPool().execute<import("mysql2").ResultSetHeader>(
      `UPDATE inventions
       SET title = ?, abstract = ?, description = ?, category = ?
       WHERE invention_id = ?`,
      [invention.title, invention.abstract, invention.description, invention.category, inventionId],
    );
    if (result.affectedRows === 0) throw new HttpError(404, "Invention not found.");

    try {
      await upsertInventionVector({ ...invention, invention_id: inventionId });
    } catch (error) {
      console.error("Invention was updated but vector indexing failed.", error);
      return NextResponse.json(
        { error: "The invention was updated, but semantic indexing failed. Run the vector indexing command." },
        { status: 503 },
      );
    }
    return NextResponse.json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(_request: Request, context: RouteContext) {
  try {
    const inventionId = await getId(context);
    const [result] = await getPool().execute<import("mysql2").ResultSetHeader>(
      "DELETE FROM inventions WHERE invention_id = ?",
      [inventionId],
    );
    if (result.affectedRows === 0) throw new HttpError(404, "Invention not found.");

    try {
      await removeInventionVector(inventionId);
    } catch (error) {
      console.error("Invention was deleted but vector cleanup failed.", error);
      return NextResponse.json(
        { error: "The invention was deleted, but its vector could not be removed." },
        { status: 503 },
      );
    }
    return NextResponse.json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
