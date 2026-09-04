// Shape checks for each vector kind in shared/vectors (the contract: shared/vectors/README.md).
// Each check takes (vector, fail) and reports every field that is missing, mistyped, or self-inconsistent.
// Used by check-vectors.mjs. SPEC: Part XI T003 (Verify: JSON schema check) · 8.1

import { checkApplyInvariants, checkDayKeyCases, checkPauseCases, daysBetween, isMonday } from "./vector-invariants.mjs";

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

export const shapeChecks = {
  apply: checkApply,
  dayKey: (vector, fail) => { withCases(checkDayKeyCase)(vector, fail); if (Array.isArray(vector.cases)) checkDayKeyCases(vector, fail); },
  completion: withCases(checkCompletionCase),
  recompute: checkRecompute,
  pauseValidation: (vector, fail) => { withCases(checkPauseCase)(vector, fail); if (Array.isArray(vector.cases)) checkPauseCases(vector, fail); },
  crewPulse: checkCrewPulse,
  crewWeeklyRing: withCases(checkCrewWeeklyRingCase),
  comebackBanner: checkComebackBanner,
};
