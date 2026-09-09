// SPEC: docs/api.md GET/POST/DELETE blocks — block hides content both ways without notification (E9); the list feeds Settings ›
// Blocked people and DELETE is the unblock (A7) · T034 (pulled forward)
import { ObjectId } from "mongodb";
import { errorResponse, json, notFound } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { blockUser, listBlocked, unblockUser } from "@/lib/blocks";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { blockSchema } from "@/lib/validate-crews";

// SPEC: A7 — { blocked: [{ userId, displayName }] }, oldest block first
export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    return json({ blocked: await listBlocked(new ObjectId(userId)) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = blockSchema.parse(await req.json());
    await blockUser(new ObjectId(userId), new ObjectId(body.userId));
    await logEvent(userId, "user_blocked");
    return json({ ok: true }, HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = blockSchema.parse(await req.json());
    const removed = await unblockUser(new ObjectId(userId), new ObjectId(body.userId));
    if (!removed) throw notFound("Block");
    await logEvent(userId, "user_unblocked");
    return json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
