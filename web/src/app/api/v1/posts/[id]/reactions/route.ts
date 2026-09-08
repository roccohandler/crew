// SPEC: docs/api.md posts/[id]/reactions — POST react (emoji ∈ reactionEmojis, one per user-target, crew-mates only),
// DELETE un-react; reaction XP cap via recompute (V27) · T026/T030
import { ObjectId } from "mongodb";
import { errorResponse, json, notFound } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { logEvent } from "@/lib/events";
import { recomputeAndStore } from "@/lib/gamification-store";
import { react, reactablePost, unreact } from "@/lib/reactions";
import { findUserById } from "@/lib/users";
import { reactionSchema } from "@/lib/validate-posts";

type Context = { params: Promise<{ id: string }> };

export async function POST(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const body = reactionSchema.parse(await req.json());
    const post = await reactablePost(new ObjectId(userId), id);
    const user = await findUserById(userId);
    await react(new ObjectId(userId), post, body.emoji, user?.timezone ?? "UTC");
    const gamification = await recomputeAndStore(userId);
    await logEvent(userId, "reaction_given", { emoji: body.emoji });
    return json({ ok: true, gamification });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const post = await reactablePost(new ObjectId(userId), id);
    const removed = await unreact(new ObjectId(userId), post);
    if (!removed) throw notFound("Reaction");
    const gamification = await recomputeAndStore(userId);
    return json({ ok: true, gamification });
  } catch (error) {
    return errorResponse(error);
  }
}
