// SPEC: docs/api.md GET crews/join?token= (PUBLIC preview for the landing page + the invite-aware hero, 1A/W1) · POST crews/join
// (join via link; crew full; one crew per user; blocked) · T029
import { ObjectId } from "mongodb";
import { apiError, errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { joinCrew } from "@/lib/crews";
import { crewMemberships, crews } from "@/lib/db";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { findUserById } from "@/lib/users";
import { joinCrewSchema } from "@/lib/validate-crews";
import { SpecConstants } from "@/generated/spec-constants";

export async function GET(req: Request) {
  try {
    const token = new URL(req.url).searchParams.get("token") ?? "";
    const crew = token.length > 0 ? await (await crews()).findOne({ inviteToken: token, archivedAt: null }) : null;
    if (crew === null) throw apiError("inviteInvalid", "That invite link isn't live anymore. Ask for a fresh one.", HttpStatus.notFound);
    const memberCount = await (await crewMemberships()).countDocuments({ crewId: crew._id });
    return json({ name: crew.name, emoji: crew.emoji, memberCount, full: memberCount >= SpecConstants.crewMaxMembers });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = joinCrewSchema.parse(await req.json());
    const user = await findUserById(userId);
    const crew = await joinCrew(new ObjectId(userId), body.token, user?.displayName ?? "Someone", user?.timezone ?? "UTC");
    await logEvent(userId, "crew_joined");
    return json({ crewId: crew._id.toHexString(), name: crew.name, emoji: crew.emoji }, HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}
