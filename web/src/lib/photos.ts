// SPEC: docs/api.md photos — upload (strip + resize + store, returns photoKey) and the auth-checked read. A22 G2 (owner-approved
// 2026-09-18): photos leave the product except the PROFILE picture (E1, A7) — `purpose` is "profile" and nothing else, and the
// read serves profile photos only: the owner's, or a crew-mate's (the avatars in the stream and on Home). Rows uploaded with the
// retired purpose "post" (the plate journal) stay in storage until the account's cascade deletes them and are served to no one.
// W5 (owner-approved 2026-09-17): a signed-in stranger is REFUSED with 403 — the key is 128 random bits, so naming it reveals
// nothing worth hiding, and the refusal is the fact; an unknown key is 404. T027
import { ObjectId } from "mongodb";
import { apiError, forbidden, notFound } from "@/lib/api-error";
import { deleteStoredPhoto, newPhotoKey, processPhoto, storePhoto } from "@/lib/blob";
import { crewMemberships, photos } from "@/lib/db";
import type { PhotoDoc } from "@/lib/documents-auth";
import { HttpStatus } from "@/lib/http-status";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const ACCEPTED_TYPES = new Set(["image/jpeg", "image/png", "image/heic", "image/heif", "image/webp"]);
const MAX_SOURCE_BYTES = SpecConstants.photoMaxSourceMb * TimeUnits.msPerSecond * TimeUnits.msPerSecond;

// SPEC: A22 G2 — the one purpose a photo can be uploaded for
export type PhotoPurpose = "profile";

export async function uploadPhoto(ownerId: ObjectId, file: File, purpose: PhotoPurpose, now: Date = new Date()): Promise<PhotoDoc> {
  if (!ACCEPTED_TYPES.has(file.type)) throw apiError("validation", "Send a JPEG, PNG, HEIC or WebP photo.", HttpStatus.badRequest);
  if (file.size > MAX_SOURCE_BYTES) throw apiError("photoTooLarge", `That photo is over ${SpecConstants.photoMaxSourceMb} MB. Pick a smaller one.`, HttpStatus.payloadTooLarge);
  const processed = await processPhoto(Buffer.from(await file.arrayBuffer()));
  const photoKey = newPhotoKey();
  const stored = await storePhoto(photoKey, processed.bytes);
  const doc: PhotoDoc = { _id: new ObjectId(), photoKey, ownerId, purpose, bytes: processed.bytes.length, width: processed.width, height: processed.height, storage: stored.storage, url: stored.url, createdAt: now };
  await (await photos()).insertOne(doc);
  return doc;
}

// SPEC: 8.7 · A22 G2 — a PROFILE photo: the owner's, or one of someone in the owner's crew. A legacy post photo is not found.
export async function readablePhoto(viewerId: ObjectId, photoKey: string): Promise<PhotoDoc> {
  const doc = await (await photos()).findOne({ photoKey, purpose: "profile" });
  if (doc === null) throw notFound("Photo");
  if (doc.ownerId.equals(viewerId)) return doc;
  const memberships = await crewMemberships();
  const mine = await memberships.findOne({ userId: viewerId });
  const theirs = mine === null ? null : await memberships.findOne({ userId: doc.ownerId, crewId: mine.crewId });
  if (theirs === null) throw forbidden("That photo isn't yours to see.");
  return doc;
}

export async function deletePhotosOf(ownerId: ObjectId): Promise<number> {
  const collection = await photos();
  const docs = await collection.find({ ownerId }).toArray();
  for (const doc of docs) await deleteStoredPhoto(doc.storage, doc.url);
  await collection.deleteMany({ ownerId });
  return docs.length;
}
