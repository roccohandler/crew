// SPEC: README "postUndone" (V34 same-day atomic reversal; V35 achievements survive; V43 a rolled-over day's post is a
// deletion, no change) · "dayRolledOver" (V04 reset, V15/V16 shields, V19–V21 pause, sole judge of a miss) ·
// "reactionGiven" (V27: +2 for the first five, 0 after; nothing during a pause). Twin: ios/Crew/Engine/GamificationDay.swift.
import type { Award, GameEvent, GamificationState, Pause } from "@/lib/engine/gamification";
import { isPaused } from "@/lib/engine/gamification";
import { finishAwards } from "@/lib/engine/gamification-post";
import { SpecConstants } from "@/generated/spec-constants";

type UndoEvent = Extract<GameEvent, { type: "postUndone" }>;
type RolloverEvent = Extract<GameEvent, { type: "dayRolledOver" }>;
type ReactionEvent = Extract<GameEvent, { type: "reactionGiven" }>;

export function applyPostUndone(state: GamificationState, event: UndoEvent): Award[] {
  if (state.judgedThroughDayKey !== null && state.judgedThroughDayKey >= event.dayKey) return []; // SPEC: V43, E3
  const stack = state.undo[event.dayKey];
  const snapshot = stack?.pop();
  if (snapshot === undefined) return [];
  const streakBefore = state.currentStreak;
  const restored = JSON.parse(snapshot) as Omit<GamificationState, "undo" | "earnedAchievementIds">;
  Object.assign(state, restored); // SPEC: V34 — XP, streak, longest, lastCountedDayKey and week facts revert together
  return state.currentStreak !== streakBefore ? [{ award: "streakTo", value: state.currentStreak }] : [];
}

export function applyDayRolledOver(state: GamificationState, event: RolloverEvent, pauses: Pause[]): Award[] {
  state.judgedThroughDayKey = event.dayKey;
  if (!event.hadRequirement || state.lastCountedDayKey === event.dayKey || isPaused(event.dayKey, pauses)) return [];
  if (state.shields > 0) {
    state.shields -= 1; // SPEC: V15, V16 — a shield absorbs the miss; the streak stands
    state.tallies.shieldsConsumed += 1;
    return [{ award: "shieldConsumed" }];
  }
  if (state.currentStreak > 0) {
    state.currentStreak = SpecConstants.streakAfterUnshieldedMiss; // SPEC: V04 — stated once, in gray
    return [{ award: "streakTo", value: state.currentStreak }];
  }
  return [];
}

export function applyReactionGiven(state: GamificationState, event: ReactionEvent, pauses: Pause[]): Award[] {
  if (isPaused(event.dayKey, pauses)) return [];
  if (state.day.key !== event.dayKey) state.day = { key: event.dayKey, posts: 0, meals: 0, workouts: 0, reactions: 0 };
  state.day.reactions += 1;
  if (state.day.reactions > SpecConstants.reactionXpDailyCap) return []; // SPEC: V27
  return finishAwards(state, [{ award: "xp", amount: SpecConstants.xpReaction, reason: "reaction" }], state.currentStreak, {});
}
