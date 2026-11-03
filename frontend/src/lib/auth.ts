import { createHmac, randomBytes, scrypt as scryptCallback, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";
import { HttpError } from "@/lib/http";

const cookieName = "patentpath_session";
const sessionLifetimeSeconds = 60 * 60 * 8;

function deriveKey(password: string, salt: Buffer): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    scryptCallback(password, salt, 64, { N: 16384, r: 8, p: 1 }, (error, key) => {
      if (error) reject(error);
      else resolve(key);
    });
  });
}

export type SessionUser = {
  userId: number;
  name: string;
  email: string;
  role: "USER" | "ADMIN";
};

type SessionPayload = Pick<SessionUser, "userId" | "role"> & { exp: number };

function getSessionSecret(): string {
  const secret = process.env.SESSION_SECRET;
  if (!secret || Buffer.byteLength(secret, "utf8") < 32) {
    throw new Error("SESSION_SECRET must contain at least 32 bytes.");
  }
  return secret;
}

function sign(value: string): string {
  return createHmac("sha256", getSessionSecret()).update(value).digest("base64url");
}

export function createSessionToken(user: Pick<SessionUser, "userId" | "role">): string {
  const payload: SessionPayload = {
    ...user,
    exp: Math.floor(Date.now() / 1000) + sessionLifetimeSeconds,
  };
  const encoded = Buffer.from(JSON.stringify(payload)).toString("base64url");
  return `${encoded}.${sign(encoded)}`;
}

function readSessionToken(token: string): SessionPayload | null {
  const parts = token.split(".");
  if (parts.length !== 2) return null;
  const [encoded, suppliedSignature] = parts;
  if (!encoded || !suppliedSignature) return null;

  const expected = Buffer.from(sign(encoded));
  const supplied = Buffer.from(suppliedSignature);
  if (expected.length !== supplied.length || !timingSafeEqual(expected, supplied)) return null;

  try {
    const payload = JSON.parse(Buffer.from(encoded, "base64url").toString("utf8")) as SessionPayload;
    if (
      !Number.isSafeInteger(payload.userId) ||
      !["USER", "ADMIN"].includes(payload.role) ||
      !Number.isInteger(payload.exp) ||
      payload.exp <= Math.floor(Date.now() / 1000)
    ) {
      return null;
    }
    return payload;
  } catch {
    return null;
  }
}

export async function getSessionUser(): Promise<SessionPayload | null> {
  const cookieStore = await cookies();
  const token = cookieStore.get(cookieName)?.value;
  return token ? readSessionToken(token) : null;
}

export async function requireUser(): Promise<SessionPayload> {
  const user = await getSessionUser();
  if (!user) throw new HttpError(401, "Please sign in to continue.");
  return user;
}

export async function requireAdmin(): Promise<SessionPayload> {
  const user = await requireUser();
  if (user.role !== "ADMIN") throw new HttpError(403, "Administrator access is required.");
  return user;
}

export function sessionCookieOptions() {
  return {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax" as const,
    path: "/",
    maxAge: sessionLifetimeSeconds,
  };
}

export function clearSessionCookieOptions() {
  return { ...sessionCookieOptions(), maxAge: 0 };
}

export async function verifyPassword(password: string, storedHash: string): Promise<boolean> {
  const [algorithm, saltHex, hashHex] = storedHash.split("$");
  if (algorithm !== "scrypt" || !saltHex || !/^[0-9a-f]{32}$/i.test(saltHex) || !hashHex) {
    return false;
  }

  const expected = Buffer.from(hashHex, "hex");
  if (expected.length !== 64) return false;
  const actual = await deriveKey(password, Buffer.from(saltHex, "hex"));
  return timingSafeEqual(actual, expected);
}

export function makePasswordHash(password: string): Promise<string> {
  const salt = randomBytes(16);
  return deriveKey(password, salt).then(
    (hash) => `scrypt$${salt.toString("hex")}$${hash.toString("hex")}`,
  );
}
