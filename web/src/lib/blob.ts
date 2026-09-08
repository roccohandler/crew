// SPEC: Part IV (Vercel Blob for photos) · 5.2 lib/blob.ts (upload, EXIF strip + resize via sharp) · E1/E3 (EXIF/GPS always
// stripped) · 8.8 (12 MP → ≤ ~300 KB) · 8.7 (blob URLs unguessable + auth-checked: the key is random, the GET route checks).
// Without BLOB_READ_WRITE_TOKEN photos are written under web/.blob-dev/ — the dev/test substitute (rule 3b).
import { randomBytes } from "node:crypto";
import { mkdir, readFile, unlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { put, del } from "@vercel/blob";
import sharp from "sharp";
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
    const result = await put(`photos/${key}.jpg`, bytes, { access: "public", contentType: "image/jpeg", token, addRandomSuffix: true });
    return { storage: "blob", url: result.url };
  }
  await mkdir(LOCAL_DIR, { recursive: true });
  const path = join(LOCAL_DIR, `${key}.jpg`);
  await writeFile(path, bytes);
  return { storage: "local", url: path };
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
