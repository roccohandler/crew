// SPEC: docs/api.md GET photos/[key] — auth-checked read: own photo or a crew-mate's; blob storage redirects to the
// unguessable URL, the local substitute streams the file (8.7) · T027
import { ObjectId } from "mongodb";
import { errorResponse } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { readLocalPhoto } from "@/lib/blob";
import { readablePhoto } from "@/lib/photos";

type Context = { params: Promise<{ key: string }> };
const FOUND = 302;

export async function GET(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { key } = await context.params;
    const photo = await readablePhoto(new ObjectId(userId), key);
    if (photo.storage === "blob") return new Response(null, { status: FOUND, headers: { location: photo.url, "cache-control": "private, no-store" } });
    const bytes = await readLocalPhoto(photo.url);
    return new Response(new Uint8Array(bytes), { headers: { "content-type": "image/jpeg", "content-length": String(bytes.length), "cache-control": "private, max-age=0" } });
  } catch (error) {
    return errorResponse(error);
  }
}
