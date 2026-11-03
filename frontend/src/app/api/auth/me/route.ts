import { NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { requireUser } from "@/lib/auth";
import { getPool } from "@/lib/db";
import { errorResponse } from "@/lib/http";

export const runtime = "nodejs";

type UserRow = RowDataPacket & { user_id: string; name: string; email: string; role: "USER" | "ADMIN" };

export async function GET() {
  try {
    const session = await requireUser();
    const [rows] = await getPool().execute<UserRow[]>(
      "SELECT user_id, name, email, role FROM users WHERE user_id = ? LIMIT 1",
      [session.userId],
    );
    const user = rows[0];
    if (!user) {
      return NextResponse.json({ error: "Your account no longer exists." }, { status: 401 });
    }
    return NextResponse.json({
      user: { userId: Number(user.user_id), name: user.name, email: user.email, role: user.role },
    });
  } catch (error) {
    return errorResponse(error);
  }
}
