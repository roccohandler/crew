// SPEC: E9 (JSON data export in MVP) · 8.2 Account (export completeness) · docs/api.md users/me/export — everything the user
// owns, assembled into one JSON document. The plan is exported in its A1 shape (a legacy document is normalised first). T041
import type { ObjectId } from "mongodb";
import { blocks, crewMemberships, gamificationStates, messages, pauses, posts, reactions, sessions, users } from "@/lib/db";
import { findPlan } from "@/lib/plans";

export async function exportEverything(userId: ObjectId, now: Date = new Date()) {
  const [user, plan, ownSessions, ownPosts, given, memberships, ownMessages, gamification, ownPauses, ownBlocks] = await Promise.all([
    (await users()).findOne({ _id: userId }, { projection: { passwordHash: 0, appleSub: 0 } }),
    findPlan(userId),
    (await sessions()).find({ userId }).sort({ startedAt: 1 }).toArray(),
    (await posts()).find({ userId }).sort({ createdAt: 1 }).toArray(),
    (await reactions()).find({ userId }).toArray(),
    (await crewMemberships()).find({ userId }).toArray(),
    (await messages()).find({ userId }).sort({ createdAt: 1 }).toArray(),
    (await gamificationStates()).findOne({ userId }),
    (await pauses()).find({ userId }).toArray(),
    (await blocks()).find({ blockerId: userId }).toArray(),
  ]);
  return { exportedAt: now.toISOString(), user, plan, sessions: ownSessions, posts: ownPosts, reactionsGiven: given, memberships, messages: ownMessages, gamification, pauses: ownPauses, blocks: ownBlocks };
}
