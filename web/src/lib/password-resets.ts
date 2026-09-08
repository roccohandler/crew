// SPEC: Part IV (password reset: single-use token, 30-min expiry) · 8.2 Auth (old token dead after use; reset
// invalidates existing refresh tokens) · E18 (standard resets). Tokens are opaque and stored hashed.
import { randomBytes } from "node:crypto";
import { ObjectId } from "mongodb";
import { apiError } from "@/lib/api-error";
import { CryptoParams } from "@/lib/crypto-params";
import { passwordResets, users } from "@/lib/db";
import { HttpStatus } from "@/lib/http-status";
import { hashPassword } from "@/lib/password";
import { hashToken, revokeAllRefreshTokens } from "@/lib/refresh-tokens";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export function resetLinkFor(token: string): string {
  const base = process.env.APP_BASE_URL ?? "http://localhost:3000";
  return `${base}/reset?token=${encodeURIComponent(token)}`;
}

export async function createPasswordReset(userId: ObjectId, now: Date = new Date()): Promise<string> {
  const token = randomBytes(CryptoParams.opaqueTokenBytes).toString("base64url");
  await (await passwordResets()).insertOne({
    _id: new ObjectId(),
    userId,
    tokenHash: hashToken(token),
    expiresAt: new Date(now.getTime() + SpecConstants.passwordResetTokenExpiryMinutes * TimeUnits.msPerMinute),
    usedAt: null,
    createdAt: now,
  });
  return token;
}

const invalidToken = () => apiError("resetTokenInvalid", "That reset link is no longer valid. Request a new one.", HttpStatus.badRequest);

// Consumes the token exactly once, sets the new hash, and signs the user out everywhere.
export async function confirmPasswordReset(token: string, newPassword: string, now: Date = new Date()): Promise<ObjectId> {
  const collection = await passwordResets();
  const consumed = await collection.findOneAndUpdate(
    { tokenHash: hashToken(token), usedAt: null, expiresAt: { $gt: now } },
    { $set: { usedAt: now } },
  );
  if (consumed === null) throw invalidToken();
  const passwordHash = await hashPassword(newPassword);
  await (await users()).updateOne({ _id: consumed.userId }, { $set: { passwordHash } });
  await revokeAllRefreshTokens(consumed.userId, now);
  return consumed.userId;
}
