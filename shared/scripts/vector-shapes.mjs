// Shape checks for each vector kind in shared/vectors (the contract: shared/vectors/README.md).
// Each check takes (vector, fail) and reports every field that is missing, mistyped, or self-inconsistent.
// Used by check-vectors.mjs. SPEC: Part XI T003 (Verify: JSON schema check) · 8.1

import { checkApplyInvariants, checkDayKeyCases, checkPauseCases, daysBetween, isMonday } from "./vector-invariants.mjs";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// kind achievements: the definitions ARE the seed (shared/seed/achievements.json) — ids, triggers, thresholds, order
const seedAchievements = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "..", "seed", "achievements.json"), "utf8")).achievements;
const TRIGGERS = new Set(seedAchievements.map((achievement) => achievement.trigger));
const ACHIEVEMENT_IDS = new Set(seedAchievements.map((achievement) => achievement.id));

const DAY = /^\d{4}-\d{2}-\d{2}$/;
const INSTANT = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/;
const POST_KINDS = ["workout", "meal", "text"];
const REJECT_REASONS = ["retroactive", "tooLong", "alreadyPaused"];
const isInt = (value) => Number.isInteger(value);
const isDay = (value) => typeof value === "string" && DAY.test(value);

function checkDayRef(id, where, thing, fail) {
  if (typeof thing.dayKey === "string") { if (!isDay(thing.dayKey)) fail(id, `${where}: bad dayKey ${thing.dayKey}`); return; }
  if (!INSTANT.test(thing.at ?? "") || typeof thing.tz !== "string") fail(id, `${where}: needs dayKey or at + tz`);
}

function checkState(id, where, state, fail) {
  for (const field of ["currentStreak", "longestStreak", "totalXP", "level", "shields"]) if (!isInt(state?.[field])) fail(id, `${where}.${field} must be an integer`);
  if (state?.lastCountedDayKey !== null && !isDay(state?.lastCountedDayKey)) fail(id, `${where}.lastCountedDayKey must be a dayKey or null`);
  if (!Array.isArray(state?.earnedAchievementIds)) fail(id, `${where}.earnedAchievementIds must be an array`);
}

function checkPauses(id, pauses, fail) {
  if (!Array.isArray(pauses)) return fail(id, "pauses must be an array");
  for (const pause of pauses) if (!isDay(pause.startDay) || !isDay(pause.endDay) || pause.endDay <= pause.startDay) fail(id, `bad pause ${JSON.stringify(pause)}`);
}

function checkEvent(id, index, event, fail) {
  const where = `events[${index}]`;
  if (event.type === "postCreated") {
    if (!POST_KINDS.includes(event.kind)) fail(id, `${where}: kind must be workout | meal | text`);
    if (typeof event.isPlannedDay !== "boolean") fail(id, `${where}: isPlannedDay must be a boolean`);
    if (event.kind === "workout" && typeof event.workoutCompleted !== "boolean") fail(id, `${where}: workout posts need workoutCompleted`);
    return checkDayRef(id, where, event, fail);
  }
  if (event.type === "postUndone" || event.type === "reactionGiven") { if (!isDay(event.dayKey)) fail(id, `${where}: needs dayKey`); return; }
  if (event.type === "dayRolledOver") { if (!isDay(event.dayKey) || typeof event.hadRequirement !== "boolean") fail(id, `${where}: needs dayKey + hadRequirement`); return; }
  fail(id, `${where}: unknown event type ${event.type}`);
}

function withCases(checkCase) {
  return (vector, fail) => {
    if (!Array.isArray(vector.cases) || vector.cases.length === 0) return fail(vector.id, "cases must be a non-empty array");
    vector.cases.forEach((item, index) => checkCase(vector.id, `cases[${index}]`, item, fail));
  };
}

function checkApply(vector, fail) {
  checkState(vector.id, "initialState", vector.initialState, fail);
  checkPauses(vector.id, vector.pauses, fail);
  if (!Array.isArray(vector.events) || vector.events.length === 0) return fail(vector.id, "events must be a non-empty array");
  vector.events.forEach((event, index) => checkEvent(vector.id, index, event, fail));
  checkState(vector.id, "expect.state", vector.expect?.state, fail);
  const awards = vector.expect?.awardsByEvent;
  if (!Array.isArray(awards) || awards.length !== vector.events.length || !awards.every(Array.isArray)) return fail(vector.id, "expect.awardsByEvent needs one array per event");
  checkApplyInvariants(vector, fail);
}

function checkDayKeyCase(id, where, item, fail) {
  if (!INSTANT.test(item.at ?? "") || typeof item.tz !== "string" || !isDay(item.dayKey) || !isDay(item.weekKey)) fail(id, `${where}: needs at, tz, dayKey, weekKey`);
}

function checkCompletionCase(id, where, item, fail) {
  const sets = Array.isArray(item.sets) ? item.sets : [];
  for (const set of sets) if (!isInt(set.targetReps) || !isInt(set.actualReps) || typeof set.done !== "boolean" || typeof set.isWarmup !== "boolean") fail(id, `${where}: bad set ${JSON.stringify(set)}`);
  const expect = item.expect ?? {};
  if (typeof expect.complete !== "boolean" || !isInt(expect.setsDone) || !isInt(expect.setsPlanned) || !isInt(expect.setsAsPlanned)) return fail(id, `${where}.expect needs complete, setsDone, setsPlanned, setsAsPlanned`);
  if (!Array.isArray(expect.sets) || expect.sets.length !== sets.length) fail(id, `${where}.expect.sets must mirror sets`);
  const work = sets.filter((set) => !set.isWarmup);
  if (expect.setsPlanned !== work.length) fail(id, `${where}: setsPlanned must be the number of non-warm-up sets (${work.length})`);
  if (expect.setsDone !== work.filter((set) => set.done).length) fail(id, `${where}: setsDone must count done non-warm-up sets`);
  if (expect.setsAsPlanned !== work.filter((set) => set.done && set.actualReps >= set.targetReps).length) fail(id, `${where}: setsAsPlanned mismatch`);
  if (expect.complete !== expect.setsDone >= 1) fail(id, `${where}: complete must equal setsDone ≥ 1`);
  sets.forEach((set, index) => {
    const row = expect.sets?.[index] ?? {};
    if (row.done !== set.done || row.asPlanned !== (set.done && set.actualReps >= set.targetReps)) fail(id, `${where}.expect.sets[${index}] disagrees with the set`);
  });
}

function checkRecompute(vector, fail) {
  if (typeof vector.tz !== "string" || !isDay(vector.asOfDayKey)) fail(vector.id, "recompute needs tz + asOfDayKey");
  checkPauses(vector.id, vector.pauses, fail);
  if (!Array.isArray(vector.variants) || vector.variants.length === 0) return fail(vector.id, "variants must be non-empty");
  for (const variant of vector.variants) {
    for (const session of variant.sessions ?? []) if (typeof session.id !== "string" || !isDay(session.dayKey) || typeof session.completed !== "boolean" || !Array.isArray(session.sets)) fail(vector.id, `bad session ${JSON.stringify(session)}`);
    for (const post of variant.posts ?? []) if (!isDay(post.dayKey) || !POST_KINDS.includes(post.kind) || typeof post.isPlannedDay !== "boolean") fail(vector.id, `bad post ${JSON.stringify(post)}`);
    if (!Array.isArray(variant.reactions)) fail(vector.id, "variant.reactions must be an array");
  }
  checkState(vector.id, "expect.state", vector.expect?.state, fail);
}

function checkPauseCase(id, where, item, fail) {
  if (!isDay(item.today) || !isDay(item.startDay) || !isDay(item.endDay) || !Array.isArray(item.existingPauses)) fail(id, `${where}: needs today, startDay, endDay, existingPauses`);
  const expect = item.expect ?? {};
  if (typeof expect.accepted !== "boolean" || (!expect.accepted && !REJECT_REASONS.includes(expect.reason))) fail(id, `${where}.expect needs accepted (+ reason when rejected)`);
}

function checkMembersAndPosts(id, where, item, fail) {
  for (const member of item.members ?? []) if (typeof member.userId !== "string" || !isDay(member.joinedDayKey) || (member.leftDayKey !== undefined && !isDay(member.leftDayKey))) fail(id, `${where}: bad member ${JSON.stringify(member)}`);
  (item.posts ?? []).forEach((post, index) => { if (typeof post.userId !== "string") fail(id, `${where}.posts[${index}] needs userId`); checkDayRef(id, `${where}.posts[${index}]`, post, fail); });
}

function checkCrewPulse(vector, fail) {
  if (!isDay(vector.dayKey)) fail(vector.id, "crewPulse needs dayKey");
  checkMembersAndPosts(vector.id, "crewPulse", vector, fail);
  if (!isInt(vector.expect?.posted) || !isInt(vector.expect?.total) || vector.expect.posted > vector.expect.total) fail(vector.id, "expect needs posted ≤ total");
}

function checkCrewWeeklyRingCase(id, where, item, fail) {
  if (!isDay(item.asOfDayKey)) return fail(id, `${where}: needs asOfDayKey`);
  checkMembersAndPosts(id, where, item, fail);
  const days = item.expect?.days;
  if (!Array.isArray(days) || days.length === 0) return fail(id, `${where}: expect.days must be non-empty`);
  if (!isMonday(days[0].dayKey)) fail(id, `${where}: the ring must start on a Monday`);
  if (days[days.length - 1].dayKey !== item.asOfDayKey) fail(id, `${where}: the ring must end on asOfDayKey`);
  days.forEach((day, index) => {
    if (!isDay(day.dayKey) || !isInt(day.posted) || !isInt(day.total) || day.posted > day.total) fail(id, `${where}.expect.days[${index}] needs dayKey, posted ≤ total`);
    if (index > 0 && daysBetween(days[index - 1].dayKey, day.dayKey) !== 1) fail(id, `${where}.expect.days[${index}] is not the next day`);
  });
}

function checkComebackBanner(vector, fail) {
  checkPauses(vector.id, vector.pauses, fail);
  if (!Array.isArray(vector.posts) || vector.posts.length === 0 || !vector.posts.every((post) => isDay(post.dayKey))) return fail(vector.id, "posts must be a non-empty array of { dayKey }");
  const flags = vector.expect?.comebackByPost;
  if (!Array.isArray(flags) || flags.length !== vector.posts.length || !flags.every((flag) => typeof flag === "boolean")) return fail(vector.id, "expect.comebackByPost needs one boolean per post");
  if (flags[0]) fail(vector.id, "the first post can never be a comeback");
}

// README kind achievements: counters → the seed-ordered awards not yet earned; earnedAfter = alreadyEarned + awarded ids
function checkAchievementCase(id, where, item, fail) {
  const counters = item.counters ?? {};
  for (const [trigger, value] of Object.entries(counters)) if (!TRIGGERS.has(trigger) || !isInt(value) || value < 0) fail(id, `${where}.counters.${trigger} must be a known trigger with an integer ≥ 0`);
  const already = Array.isArray(item.alreadyEarned) ? item.alreadyEarned : [];
  if (!Array.isArray(item.alreadyEarned) || !already.every((earned) => ACHIEVEMENT_IDS.has(earned))) fail(id, `${where}.alreadyEarned must list seed ids`);
  const awards = item.expect?.awards;
  if (!Array.isArray(awards) || !awards.every((award) => award.award === "achievement" && ACHIEVEMENT_IDS.has(award.id))) return fail(id, `${where}.expect.awards must be achievement awards with seed ids`);
  const expectedIds = seedAchievements.filter((achievement) => (counters[achievement.trigger] ?? 0) >= achievement.threshold && !already.includes(achievement.id)).map((achievement) => achievement.id);
  if (JSON.stringify(awards.map((award) => award.id)) !== JSON.stringify(expectedIds)) fail(id, `${where}.expect.awards must be exactly ${JSON.stringify(expectedIds)} (seed order, thresholds, not yet earned)`);
  if (JSON.stringify(item.expect?.earnedAfter) !== JSON.stringify([...already, ...expectedIds])) fail(id, `${where}.expect.earnedAfter must be alreadyEarned followed by the awarded ids`);
}

// README kind weightUnits (A9): a conversion case names value + from + to + the expected number; a comparison case names
// two {value, unit} sides and which one is heavier once normalised. One kind, two case shapes — told apart by their fields.
const WEIGHT_UNITS = ["lb", "kg"];
const HEAVIER = ["left", "right", "equal"];
function checkWeightUnitsCase(id, where, item, fail) {
  if (item.left !== undefined || item.right !== undefined) {
    for (const side of ["left", "right"]) {
      const value = item[side];
      if (typeof value?.value !== "number" || value.value < 0) fail(id, `${where}.${side}.value must be a number ≥ 0`);
      if (!WEIGHT_UNITS.includes(value?.unit)) fail(id, `${where}.${side}.unit must be lb or kg`);
    }
    if (!HEAVIER.includes(item.expect)) fail(id, `${where}.expect must be left, right or equal`);
    return;
  }
  if (typeof item.value !== "number" || item.value < 0) fail(id, `${where}.value must be a number ≥ 0`);
  for (const field of ["from", "to"]) if (!WEIGHT_UNITS.includes(item[field])) fail(id, `${where}.${field} must be lb or kg`);
  if (typeof item.expect !== "number") fail(id, `${where}.expect must be a number`);
  if (item.from === item.to && item.expect !== item.value) fail(id, `${where}: a same-unit conversion must return the value unchanged`);
}

// README kind setRemoval (A11): sets in, one order removed, the renumbered survivors and the new denominator out.
// The expectation is checked for internal consistency here, so a fixture cannot assert a hole or a wrong count.
function checkSetRemovalCase(id, where, item, fail) {
  const sets = item.sets;
  if (!Array.isArray(sets) || sets.length === 0) return fail(id, `${where}.sets must be a non-empty array`);
  for (const set of sets) if (!isInt(set?.order) || typeof set?.isWarmup !== "boolean") fail(id, `${where}.sets needs order + isWarmup`);
  if (!isInt(item.removeOrder)) fail(id, `${where}.removeOrder must be an integer`);
  const expect = item.expect ?? {};
  if (typeof expect.removed !== "boolean") fail(id, `${where}.expect.removed must be a boolean`);
  if (!Array.isArray(expect.sets)) return fail(id, `${where}.expect.sets must be an array`);
  const orders = expect.sets.map((set) => set.order);
  if (JSON.stringify(orders) !== JSON.stringify(orders.map((_, index) => index))) fail(id, `${where}.expect.sets must be renumbered 0..n-1, got ${JSON.stringify(orders)}`);
  const work = expect.sets.filter((set) => set.isWarmup === false).length;
  if (expect.setsPlanned !== work) fail(id, `${where}.expect.setsPlanned must be ${work} (work sets only)`);
  if (work < 1) fail(id, `${where}: an exercise may never be left with zero work sets`);
  if (expect.removed && expect.sets.length !== sets.length - 1) fail(id, `${where}: a removal drops exactly one row`);
  if (!expect.removed && JSON.stringify(expect.sets) !== JSON.stringify(sets)) fail(id, `${where}: a refused removal returns the sets unchanged`);
}

export const shapeChecks = {
  achievements: withCases(checkAchievementCase),
  weightUnits: withCases(checkWeightUnitsCase),
  setRemoval: withCases(checkSetRemovalCase),
  apply: checkApply,
  dayKey: (vector, fail) => { withCases(checkDayKeyCase)(vector, fail); if (Array.isArray(vector.cases)) checkDayKeyCases(vector, fail); },
  completion: withCases(checkCompletionCase),
  recompute: checkRecompute,
  pauseValidation: (vector, fail) => { withCases(checkPauseCase)(vector, fail); if (Array.isArray(vector.cases)) checkPauseCases(vector, fail); },
  crewPulse: checkCrewPulse,
  crewWeeklyRing: withCases(checkCrewWeeklyRingCase),
  comebackBanner: checkComebackBanner,
};
