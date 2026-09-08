// SPEC: docs/api.md POST crews (create; caller = Captain; one crew per user) · GET crews (mine with members + pulse, or null) · T029
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { memberDots, pulseFor } from "@/lib/crew-stream";
import { createCrew, inviteLinkFor, membershipOf } from "@/lib/crews";
import { crews } from "@/lib/db";
import { dayKeyFor } from "@/lib/engine/day-key";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { findUserById } from "@/lib/users";
import { createCrewSchema } from "@/lib/validate-crews";

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = createCrewSchema.parse(await req.json());
    const user = await findUserById(userId);
    const crew = await createCrew(new ObjectId(userId), body.name, body.emoji, user?.timezone ?? "UTC");
    await logEvent(userId, "crew_created");
    return json({ crew: { id: crew._id.toHexString(), name: crew.name, emoji: crew.emoji, captainId: crew.captainId.toHexString(), inviteLink: inviteLinkFor(crew.inviteToken) } }, HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}

export async function GET(req: Request) {
  try {
    const userId = new ObjectId(await requireUser(req));
    const membership = await membershipOf(userId);
    if (membership === null) return json({ crew: null });
    const crew = await (await crews()).findOne({ _id: membership.crewId });
    if (crew === null) return json({ crew: null });
    const user = await findUserById(userId.toHexString());
    const todayKey = dayKeyFor(new Date(), user?.timezone ?? "UTC");
    const isCaptain = crew.captainId.equals(userId);
    return json({
      crew: { id: crew._id.toHexString(), name: crew.name, emoji: crew.emoji, captainId: crew.captainId.toHexString(), inviteLink: isCaptain ? inviteLinkFor(crew.inviteToken) : null, muted: membership.mutedAt !== null },
      members: await memberDots(crew._id, crew.captainId, todayKey),
      pulse: await pulseFor(crew._id, todayKey),
    });
  } catch (error) {
    return errorResponse(error);
  }
}
