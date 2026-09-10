// SPEC: 5.6.4 (every mutation ends with recomputeAndStore) · 12.4 (engine truth) · 5.6.3 (server state REPLACES the
// client's) · Part IX GamificationState — server-derived, recomputable from Sessions + Posts alone (+ reactions, pauses).
import { ObjectId } from "mongodb";
import { achievementCounters } from "@/lib/achievement-facts";
import { dayKeyFor } from "@/lib/engine/day-key";
import { achievementsEarned } from "@/lib/engine/achievements";
import { publicState, type Pause, type PublicState } from "@/lib/engine/gamification";
import { recomputeState } from "@/lib/engine/gamification-recompute";
import { logEvent } from "@/lib/events";
import { gamificationStates, pauses, posts, reactions, sessions, users } from "@/lib/db";
import { weightUnitOf } from "@/lib/users";

// The API's gamification shape: Part IX fields + the ids unlocked by THIS mutation (E8: they ride the reply into the celebration)
export type StoredState = PublicState & { newAchievementIds: string[] };

export async function pausesFor(userId: ObjectId): Promise<Pause[]> {
  const docs = await (await pauses()).find({ userId }).sort({ startDay: 1 }).toArray();
  return docs.map((doc) => ({ startDay: doc.startDay, endDay: doc.endDay }));
}

export async function recomputeAndStore(userIdText: string, now: Date = new Date()): Promise<StoredState> {
  const userId = new ObjectId(userIdText);
  const user = await (await users()).findOne({ _id: userId });
  const timezone = user?.timezone ?? "UTC";
  const sessionDocs = await (await sessions()).find({ userId }, { projection: { _id: 1, dayKey: 1, status: 1 } }).toArray();
  const postDocs = await (await posts()).find({ userId, deletedAt: null }, { projection: { dayKey: 1, type: 1, isPlannedDay: 1, sessionId: 1, createdAt: 1 } }).sort({ createdAt: 1 }).toArray();
  const reactionDocs = await (await reactions()).find({ userId }, { projection: { dayKey: 1 } }).toArray();
  const todayKey = dayKeyFor(now, timezone);
  const full = recomputeState(
    sessionDocs.map((doc) => ({ id: doc._id.toHexString(), dayKey: doc.dayKey, completed: doc.status === "completed" })),
    // SPEC: A14 · V25/V30/V31 — the engine knows three post kinds and always has; a cardio post is a WORKOUT to it, so a
    // walk still earns +25, still sustains the streak, and every gamification vector stays green without being re-expected.
    // The new "cardio" type exists for the journal, the heat map and Home's vector row — never for XP.
    postDocs.map((doc) => ({ dayKey: doc.dayKey, kind: doc.type === "cardio" ? "workout" : doc.type, isPlannedDay: doc.isPlannedDay, sessionId: doc.sessionId?.toHexString() })),
    reactionDocs.map((doc) => ({ dayKey: doc.dayKey })),
    await pausesFor(userId),
    todayKey,
  );
  const existing = await (await gamificationStates()).findOne({ userId }, { projection: { earnedAchievementIds: 1 } });
  const earnedBefore = existing?.earnedAchievementIds ?? []; // V35: achievements never recomputed away
  const newAchievementIds = achievementsEarned(await achievementCounters(userId, full, todayKey, await accountWeightUnit(userId)), earnedBefore).map((award) => (award.award === "achievement" ? award.id : "")).filter((id) => id !== "");
  const stored = { ...publicState(full), earnedAchievementIds: [...earnedBefore, ...newAchievementIds] };
  await (await gamificationStates()).updateOne({ userId }, { $set: { ...stored, recomputedAt: now }, $setOnInsert: { _id: new ObjectId(), userId } }, { upsert: true });
  if (newAchievementIds.length > 0) await logEvent(userIdText, "achievement_earned", { ids: newAchievementIds.join(",") });
  return { ...stored, newAchievementIds };
}

// SPEC: A9 — a set logged before the split has no unit of its own; the account's own preference is what it was entered in
async function accountWeightUnit(userId: ObjectId): Promise<"lb" | "kg"> {
  const user = await (await users()).findOne({ _id: userId }, { projection: { units: 1, weightUnit: 1 } });
  return user === null ? "lb" : weightUnitOf(user);
}

export async function storedState(userIdText: string): Promise<PublicState | null> {
  const doc = await (await gamificationStates()).findOne({ userId: new ObjectId(userIdText) });
  if (doc === null) return null;
  return { currentStreak: doc.currentStreak, longestStreak: doc.longestStreak, totalXP: doc.totalXP, level: doc.level, shields: doc.shields, lastCountedDayKey: doc.lastCountedDayKey, earnedAchievementIds: doc.earnedAchievementIds };
}
