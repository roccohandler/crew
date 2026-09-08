// SPEC: docs/api.md GET users/me/export — the JSON export of everything the user owns (E9) · T041
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { logEvent } from "@/lib/events";
import { exportEverything } from "@/lib/export";
import { HttpStatus } from "@/lib/http-status";

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    const data = await exportEverything(new ObjectId(userId));
    await logEvent(userId, "export_requested");
    return json(data, HttpStatus.ok, { "content-disposition": 'attachment; filename="crew-export.json"' });
  } catch (error) {
    return errorResponse(error);
  }
}
