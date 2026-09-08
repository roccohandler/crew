// SPEC: Part VIII V01–V44 · 5.6.1 GamificationEngine (state in, state out; one event type; awards) · shared/vectors/README.md
// (the rule text every branch encodes). Twin of ios/Crew/Engine/GamificationEngine.swift — identical names. Pure:
// no I/O, no clocks; the dayKey of every event is computed by the caller with the device timezone of that moment (V10).
// The event handlers live in gamification-post.ts / gamification-day.ts (C9 cap); recompute in gamification-recompute.ts.
import { applyPostCreated } from "@/lib/engine/gamification-post";
import { applyDayRolledOver, applyPostUndone, applyReactionGiven } from "@/lib/engine/gamification-day";
import { SpecConstants } from "@/generated/spec-constants";

export interface Pause {
  startDay: string;
  endDay: string; // return day, exclusive
}

export interface DayCounters {
  key: string | null;
  posts: number;
  meals: number;
  workouts: number; // completed workouts only
  reactions: number;
}

export interface WeekFacts {
  key: string | null;
  posted: string[];
  planned: string[];
  plannedDone: string[];
  awarded: boolean;
}

// README kind achievements: tallies of awards emitted so far — engine memory, reverted with the day on undo
export interface AchievementTallies {
  perfectWeeks: number;
  shieldsConsumed: number;
  comebacks: number;
}

// Part IX fields first; then the engine's own memory (never asserted by vectors)
export interface GamificationState {
  currentStreak: number;
  longestStreak: number;
  totalXP: number;
  level: number;
  shields: number;
  lastCountedDayKey: string | null;
  earnedAchievementIds: string[];
  day: DayCounters;
  week: WeekFacts;
  judgedThroughDayKey: string | null;
  tallies: AchievementTallies;
  undo: Record<string, string[]>; // per-day stack of JSON snapshots taken before each post
}

export type PostKind = "workout" | "meal" | "text";

export type GameEvent =
  | { type: "postCreated"; kind: PostKind; dayKey: string; isPlannedDay: boolean; workoutCompleted?: boolean }
  | { type: "postUndone"; dayKey: string }
  | { type: "dayRolledOver"; dayKey: string; hadRequirement: boolean }
  | { type: "reactionGiven"; dayKey: string };

export type XpReason = "firstPostOfDay" | "plannedWorkout" | "bonusWorkout" | "meal" | "reaction" | "comeback" | "perfectWeek";

export type Award =
  | { award: "xp"; amount: number; reason: XpReason }
  | { award: "streakTo"; value: number }
  | { award: "comeback" }
  | { award: "perfectWeek" }
  | { award: "shieldEarned" }
  | { award: "shieldConsumed" }
  | { award: "levelUp"; value: number }
  | { award: "achievement"; id: string }
  | { award: "prBadge"; exercise: string };

export interface PublicState {
  currentStreak: number;
  longestStreak: number;
  totalXP: number;
  level: number;
  shields: number;
  lastCountedDayKey: string | null;
  earnedAchievementIds: string[];
}

export function initialState(fields?: Partial<PublicState>): GamificationState {
  return {
    currentStreak: 0,
    longestStreak: 0,
    totalXP: 0,
    level: SpecConstants.startingLevel,
    shields: 0,
    lastCountedDayKey: null,
    earnedAchievementIds: [],
    ...fields,
    day: { key: null, posts: 0, meals: 0, workouts: 0, reactions: 0 },
    week: { key: null, posted: [], planned: [], plannedDone: [], awarded: false },
    judgedThroughDayKey: null,
    tallies: { perfectWeeks: 0, shieldsConsumed: 0, comebacks: 0 },
    undo: {},
  };
}

export function publicState(state: GamificationState): PublicState {
  return {
    currentStreak: state.currentStreak,
    longestStreak: state.longestStreak,
    totalXP: state.totalXP,
    level: state.level,
    shields: state.shields,
    lastCountedDayKey: state.lastCountedDayKey,
    earnedAchievementIds: [...state.earnedAchievementIds],
  };
}

// SPEC: G2 — level N requires totalXP ≥ levelBaseXp × (N−1) × N / 2
export function levelFor(totalXP: number): number {
  let level = SpecConstants.startingLevel;
  while (totalXP >= (SpecConstants.levelBaseXp * level * (level + 1)) / SpecConstants.levelFormulaDivisor) level += 1;
  return level;
}

export function isPaused(dayKey: string, pauses: Pause[]): boolean {
  return pauses.some((pause) => pause.startDay <= dayKey && dayKey < pause.endDay);
}

// SPEC: 5.6.1 — apply(_ e: GameEvent, to: GamificationState, pauses: [Pause]) -> (GamificationState, [Award])
export function apply(state: GamificationState, event: GameEvent, pauses: Pause[]): { state: GamificationState; awards: Award[] } {
  const next = structuredClone(state);
  let awards: Award[];
  if (event.type === "postCreated") awards = applyPostCreated(next, event, pauses);
  else if (event.type === "postUndone") awards = applyPostUndone(next, event);
  else if (event.type === "dayRolledOver") awards = applyDayRolledOver(next, event, pauses);
  else awards = applyReactionGiven(next, event, pauses);
  return { state: next, awards };
}
