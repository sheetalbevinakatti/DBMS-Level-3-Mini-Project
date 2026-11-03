import { NextResponse } from "next/server";

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = "HttpError";
  }
}

export async function readJsonBody(request: Request): Promise<unknown> {
  try {
    return await request.json();
  } catch {
    throw new HttpError(400, "Request body must be valid JSON.");
  }
}

export function errorResponse(error: unknown): NextResponse {
  if (error instanceof HttpError) {
    return NextResponse.json({ error: error.message }, { status: error.status });
  }

  if (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    error.code === "ER_ROW_IS_REFERENCED_2"
  ) {
    return NextResponse.json(
      { error: "This record is referenced by patent records and cannot be deleted." },
      { status: 409 },
    );
  }

  console.error("Request failed", error);
  return NextResponse.json({ error: "The request could not be completed." }, { status: 500 });
}
