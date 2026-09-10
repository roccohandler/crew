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
import { validatePauseRequest } from "@/lib/engine/pause-validation";
import { normalizedForCompare, weightIn, type WeightUnit } from "@/lib/engine/weight-units";
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

function runRecompute(vector: Vector) {
  const expected = (vector.expect as { state: PublicState }).state;
  for (const variant of vector.variants as { label: string; sessions: SessionFacts[]; posts: PostFacts[]; reactions: ReactionFacts[] }[]) {
    expect(recompute(variant.sessions, variant.posts, variant.reactions, vector.pauses as Pause[], vector.asOfDayKey as string), `${vector.id} ${variant.label}`).toEqual(expected);
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
  dayKey: runDayKey, apply: runApply, completion: runCompletion, recompute: runRecompute,
  pauseValidation: runPauseValidation, crewPulse: runCrewPulse, crewWeeklyRing: runCrewWeeklyRing, comebackBanner: runComebackBanner,
};

for (const file of files) {
  describe(file.file, () => {
    for (const vector of file.vectors) {
      it(`${vector.id} ${vector.title}`, () => {
        const run = runners[vector.kind];
        if (run === undefined) throw new Error(`no runner for kind ${vector.kind}`);
        run(vector);
      });
    }
  });
}
