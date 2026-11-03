import { NextResponse } from "next/server";
import { getPool } from "@/lib/db";

export const runtime = "nodejs";

export async function GET() {
  try {
    await getPool().query("SELECT 1");
    const qdrantUrl = process.env.QDRANT_URL;
    if (!qdrantUrl) {
      return NextResponse.json(
        { mysql: "connected", qdrant: "not configured" },
        { status: 503 },
      );
    }

    const headers = new Headers();
    if (process.env.QDRANT_API_KEY) headers.set("api-key", process.env.QDRANT_API_KEY);
    const response = await fetch(`${qdrantUrl.replace(/\/+$/, "")}/collections`, {
      headers,
      cache: "no-store",
    });
    return NextResponse.json(
      { mysql: "connected", qdrant: response.ok ? "connected" : "unavailable" },
      { status: response.ok ? 200 : 503 },
    );
  } catch (error) {
    console.error("Health check failed.", error);
    return NextResponse.json({ error: "Database health check failed." }, { status: 503 });
  }
}
