// SPEC: Flow 6 (2–10 people; invite link; one crew per user) · E2 (Captain: rename, remove, regenerate link; captaincy
// auto-passes to the longest-tenured on exit; leavers' posts remain; full crew; last-one-out archives silently) ·
// docs/api.md crews. Plain collection ops + captain checks inline (5.6.4). T029
import { randomBytes } from "node:crypto";
import { ObjectId } from "mongodb";
import { apiError, forbidden, notFound } from "@/lib/api-error";
import { CryptoParams } from "@/lib/crypto-params";
import { blocks, crewMemberships, crews, messages } from "@/lib/db";
import type { CrewDoc, CrewMembershipDoc } from "@/lib/documents-social";
import { dayKeyFor } from "@/lib/engine/day-key";
import { HttpStatus } from "@/lib/http-status";
import { SpecConstants } from "@/generated/spec-constants";

export function newInviteToken(): string {
  return randomBytes(CryptoParams.inviteTokenBytes).toString("base64url");
}

export const alreadyInCrew = () => apiError("alreadyInCrew", "You're already in a crew. One crew at a time in this version.", HttpStatus.conflict);

export async function membershipOf(userId: ObjectId): Promise<CrewMembershipDoc | null> {
  return (await crewMemberships()).findOne({ userId });
}

export async function requireMember(userId: ObjectId, crewId: string): Promise<{ crew: CrewDoc; membership: CrewMembershipDoc }> {
  const crew = ObjectId.isValid(crewId) ? await (await crews()).findOne({ _id: new ObjectId(crewId), archivedAt: null }) : null;
  if (crew === null) throw notFound("Crew");
  const membership = await (await crewMemberships()).findOne({ crewId: crew._id, userId });
  if (membership === null) throw notFound("Crew");
  return { crew, membership };
}

export async function systemLine(crewId: ObjectId, userId: ObjectId, body: string, now: Date): Promise<void> {
  await (await messages()).insertOne({ _id: new ObjectId(), clientId: `system-${new ObjectId().toHexString()}`, crewId, userId, kind: "system", body, createdAt: now, deletedAt: null });
}

export async function createCrew(userId: ObjectId, name: string, emoji: string, timezone: string, now: Date = new Date()): Promise<CrewDoc> {
  if ((await membershipOf(userId)) !== null) throw alreadyInCrew();
  const crew: CrewDoc = { _id: new ObjectId(), name, emoji, captainId: userId, inviteToken: newInviteToken(), createdAt: now, archivedAt: null };
  await (await crews()).insertOne(crew);
  await (await crewMemberships()).insertOne({ _id: new ObjectId(), crewId: crew._id, userId, joinedAt: now, joinedDayKey: dayKeyFor(now, timezone), mutedAt: null });
  return crew;
}

// SPEC: Flow 6 join via link · E2 full crew · E9 blocks (a block in either direction keeps people apart)
export async function joinCrew(userId: ObjectId, token: string, displayName: string, timezone: string, now: Date = new Date()): Promise<CrewDoc> {
  const crew = await (await crews()).findOne({ inviteToken: token, archivedAt: null });
  if (crew === null) throw apiError("inviteInvalid", "That invite link isn't live anymore. Ask for a fresh one.", HttpStatus.notFound);
  if ((await membershipOf(userId)) !== null) throw alreadyInCrew();
  const members = await (await crewMemberships()).find({ crewId: crew._id }).toArray();
  if (members.length >= SpecConstants.crewMaxMembers) throw apiError("crewFull", `This crew is full (${SpecConstants.crewMaxMembers} people).`, HttpStatus.conflict);
  const memberIds = members.map((member) => member.userId);
  const blocked = await (await blocks()).findOne({ $or: [{ blockerId: userId, blockedId: { $in: memberIds } }, { blockerId: { $in: memberIds }, blockedId: userId }] });
  if (blocked !== null) throw apiError("blocked", "You can't join this crew.", HttpStatus.forbidden);
  await (await crewMemberships()).insertOne({ _id: new ObjectId(), crewId: crew._id, userId, joinedAt: now, joinedDayKey: dayKeyFor(now, timezone), mutedAt: null });
  await systemLine(crew._id, userId, `${displayName} joined the crew`, now);
  return crew;
}

// SPEC: E2 — leaving keeps past posts; captaincy passes to the longest-tenured; last one out archives silently
export async function removeMember(actorId: ObjectId, crewId: string, targetId: ObjectId, displayName: string, now: Date = new Date()): Promise<void> {
  const { crew } = await requireMember(actorId, crewId);
  if (!targetId.equals(actorId) && !crew.captainId.equals(actorId)) throw forbidden("Only the Captain can remove members.");
  const memberships = await crewMemberships();
  const removed = await memberships.deleteOne({ crewId: crew._id, userId: targetId });
  if (removed.deletedCount === 0) throw notFound("Member");
  const remaining = await memberships.find({ crewId: crew._id }).sort({ joinedAt: 1 }).toArray();
  if (remaining.length === 0) {
    await (await crews()).updateOne({ _id: crew._id }, { $set: { archivedAt: now } });
    return;
  }
  if (crew.captainId.equals(targetId)) await (await crews()).updateOne({ _id: crew._id }, { $set: { captainId: remaining[0]!.userId } });
  await systemLine(crew._id, targetId, targetId.equals(actorId) ? `${displayName} left the crew` : `${displayName} was removed`, now);
}

export async function requireCaptain(userId: ObjectId, crewId: string): Promise<CrewDoc> {
  const { crew } = await requireMember(userId, crewId);
  if (!crew.captainId.equals(userId)) throw forbidden("Only the Captain can do that.");
  return crew;
}

export async function regenerateInvite(userId: ObjectId, crewId: string): Promise<string> {
  const crew = await requireCaptain(userId, crewId);
  const inviteToken = newInviteToken();
  await (await crews()).updateOne({ _id: crew._id }, { $set: { inviteToken } }); // the old link dies
  return inviteToken;
}

export function inviteLinkFor(token: string): string {
  return `${process.env.APP_BASE_URL ?? "http://localhost:3000"}/join/${token}`;
}
