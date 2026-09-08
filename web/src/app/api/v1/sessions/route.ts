// SPEC: docs/api.md POST sessions (snapshot, idempotent on clientId) · GET sessions?from=&to= (Progress/Journal) · T023
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { sessions } from "@/lib/db";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { createSession, sessionResponse } from "@/lib/sessions";
import { dayKeySchema } from "@/lib/validate";
import { createSessionSchema } from "@/lib/validate-sessions";

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = createSessionSchema.parse(await req.json());
    const { session, created } = await createSession(new ObjectId(userId), body);
    if (created) await logEvent(userId, "session_started", { planned: session.isPlannedDay });
    return json({ session: sessionResponse(session) }, created ? HttpStatus.created : HttpStatus.ok);
  } catch (error) {
    return errorResponse(error);
  }
}

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    const url = new URL(req.url);
    const from = url.searchParams.get("from");
    const to = url.searchParams.get("to");
    const range: Record<string, string> = {};
    if (from !== null) range.$gte = dayKeySchema.parse(from);
    if (to !== null) range.$lte = dayKeySchema.parse(to);
    const filter = Object.keys(range).length > 0 ? { userId: new ObjectId(userId), dayKey: range } : { userId: new ObjectId(userId) };
    const docs = await (await sessions()).find(filter).sort({ startedAt: -1 }).toArray();
    return json({ items: docs.map(sessionResponse) });
  } catch (error) {
    return errorResponse(error);
  }
}
