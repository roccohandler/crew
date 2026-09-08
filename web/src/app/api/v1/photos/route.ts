// SPEC: docs/api.md POST photos — multipart file + purpose → EXIF/GPS stripped, auto-oriented, resized, JPEG ≤ ~300 KB,
// stored under an unguessable key (E3, 8.7, 8.8) · T027
import { ObjectId } from "mongodb";
import { apiError, errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { uploadPhoto } from "@/lib/photos";

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const form = await req.formData().catch(() => null);
    if (form === null) throw apiError("validation", "Send the photo as multipart form data with a `file` field.", HttpStatus.badRequest);
    const file = form.get("file");
    const purpose = form.get("purpose");
    if (!(file instanceof File)) throw apiError("validation", "The `file` field must be an image.", HttpStatus.badRequest);
    if (purpose !== "post" && purpose !== "profile") throw apiError("validation", "`purpose` must be post or profile.", HttpStatus.badRequest);
    const photo = await uploadPhoto(new ObjectId(userId), file, purpose);
    await logEvent(userId, "photo_uploaded", { purpose, bytes: photo.bytes });
    return json({ photoKey: photo.photoKey, width: photo.width, height: photo.height, bytes: photo.bytes }, HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}
