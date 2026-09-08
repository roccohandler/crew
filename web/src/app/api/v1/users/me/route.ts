// SPEC: docs/api.md users/me — GET (user + gamification + pause + crew summary) · PATCH profile fields · DELETE the cascade (E9) · T041
import { ObjectId } from "mongodb";
import { errorResponse, json, notFound } from "@/lib/api-error";
import { deleteAccount } from "@/lib/account-delete";
import { clearedCookieHeaders, requireUser } from "@/lib/auth";
import { crewMemberships, crews, users } from "@/lib/db";
import { dayKeyFor } from "@/lib/engine/day-key";
import { logEvent } from "@/lib/events";
import { storedState } from "@/lib/gamification-store";
import { HttpStatus } from "@/lib/http-status";
import { currentPause, pauseResponse } from "@/lib/pauses";
import { findUserById, publicUser } from "@/lib/users";
import { deleteAccountSchema, updateMeSchema } from "@/lib/validate";

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    const user = await findUserById(userId);
    if (user === null) throw notFound("User");
    const membership = await (await crewMemberships()).findOne({ userId: user._id });
    const crew = membership ? await (await crews()).findOne({ _id: membership.crewId }) : null;
    const pause = await currentPause(user._id, dayKeyFor(new Date(), user.timezone));
    return json({ user: publicUser(user), gamification: await storedState(userId), pause: pause === null ? null : pauseResponse(pause), crew: crew ? { id: crew._id.toHexString(), name: crew.name, emoji: crew.emoji, muted: membership?.mutedAt !== null } : null });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function PATCH(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = updateMeSchema.parse(await req.json());
    const changes: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(body)) if (value !== undefined) changes[key] = value;
    await (await users()).updateOne({ _id: new ObjectId(userId) }, { $set: changes });
    const user = await findUserById(userId);
    if (user === null) throw notFound("User");
    await logEvent(userId, "profile_updated", { fields: Object.keys(changes).join(",") });
    return json(publicUser(user));
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request) {
  try {
    const userId = await requireUser(req);
    deleteAccountSchema.parse(await req.json());
    await deleteAccount(new ObjectId(userId));
    await logEvent(null, "account_deleted");
    return json({ ok: true }, HttpStatus.ok, clearedCookieHeaders());
  } catch (error) {
    return errorResponse(error);
  }
}
