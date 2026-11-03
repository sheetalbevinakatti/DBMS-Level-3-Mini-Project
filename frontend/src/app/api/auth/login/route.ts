import { NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { z } from "zod";
import { createSessionToken, sessionCookieOptions, verifyPassword } from "@/lib/auth";
import { getPool } from "@/lib/db";
import { errorResponse, HttpError, readJsonBody } from "@/lib/http";

export const runtime = "nodejs";

const loginSchema = z.object({
  email: z.string().email().max(254),
  password: z.string().min(1).max(200),
});

type UserRow = RowDataPacket & {
  user_id: string;
  name: string;
  email: string;
  password_hash: string;
  role: "USER" | "ADMIN";
};

export async function POST(request: Request) {
  try {
    const parsed = loginSchema.safeParse(await readJsonBody(request));
    if (!parsed.success) throw new HttpError(400, "Enter a valid email address and password.");

    const [rows] = await getPool().execute<UserRow[]>(
      `SELECT user_id, name, email, password_hash, role
       FROM users WHERE email = ? LIMIT 1`,
      [parsed.data.email.toLowerCase()],
    );
    const user = rows[0];
    if (!user || !(await verifyPassword(parsed.data.password, user.password_hash))) {
      throw new HttpError(401, "Email or password is incorrect.");
    }

    const response = NextResponse.json({
      user: {
        userId: Number(user.user_id),
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
    response.cookies.set(
      "patentpath_session",
      createSessionToken({ userId: Number(user.user_id), role: user.role }),
      sessionCookieOptions(),
    );
    return response;
  } catch (error) {
    return errorResponse(error);
  }
}
