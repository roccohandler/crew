// SPEC: 5.6.1 recompute(sessions, posts, pauses, tz) → GamificationState — server truth; must equal the folded apply()
// (V36; 12.4). Facts are folded chronologically day by day; every day before asOfDayKey is judged by a rollover once the
// first post exists (README "rollover is the sole judge of a miss"). Twin: ios/Crew/Engine/GamificationRecompute.swift.
import { addDays } from "@/lib/engine/day-key";
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

export function recompute(sessions: SessionFacts[], posts: PostFacts[], reactions: ReactionFacts[], pauses: Pause[], asOfDayKey: string): PublicState {
  return publicState(recomputeState(sessions, posts, reactions, pauses, asOfDayKey));
}

export function recomputeState(sessions: SessionFacts[], posts: PostFacts[], reactions: ReactionFacts[], pauses: Pause[], asOfDayKey: string): GamificationState {
  let state = initialState();
  const days = [...posts.map((post) => post.dayKey), ...reactions.map((reaction) => reaction.dayKey)].sort();
  const firstDay = days[0];
  if (firstDay === undefined) return state;
  let started = false;
  for (let day = firstDay; day <= asOfDayKey; day = addDays(day, 1)) {
    for (const post of posts.filter((candidate) => candidate.dayKey === day)) {
      const session = sessions.find((candidate) => candidate.id === post.sessionId);
      state = apply(state, { type: "postCreated", kind: post.kind, dayKey: day, isPlannedDay: post.isPlannedDay, workoutCompleted: session?.completed === true }, pauses).state;
      started = true;
    }
    for (let count = reactions.filter((reaction) => reaction.dayKey === day).length; count > 0; count -= 1) {
      state = apply(state, { type: "reactionGiven", dayKey: day }, pauses).state;
    }
    if (day < asOfDayKey) state = apply(state, { type: "dayRolledOver", dayKey: day, hadRequirement: started && !isPaused(day, pauses) }, pauses).state;
  }
  return state;
}
