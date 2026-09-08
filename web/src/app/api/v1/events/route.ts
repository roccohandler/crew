// SPEC: docs/api.md POST events — first-party funnel events from the clients (hero → questions → plan built → saved; 1C speed
// targets "measured, funnel-instrumented", 1D bridge → first post) into the same `events` collection the server writes
// (Part IV: analytics = first-party events to our DB). The client stamps `at` itself so a batch flushed after sign-up keeps
// the pre-auth timestamps; the server clock stamps `receivedAt` (E15). Auth required — an event always belongs to an account.
import { errorResponse, json } from "@/lib/api-error";
import { isIosClient, requireUser } from "@/lib/auth";
import { logClientEvents } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { clientEventsSchema } from "@/lib/validate";

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = clientEventsSchema.parse(await req.json());
    const accepted = await logClientEvents(userId, isIosClient(req) ? "ios" : "web", body.events);
    return json({ accepted }, HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}
