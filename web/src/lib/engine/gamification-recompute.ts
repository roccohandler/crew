// SPEC: 5.6.1 recompute(sessions, posts, pauses, tz) → GamificationState — server truth; must equal the folded apply()
// (V77, V78; 12.4). Facts are folded chronologically day by day; every day before asOfDayKey is judged by a rollover once the
// first post exists (README "rollover is the sole judge of a miss"). A22 G1 (a) (owner-approved 2026-09-18): the fold knows the
// plan — a day is REQUIRED only when it is a planned training weekday of the plan handed in, and every synthesized post carries
// plannedWeekdays; plan history is not kept, so the current plan judges an unposted past day (R-068 reading 1).
// Twin: ios/Crew/Engine/GamificationRecompute.swift.
import { addDays, isoWeekday } from "@/lib/engine/day-key";
import { apply, initialState, isPaused, publicState, type GamificationState, type Pause, type PostKind, type PublicState } from "@/lib/engine/gamification";

export interface SessionFacts {
  id: string;
  dayKey: string;
  completed: boolean;
}

export interface PostFacts {
  dayKey: string;
  kind: PostKind;
  isPlannedDay: boolean;
  sessionId?: string;
}

export interface ReactionFacts {
  dayKey: string;
}

export function recompute(sessions: SessionFacts[], posts: PostFacts[], reactions: ReactionFacts[], pauses: Pause[], asOfDayKey: string, trainingWeekdays: number[]): PublicState {
  return publicState(recomputeState(sessions, posts, reactions, pauses, asOfDayKey, trainingWeekdays));
}

export function recomputeState(sessions: SessionFacts[], posts: PostFacts[], reactions: ReactionFacts[], pauses: Pause[], asOfDayKey: string, trainingWeekdays: number[]): GamificationState {
  let state = initialState();
  const days = [...posts.map((post) => post.dayKey), ...reactions.map((reaction) => reaction.dayKey)].sort();
  const firstDay = days[0];
  if (firstDay === undefined) return state;
  let started = false;
  for (let day = firstDay; day <= asOfDayKey; day = addDays(day, 1)) {
    for (const post of posts.filter((candidate) => candidate.dayKey === day)) {
      const session = sessions.find((candidate) => candidate.id === post.sessionId);
      state = apply(state, { type: "postCreated", kind: post.kind, dayKey: day, isPlannedDay: post.isPlannedDay, workoutCompleted: session?.completed === true, plannedWeekdays: trainingWeekdays }, pauses).state;
      started = true;
    }
    for (let count = reactions.filter((reaction) => reaction.dayKey === day).length; count > 0; count -= 1) {
      state = apply(state, { type: "reactionGiven", dayKey: day }, pauses).state;
    }
    // SPEC: A22 G1 (a) — only a planned training weekday can be missed; a rest day is never required
    if (day < asOfDayKey) state = apply(state, { type: "dayRolledOver", dayKey: day, hadRequirement: started && !isPaused(day, pauses) && trainingWeekdays.includes(isoWeekday(day)) }, pauses).state;
  }
  return state;
}
