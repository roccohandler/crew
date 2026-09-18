// SPEC: Part IV (Vercel Blob for photos) · 5.2 lib/blob.ts (upload, EXIF strip + resize via sharp) · E1/E3 (EXIF/GPS always
// stripped) · 8.8 (12 MP → ≤ ~300 KB) · 8.7 (blob URLs unguessable + auth-checked: the key is random, the GET route checks).
// W5 (owner-approved 2026-09-17): blobs are PRIVATE — `access: "private"` on write, `get(…, { access: "private" })` on read — so
// the auth-checked GET route STREAMS the bytes and never hands out a URL a browser could open on its own (the 302 to a public
// blob URL is gone; docs/MVP_STATE_REPORT.md §9). Without BLOB_READ_WRITE_TOKEN photos are written under web/.blob-dev/ — the
// dev/test substitute (rule 3b), streamed the same way.
import { randomBytes } from "node:crypto";
import { mkdir, readFile, unlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { del, get, put } from "@vercel/blob";
import sharp from "sharp";
import { notFound } from "@/lib/api-error";
import { CryptoParams } from "@/lib/crypto-params";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const LOCAL_DIR = join(process.cwd(), ".blob-dev");
const KB = TimeUnits.msPerSecond; // 1000 bytes per KB in the spec's "~300 KB" sense (not 1024)

export interface ProcessedPhoto {
  bytes: Buffer;
  width: number;
  height: number;
}

export function newPhotoKey(): string {
  return randomBytes(CryptoParams.photoKeyBytes).toString("base64url");
}

// sharp drops ALL metadata unless withMetadata() is called — the strip is the default path, never an option
export async function processPhoto(source: Buffer): Promise<ProcessedPhoto> {
  const base = sharp(source, { failOn: "none" }).rotate().resize({ width: SpecConstants.photoMaxEdgePx, height: SpecConstants.photoMaxEdgePx, fit: "inside", withoutEnlargement: true });
  let quality = SpecConstants.photoJpegQuality;
  let encoded = await base.clone().jpeg({ quality, mozjpeg: true }).toBuffer({ resolveWithObject: true });
  while (encoded.data.length > SpecConstants.imageUploadMaxKb * KB && quality - SpecConstants.photoJpegQualityStep >= SpecConstants.photoJpegQualityFloor) {
    quality -= SpecConstants.photoJpegQualityStep;
    encoded = await base.clone().jpeg({ quality, mozjpeg: true }).toBuffer({ resolveWithObject: true });
  }
  return { bytes: encoded.data, width: encoded.info.width, height: encoded.info.height };
}

export async function storePhoto(key: string, bytes: Buffer): Promise<{ storage: "blob" | "local"; url: string }> {
  const token = process.env.BLOB_READ_WRITE_TOKEN ?? "";
  if (token.length > 0) {
    const result = await put(`photos/${key}.jpg`, bytes, { access: "private", contentType: "image/jpeg", token, addRandomSuffix: true });
    return { storage: "blob", url: result.url };
  }
  await mkdir(LOCAL_DIR, { recursive: true });
  const path = join(LOCAL_DIR, `${key}.jpg`);
  await writeFile(path, bytes);
  return { storage: "local", url: path };
}

// SPEC: 8.7 · W5 — the bytes of a stored photo, from either storage, for the auth-checked route to stream; a private blob is
// read with the server's token and never exposed by URL
export async function readStoredPhoto(storage: "blob" | "local", url: string): Promise<ReadableStream<Uint8Array>> {
  if (storage === "local") {
    const bytes = await readFile(url);
    return new Blob([new Uint8Array(bytes)]).stream();
  }
  const token = process.env.BLOB_READ_WRITE_TOKEN ?? "";
  const result = token.length > 0 ? await get(url, { access: "private", token }) : null;
  if (result === null || result.stream === null) throw notFound("Photo");
  return result.stream;
}

export async function readLocalPhoto(url: string): Promise<Buffer> {
  return readFile(url);
}

export async function deleteStoredPhoto(storage: "blob" | "local", url: string): Promise<void> {
  if (storage === "blob") {
    const token = process.env.BLOB_READ_WRITE_TOKEN ?? "";
    if (token.length > 0) await del(url, { token });
    return;
  }
  await unlink(url).catch(() => undefined);
}
