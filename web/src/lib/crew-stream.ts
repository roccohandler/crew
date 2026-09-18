// SPEC: Flow 6 — ONE unified stream: shared posts + system lines, time-merged; feedWindowDays (7); joiners see join-forward
// (E2); blocked users filtered both ways (E9) — from the stream, the PULSE and the MEMBER STRIP alike (A21.2 / W3, 2026-09-17:
// the viewer who blocked or was blocked never counts the other in "n/m today" and never sees them in the strip); reactions
// summarised with the viewer's own; COMEBACK banner per V39 (crew-rules.comebackBanner); the pulse per V37. A21.2 (owner-approved
// 2026-09-17): free-text chat is gone — the messages collection carries system lines only and a legacy `message` row is never
// served. docs/api.md GET crews/[id]/stream. T029–T031
import { ObjectId } from "mongodb";
import { blocks, crewMemberships, gamificationStates, messages, pauses, posts, users } from "@/lib/db";
import type { CrewMembershipDoc } from "@/lib/documents-social";
import { comebackBanner, crewPulse, type MemberFacts } from "@/lib/engine/crew-rules";
import { addDays } from "@/lib/engine/day-key";
import { postResponse } from "@/lib/posts";
import { reactionsFor } from "@/lib/reactions";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export interface MemberDot {
  id: string;
  displayName: string;
  profilePhotoKey: string | null;
  streak: number;
  postedToday: boolean;
  paused: boolean;
  joinedDayKey: string;
  isCaptain: boolean;
}

// SPEC: E9 — everyone this user blocked or was blocked by: the set every crew read filters on
export async function blockedIdsFor(userId: ObjectId): Promise<Set<string>> {
  const docs = await (await blocks()).find({ $or: [{ blockerId: userId }, { blockedId: userId }] }).toArray();
  return new Set(docs.map((doc) => (doc.blockerId.equals(userId) ? doc.blockedId : doc.blockerId).toHexString()));
}

async function visibleMembers(crewId: ObjectId, hidden: Set<string>): Promise<CrewMembershipDoc[]> {
  const members = await (await crewMemberships()).find({ crewId }).sort({ joinedAt: 1 }).toArray();
  return members.filter((member) => !hidden.has(member.userId.toHexString()));
}

// SPEC: Flow 6 member strip · E9 / W3 — `hidden` is the viewer's block set (blockedIdsFor): those members are absent from the strip
export async function memberDots(crewId: ObjectId, captainId: ObjectId, todayKey: string, hidden: Set<string>): Promise<MemberDot[]> {
  const members = await visibleMembers(crewId, hidden);
  const ids = members.map((member) => member.userId);
  const [userDocs, states, todaysPosts, activePauses] = await Promise.all([
    (await users()).find({ _id: { $in: ids } }).toArray(),
    (await gamificationStates()).find({ userId: { $in: ids } }).toArray(),
    (await posts()).find({ userId: { $in: ids }, dayKey: todayKey, deletedAt: null }, { projection: { userId: 1 } }).toArray(),
    (await pauses()).find({ userId: { $in: ids }, startDay: { $lte: todayKey }, endDay: { $gt: todayKey } }).toArray(),
  ]);
  const posted = new Set(todaysPosts.map((post) => post.userId.toHexString()));
  const pausedIds = new Set(activePauses.map((pause) => pause.userId.toHexString()));
  return members.map((member) => {
    const id = member.userId.toHexString();
    const user = userDocs.find((doc) => doc._id.equals(member.userId));
    const state = states.find((doc) => doc.userId.equals(member.userId));
    return { id, displayName: user?.displayName ?? "Member", profilePhotoKey: user?.profilePhotoKey ?? null, streak: state?.currentStreak ?? 0, postedToday: posted.has(id), paused: pausedIds.has(id), joinedDayKey: member.joinedDayKey, isCaptain: captainId.equals(member.userId) };
  });
}

// SPEC: V37 — distinct members who posted this (3 AM) day, over the members the viewer can see (E9 / W3: a blocked member is in
// neither the numerator nor the denominator for either side of the block)
export async function pulseFor(crewId: ObjectId, todayKey: string, hidden: Set<string>) {
  const members = await visibleMembers(crewId, hidden);
  const facts: MemberFacts[] = members.map((member) => ({ userId: member.userId.toHexString(), joinedDayKey: member.joinedDayKey }));
  const todays = await (await posts()).find({ userId: { $in: members.map((member) => member.userId) }, dayKey: todayKey, deletedAt: null }, { projection: { userId: 1, dayKey: 1 } }).toArray();
  return crewPulse(facts, todays.map((post) => ({ userId: post.userId.toHexString(), dayKey: post.dayKey })), todayKey);
}

// Which of a member's posts (by id) are comebacks — the same rule as the engine (V29 / V39)
async function comebackPostIds(userId: ObjectId): Promise<Set<string>> {
  const history = await (await posts()).find({ userId, deletedAt: null }, { projection: { dayKey: 1 } }).sort({ createdAt: 1 }).toArray();
  const userPauses = await (await pauses()).find({ userId }).toArray();
  const flags = comebackBanner(history.map((post) => ({ dayKey: post.dayKey })), userPauses.map((pause) => ({ startDay: pause.startDay, endDay: pause.endDay })));
  return new Set(history.filter((_, index) => flags[index]).map((post) => post._id.toHexString()));
}

export async function streamFor(membership: CrewMembershipDoc, todayKey: string, sinceIso: string | null, hidden: Set<string>) {
  const crewId = membership.crewId;
  const windowStart = new Date(Date.now() - SpecConstants.feedWindowDays * TimeUnits.msPerDay);
  const since = sinceIso === null ? windowStart : new Date(Math.max(windowStart.getTime(), new Date(sinceIso).getTime()));
  const from = new Date(Math.max(since.getTime(), membership.joinedAt.getTime())); // join-forward (E2)
  const [postDocs, systemDocs] = await Promise.all([
    (await posts()).find({ crewId, deletedAt: null, createdAt: { $gte: from } }).sort({ createdAt: 1 }).toArray(),
    (await messages()).find({ crewId, kind: "system", createdAt: { $gte: from } }).sort({ createdAt: 1 }).toArray(), // A21.2: never a legacy chat row
  ]);
  const visiblePosts = postDocs.filter((post) => !hidden.has(post.userId.toHexString()));
  const reactions = await reactionsFor(visiblePosts.map((post) => post._id));
  const comebacks = new Map<string, Set<string>>();
  for (const authorId of new Set(visiblePosts.map((post) => post.userId.toHexString()))) comebacks.set(authorId, await comebackPostIds(new ObjectId(authorId)));
  const items = [
    ...visiblePosts.map((post) => ({ kind: "post" as const, at: post.createdAt.toISOString(), userId: post.userId.toHexString(), post: postResponse(post), reactions: reactions.get(post._id.toHexString()) ?? [], comeback: comebacks.get(post.userId.toHexString())?.has(post._id.toHexString()) ?? false })),
    ...systemDocs.filter((line) => !hidden.has(line.userId.toHexString())).map((line) => ({ kind: "system" as const, at: line.createdAt.toISOString(), userId: line.userId.toHexString(), id: line._id.toHexString(), body: line.body })),
  ].sort((left, right) => left.at.localeCompare(right.at));
  return { items, windowDays: SpecConstants.feedWindowDays, windowStartDayKey: addDays(todayKey, -(SpecConstants.feedWindowDays - 1)) };
}
