// SPEC: docs/api.md GET photos/[key] — auth-checked read of a PROFILE photo (A22 G2): own or a crew-mate's. W5 (owner-approved 2026-09-17): the bytes
// are STREAMED from either storage behind the auth check; no redirect to a blob URL ever leaves this route (blobs are private,
// lib/blob.ts). A stranger gets 403 (8.7); an unknown key 404. Never cached beyond the caller. T027
import { ObjectId } from "mongodb";
import { errorResponse } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { readStoredPhoto } from "@/lib/blob";
import { readablePhoto } from "@/lib/photos";

type Context = { params: Promise<{ key: string }> };

export async function GET(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { key } = await context.params;
    const photo = await readablePhoto(new ObjectId(userId), key);
    const stream = await readStoredPhoto(photo.storage, photo.url);
    return new Response(stream, { headers: { "content-type": "image/jpeg", "content-length": String(photo.bytes), "cache-control": "private, max-age=0" } });
  } catch (error) {
    return errorResponse(error);
  }
}
