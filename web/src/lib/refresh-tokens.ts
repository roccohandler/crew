// SPEC: G11 — refresh tokens live 30 days and ROTATE on every refresh; a used token is dead and its reuse revokes
// the whole family (8.2 Auth: refresh rotation; reset invalidates existing refresh tokens). Tokens are opaque
// random bytes stored as sha256 hashes — the database never holds a usable token.
import { createHash, randomBytes, randomUUID } from "node:crypto";
import { ObjectId } from "mongodb";
import { unauthorized } from "@/lib/api-error";
import { CryptoParams } from "@/lib/crypto-params";
import { refreshTokens } from "@/lib/db";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("base64url");
}

function newOpaqueToken(): string {
  return randomBytes(CryptoParams.opaqueTokenBytes).toString("base64url");
}

async function storeRefreshToken(userId: ObjectId, familyId: string, now: Date): Promise<string> {
  const token = newOpaqueToken();
  await (await refreshTokens()).insertOne({
    _id: new ObjectId(),
    userId,
    tokenHash: hashToken(token),
    familyId,
    expiresAt: new Date(now.getTime() + SpecConstants.jwtRefreshTokenDays * TimeUnits.msPerDay),
    createdAt: now,
    revokedAt: null,
    replacedByHash: null,
  });
  return token;
}

export async function issueRefreshToken(userId: ObjectId, now: Date = new Date()): Promise<string> {
  return storeRefreshToken(userId, randomUUID(), now);
}

// Rotation: the presented token must be live; it is revoked and replaced inside the same family.
export async function rotateRefreshToken(presented: string, now: Date = new Date()): Promise<{ userId: ObjectId; refreshToken: string }> {
  const collection = await refreshTokens();
  const record = await collection.findOne({ tokenHash: hashToken(presented) });
  if (record === null) throw unauthorized();
  if (record.revokedAt !== null) {
    await collection.updateMany({ familyId: record.familyId, revokedAt: null }, { $set: { revokedAt: now } }); // reuse → family dead
    throw unauthorized();
  }
  if (record.expiresAt.getTime() <= now.getTime()) throw unauthorized();
  const refreshToken = await storeRefreshToken(record.userId, record.familyId, now);
  await collection.updateOne({ _id: record._id }, { $set: { revokedAt: now, replacedByHash: hashToken(refreshToken) } });
  return { userId: record.userId, refreshToken };
}

export async function revokeRefreshToken(presented: string, now: Date = new Date()): Promise<void> {
  await (await refreshTokens()).updateOne({ tokenHash: hashToken(presented), revokedAt: null }, { $set: { revokedAt: now } });
}

export async function revokeAllRefreshTokens(userId: ObjectId, now: Date = new Date()): Promise<void> {
  await (await refreshTokens()).updateMany({ userId, revokedAt: null }, { $set: { revokedAt: now } });
}
