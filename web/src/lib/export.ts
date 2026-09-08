// SPEC: E9 (JSON data export in MVP) · 8.2 Account (export completeness) · docs/api.md users/me/export — everything the user
// owns, assembled into one JSON document. T041
import type { ObjectId } from "mongodb";
import { crewMemberships, gamificationStates, messages, pauses, plans, posts, reactions, sessions, users } from "@/lib/db";

export async function exportEverything(userId: ObjectId, now: Date = new Date()) {
  const [user, plan, ownSessions, ownPosts, given, memberships, ownMessages, gamification, ownPauses] = await Promise.all([
    (await users()).findOne({ _id: userId }, { projection: { passwordHash: 0, appleSub: 0 } }),
    (await plans()).findOne({ userId }),
    (await sessions()).find({ userId }).sort({ startedAt: 1 }).toArray(),
    (await posts()).find({ userId }).sort({ createdAt: 1 }).toArray(),
    (await reactions()).find({ userId }).toArray(),
    (await crewMemberships()).find({ userId }).toArray(),
    (await messages()).find({ userId }).sort({ createdAt: 1 }).toArray(),
    (await gamificationStates()).findOne({ userId }),
    (await pauses()).find({ userId }).toArray(),
  ]);
  return { exportedAt: now.toISOString(), user, plan, sessions: ownSessions, posts: ownPosts, reactionsGiven: given, memberships, messages: ownMessages, gamification, pauses: ownPauses };
}
