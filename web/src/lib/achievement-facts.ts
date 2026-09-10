// SPEC: README kind achievements — the counters are FACTS derived from the user's documents plus the engine's tallies;
// the pass (achievementsEarned) runs after every recompute (5.6.4) and earned ids are only ever added (V35).
// Server twin of ios/Crew/Storage/AchievementFacts.swift (which derives the solo counters from the local store).
import type { ObjectId } from "mongodb";
import { crewMemberships, posts, reactions, sessions } from "@/lib/db";
import type { AchievementCounters } from "@/lib/engine/achievements";
import { fullPulseDays, fullPulseWeeks, type MemberFacts } from "@/lib/engine/crew-rules";
import type { GamificationState } from "@/lib/engine/gamification";
import { prCount, type RecordSession } from "@/lib/engine/personal-records";
import type { CrewMembershipDoc } from "@/lib/documents-social";

export async function achievementCounters(userId: ObjectId, state: GamificationState, todayKey: string, accountUnit: "lb" | "kg" = "lb"): Promise<AchievementCounters> {
  const [postsTotal, completed, reactionsGiven, membership] = await Promise.all([
    (await posts()).countDocuments({ userId, deletedAt: null }),
    (await sessions()).find({ userId, status: "completed" }, { projection: { completedAt: 1, exercises: 1 } }).toArray(),
    (await reactions()).countDocuments({ userId }),
    (await crewMemberships()).findOne({ userId }),
  ]);
  const history: RecordSession[] = completed.map((doc) => ({ completedAt: (doc.completedAt ?? new Date(0)).toISOString(), exercises: doc.exercises.map((row) => ({ exerciseId: row.exerciseId, name: row.name, sets: row.sets })) }));
  const crew = membership === null ? { days: 0, weeks: 0 } : await crewFullPulse(membership, todayKey);
  return {
    postsTotal, workoutsCompleted: completed.length, currentStreak: state.currentStreak, perfectWeeks: state.tallies.perfectWeeks, prCount: prCount(history, accountUnit), // A9: compare on one normalised scale
    shieldsConsumed: state.tallies.shieldsConsumed, comebacks: state.tallies.comebacks, crewJoined: membership === null ? 0 : 1, reactionsGiven,
    crewFullPulseDays: crew.days, crewFullPulseWeeks: crew.weeks,
  };
}

// Membership as of each day (V40) from the memberships that exist now; every member's posts since this user joined
async function crewFullPulse(membership: CrewMembershipDoc, todayKey: string): Promise<{ days: number; weeks: number }> {
  const memberDocs = await (await crewMemberships()).find({ crewId: membership.crewId }).toArray();
  const members: MemberFacts[] = memberDocs.map((doc) => ({ userId: doc.userId.toHexString(), joinedDayKey: doc.joinedDayKey }));
  const fromDay = membership.joinedDayKey;
  const memberPosts = await (await posts()).find({ userId: { $in: memberDocs.map((doc) => doc.userId) }, deletedAt: null, dayKey: { $gte: fromDay, $lte: todayKey } }, { projection: { userId: 1, dayKey: 1 } }).toArray();
  const postFacts = memberPosts.map((doc) => ({ userId: doc.userId.toHexString(), dayKey: doc.dayKey }));
  return { days: fullPulseDays(members, postFacts, fromDay, todayKey), weeks: fullPulseWeeks(members, postFacts, fromDay, todayKey) };
}
