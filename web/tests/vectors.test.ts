// SPEC: 8.1 — the shared vectors run against the TS engine and must match EXACTLY (the Swift VectorRunner runs the same
// files). Contract: shared/vectors/README.md. Every kind has a runner; an unknown kind fails, never skips.
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { achievementsEarned, type AchievementCounters } from "@/lib/engine/achievements";
import { completionFacts, type SetFacts } from "@/lib/engine/completion";
import { comebackBanner, crewPulse, crewWeeklyRing, type MemberFacts } from "@/lib/engine/crew-rules";
import { dayKeyFor, weekKeyFor } from "@/lib/engine/day-key";
import { apply, initialState, publicState, type Award, type GameEvent, type Pause, type PublicState } from "@/lib/engine/gamification";
import { recompute, type PostFacts, type ReactionFacts, type SessionFacts } from "@/lib/engine/gamification-recompute";
import { lastRotationKind, nextWorkoutKind } from "@/lib/engine/plan-rotation";
import type { TrainingDaysEntry } from "@/lib/engine/training-days";
import { validatePauseRequest } from "@/lib/engine/pause-validation";
import { normalizedForCompare, weightIn, type WeightUnit } from "@/lib/engine/weight-units";
import { gameEvents, logging, remaining, type MealLogFacts } from "@/lib/engine/macro-day";
import { availability } from "@/lib/engine/nutrition-gate";
import { bodyweightOf, carbs, deriveTargets, type TargetsFacts } from "@/lib/engine/nutrition-targets";
import { removeSet, setsPlanned, type RemovableSet } from "@/lib/engine/set-removal";

const vectorsDir = join(process.cwd(), "..", "shared", "vectors");

interface VectorFile { file: string; vectors: Vector[] }
interface Vector { id: string; title: string; kind: string; [key: string]: unknown }
interface DayRef { dayKey?: string; at?: string; tz?: string }

const files: VectorFile[] = readdirSync(vectorsDir)
  .filter((name) => name.endsWith(".vectors.json"))
  .sort()
  .map((name) => JSON.parse(readFileSync(join(vectorsDir, name), "utf8")) as VectorFile);

// Events and crew posts may name the day as at + tz; the DayKey engine resolves it with THAT moment's zone (V09, V10)
function resolveDay(ref: DayRef): string {
  if (ref.dayKey !== undefined) return ref.dayKey;
  return dayKeyFor(new Date(ref.at as string), ref.tz as string);
}

function runDayKey(vector: Vector) {
  for (const item of vector.cases as { at: string; tz: string; dayKey: string; weekKey: string }[]) {
    const dayKey = dayKeyFor(new Date(item.at), item.tz);
    expect({ dayKey, weekKey: weekKeyFor(dayKey) }, `${vector.id} ${item.at} ${item.tz}`).toEqual({ dayKey: item.dayKey, weekKey: item.weekKey });
  }
}

function runApply(vector: Vector) {
  const pauses = vector.pauses as Pause[];
  const expected = vector.expect as { awardsByEvent: Award[][]; state: PublicState };
  let state = initialState(vector.initialState as PublicState);
  (vector.events as (GameEvent & DayRef)[]).forEach((raw, index) => {
    const event = { ...raw, dayKey: resolveDay(raw) } as GameEvent;
    const result = apply(state, event, pauses);
    state = result.state;
    expect(result.awards, `${vector.id} awards for events[${index}]`).toEqual(expected.awardsByEvent[index]);
  });
  expect(publicState(state), `${vector.id} final state`).toEqual(expected.state);
}

function runCompletion(vector: Vector) {
  for (const item of vector.cases as { sets: SetFacts[]; expect: unknown }[]) expect(completionFacts(item.sets), vector.id).toEqual(item.expect);
}

// SPEC: README kind `nutrition` (V57–V65)
interface NutritionCase { op: string; expect: unknown; bodyweightTenths: number; unit: WeightUnit; energyKcal: number; proteinG: number; fatG: number; targets: TargetsFacts | null; logs: MealLogFacts[]; entries: MealLogFacts[]; birthYear: number | null; currentYear: number }
function nutritionAnswer(item: NutritionCase): unknown {
  if (item.op === "derive") return deriveTargets(item.bodyweightTenths, item.unit);
  if (item.op === "carbs") return carbs(item.energyKcal, item.proteinG, item.fatG);
  if (item.op === "remaining" && item.targets !== null) return remaining(item.targets, item.logs);
  if (item.op === "logging") return item.entries.reduce((logs, entry) => logging(entry, logs), item.logs);
  if (item.op === "gameEvents") return { eventCount: gameEvents(item.logs).length };
  if (item.op === "bodyweightOf") return bodyweightOf(item.targets);
  if (item.op === "availability") return availability(item.birthYear, item.currentYear);
  throw new Error(`no nutrition op ${item.op}`);
}

function runNutrition(vector: Vector) {
  (vector.cases as NutritionCase[]).forEach((item, index) => expect(nutritionAnswer(item), `${vector.id} cases[${index}] ${item.op}`).toEqual(item.expect));
}

// README kind recompute — A27 (a): the plan is a training-days history; a vector written before it names `trainingWeekdays`, which
// is a history of one entry (a day before the first entry is judged by it — R-082). With `cycle`, the rotation pointer is asserted
// from the same completed sessions (V89).
function runRecompute(vector: Vector) {
  const expected = vector.expect as { state: PublicState; nextWorkoutKind?: string };
  const history = (vector.trainingDays as TrainingDaysEntry[] | undefined) ?? [{ from: vector.asOfDayKey as string, weekdays: (vector.trainingWeekdays as number[] | undefined) ?? [] }];
  for (const variant of vector.variants as { label: string; sessions: (SessionFacts & { workoutKind?: string })[]; posts: PostFacts[]; reactions: ReactionFacts[] }[]) {
    expect(recompute(variant.sessions, variant.posts, variant.reactions, vector.pauses as Pause[], vector.asOfDayKey as string, history), `${vector.id} ${variant.label}`).toEqual(expected.state);
    if (expected.nextWorkoutKind === undefined) continue;
    const cycle = vector.cycle as string[];
    const rotation = variant.sessions.map((session) => ({ kind: session.workoutKind ?? null, name: "", completedAt: session.completed ? Date.parse(`${session.dayKey}T12:00:00Z`) : null, status: session.completed ? "completed" : "inProgress" }));
    expect(nextWorkoutKind(lastRotationKind(rotation, cycle), cycle), `${vector.id} ${variant.label} next workout`).toBe(expected.nextWorkoutKind);
  }
}

function runPauseValidation(vector: Vector) {
  for (const item of vector.cases as { today: string; startDay: string; endDay: string; existingPauses: Pause[]; expect: unknown }[]) {
    expect(validatePauseRequest(item.today, item.startDay, item.endDay, item.existingPauses), `${vector.id} ${item.startDay}→${item.endDay}`).toEqual(item.expect);
  }
}

const withDays = (posts: ({ userId: string } & DayRef)[]) => posts.map((post) => ({ userId: post.userId, dayKey: resolveDay(post) }));

function runCrewPulse(vector: Vector) {
  expect(crewPulse(vector.members as MemberFacts[], withDays(vector.posts as ({ userId: string } & DayRef)[]), vector.dayKey as string), vector.id).toEqual(vector.expect);
}

function runCrewWeeklyRing(vector: Vector) {
  for (const item of vector.cases as { asOfDayKey: string; members: MemberFacts[]; posts: ({ userId: string } & DayRef)[]; expect: { days: unknown } }[]) {
    expect(crewWeeklyRing(item.members, withDays(item.posts), item.asOfDayKey), `${vector.id} as of ${item.asOfDayKey}`).toEqual(item.expect.days);
  }
}

function runComebackBanner(vector: Vector) {
  expect(comebackBanner(vector.posts as { dayKey: string }[], vector.pauses as Pause[]), vector.id).toEqual((vector.expect as { comebackByPost: boolean[] }).comebackByPost);
}

function runAchievements(vector: Vector) {
  for (const item of vector.cases as { counters: Partial<AchievementCounters>; alreadyEarned: string[]; expect: { awards: Award[]; earnedAfter: string[] } }[]) {
    const awards = achievementsEarned(item.counters, item.alreadyEarned);
    expect(awards, `${vector.id} awards for ${JSON.stringify(item.counters)}`).toEqual(item.expect.awards);
    expect([...item.alreadyEarned, ...awards.map((award) => (award.award === "achievement" ? award.id : ""))], `${vector.id} earnedAfter`).toEqual(item.expect.earnedAfter);
  }
}

// A9 — one kind, two case shapes: a conversion (value/from/to) and a record comparison (left/right)
function runWeightUnits(vector: Vector) {
  for (const item of vector.cases as { value?: number; from?: WeightUnit; to?: WeightUnit; left?: { value: number; unit: WeightUnit }; right?: { value: number; unit: WeightUnit }; expect: number | string }[]) {
    if (item.left !== undefined && item.right !== undefined) {
      const left = normalizedForCompare(item.left.value, item.left.unit);
      const right = normalizedForCompare(item.right.value, item.right.unit);
      const heavier = left === right ? "equal" : left > right ? "left" : "right";
      expect(heavier, `${vector.id} ${item.left.value} ${item.left.unit} vs ${item.right.value} ${item.right.unit}`).toBe(item.expect);
      continue;
    }
    expect(weightIn(item.value as number, item.from as WeightUnit, item.to as WeightUnit), `${vector.id} ${item.value} ${item.from}→${item.to}`).toBe(item.expect);
  }
}

// A11 — remove one row, renumber the survivors, and never leave an exercise without a work set
function runSetRemoval(vector: Vector) {
  for (const item of vector.cases as { sets: RemovableSet[]; removeOrder: number; expect: { removed: boolean; sets: RemovableSet[]; setsPlanned: number } }[]) {
    const result = removeSet(item.sets, item.removeOrder);
    expect({ removed: result.removed, sets: result.sets, setsPlanned: setsPlanned(result.sets) }, `${vector.id} removing order ${item.removeOrder}`).toEqual(item.expect);
  }
}

const runners: Record<string, (vector: Vector) => void> = {
  achievements: runAchievements,
  weightUnits: runWeightUnits,
  setRemoval: runSetRemoval,
  dayKey: runDayKey, apply: runApply, completion: runCompletion, recompute: runRecompute, nutrition: runNutrition,
  pauseValidation: runPauseValidation, crewPulse: runCrewPulse, crewWeeklyRing: runCrewWeeklyRing, comebackBanner: runComebackBanner,
};

for (const file of files) {
  describe(file.file, () => {
    for (const vector of file.vectors) {
      const spec = vector.retired === undefined ? it : it.skip; // README "Retired vectors": kept, shape-checked, never run
      spec(`${vector.id} ${vector.title}`, () => {
        const run = runners[vector.kind];
        if (run === undefined) throw new Error(`no runner for kind ${vector.kind}`);
        run(vector);
      });
    }
  });
}
