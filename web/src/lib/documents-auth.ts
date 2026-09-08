// SPEC: Part IV auth (JWT refresh rotation, password reset single-use 30 min) · T033 push tokens · E10 first-party
// analytics · Photos (docs/api.md). Operational documents that Part IX leaves to the implementation. T009.
import type { ObjectId } from "mongodb";

export interface RefreshTokenDoc {
  _id: ObjectId;
  userId: ObjectId;
  tokenHash: string; // sha256 of the opaque token; unique
  familyId: string; // rotation family — reuse of a dead token revokes the whole family
  expiresAt: Date;
  createdAt: Date;
  revokedAt: Date | null;
  replacedByHash: string | null;
}

export interface PasswordResetDoc {
  _id: ObjectId;
  userId: ObjectId;
  tokenHash: string; // unique, single-use
  expiresAt: Date; // passwordResetTokenExpiryMinutes
  usedAt: Date | null;
  createdAt: Date;
}

export interface PushTokenDoc {
  _id: ObjectId;
  userId: ObjectId;
  token: string; // unique
  platform: "ios";
  updatedAt: Date;
}

export interface EventDoc {
  _id: ObjectId;
  userId: ObjectId | null;
  name: string; // e.g. "onboarding_hero", "post_created"
  at: Date; // the moment it happened — the client's own clock for a client batch (POST events), the server's otherwise
  receivedAt?: Date; // client batches only: the server clock when the batch arrived (E15)
  props: Record<string, string | number | boolean | null>;
  source: "server" | "ios" | "web";
}

export interface PhotoDoc {
  _id: ObjectId;
  photoKey: string; // unguessable; unique
  ownerId: ObjectId;
  purpose: "post" | "profile";
  bytes: number;
  width: number;
  height: number;
  storage: "blob" | "local"; // local = dev substitute under web/.blob-dev
  url: string;
  createdAt: Date;
}
