// SPEC: docs/api.md POST sync — ops replayed in order (each idempotent), per-op results + the server gamification state
// which REPLACES the client's (5.6.3 reconcile); device-clock skew reconciled to server time (server-clock.ts) · T023
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { logEvent } from "@/lib/events";
import { recomputeAndStore } from "@/lib/gamification-store";
import { replayOps } from "@/lib/sync-ops";
import { syncSchema } from "@/lib/validate-sessions";

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = syncSchema.parse(await req.json());
    const results = await replayOps(new ObjectId(userId), body);
    const gamification = await recomputeAndStore(userId);
    if (body.ops.length > 0) await logEvent(userId, "sync", { ops: body.ops.length, failed: results.filter((result) => !result.ok).length });
    return json({ results, gamification });
  } catch (error) {
    return errorResponse(error);
  }
}
