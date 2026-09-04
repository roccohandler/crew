// Arithmetic invariants over the vector fixtures — a second, independent computation that catches a
// wrong expected value before it can become a "green" bug on both engines (Part XII 12.5).
// Used by check-vectors.mjs. Constants come from shared/spec-constants.json, never inline.
// SPEC: 8.1 · Decision Registry G1 (reactions) / G2 (levels) · Flow 7 (shields) · V22–V23 (pause limits)

import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const constants = JSON.parse(readFileSync(join(repoRoot, "shared", "spec-constants.json"), "utf8"));
const levelBaseXp = constants.levels.levelBaseXp.value;
const pauseMaxDays = constants.pause.pauseMaxDays.value;
const maxShields = constants.shields.maxShields.value;
const AWARD_ORDER = ["xp", "streakTo", "comeback", "perfectWeek", "shieldEarned", "shieldConsumed", "levelUp", "achievement", "prBadge"];
const XP_REASON_ORDER = ["firstPostOfDay", "plannedWorkout", "bonusWorkout", "meal", "reaction", "comeback", "perfectWeek"];
const XP_AMOUNTS = {
  firstPostOfDay: constants.xp.xpFirstPostOfDay.value, plannedWorkout: constants.xp.xpPlannedWorkout.value,
  bonusWorkout: constants.xp.xpBonusWorkout.value, meal: constants.xp.xpMealPost.value, reaction: constants.xp.xpReaction.value,
  comeback: constants.xp.xpComeback.value, perfectWeek: constants.xp.xpPerfectWeek.value,
};

// SPEC: Decision Registry G2 — level N requires totalXP ≥ levelBaseXp × (N−1) × N / 2
export function levelFor(totalXP) {
  let level = 1;
  while (totalXP >= (levelBaseXp * level * (level + 1)) / 2) level += 1;
  return level;
}

function utcParts(dayKey) {
  const [year, month, day] = dayKey.split("-").map(Number);
  return [year, month - 1, day];
}

export function daysBetween(fromDayKey, toDayKey) {
  return Math.round((Date.UTC(...utcParts(toDayKey)) - Date.UTC(...utcParts(fromDayKey))) / 86400000);
}

export function isMonday(dayKey) {
  return new Date(Date.UTC(...utcParts(dayKey))).getUTCDay() === 1;
}

function checkAwardList(id, where, awards, fail) {
  let lastRank = -1;
  let lastReason = -1;
  for (const award of awards) {
    const rank = AWARD_ORDER.indexOf(award.award);
    if (rank < 0) { fail(id, `${where}: unknown award ${award.award}`); continue; }
    if (rank < lastRank) fail(id, `${where}: ${award.award} breaks the canonical award order`);
    lastRank = rank;
    if (award.award === "xp") {
      const reasonRank = XP_REASON_ORDER.indexOf(award.reason);
      if (reasonRank < 0) fail(id, `${where}: unknown xp reason ${award.reason}`);
      else if (reasonRank <= lastReason) fail(id, `${where}: xp reason ${award.reason} out of order or repeated`);
      lastReason = reasonRank;
      if (award.amount !== XP_AMOUNTS[award.reason]) fail(id, `${where}: xp ${award.reason} must be ${XP_AMOUNTS[award.reason]}, fixture says ${award.amount}`);
    }
    if ((award.award === "streakTo" || award.award === "levelUp") && !Number.isInteger(award.value)) fail(id, `${where}: ${award.award} needs an integer value`);
  }
  const has = (name) => awards.some((award) => award.award === name);
  const hasXp = (reason) => awards.some((award) => award.award === "xp" && award.reason === reason);
  if (has("perfectWeek") !== hasXp("perfectWeek")) fail(id, `${where}: perfectWeek and its xp must appear together`);
  if (has("comeback") !== hasXp("comeback")) fail(id, `${where}: comeback and its xp must appear together`);
}

export function checkApplyInvariants(vector, fail) {
  const { id, initialState: initial, events } = vector;
  const { state: final, awardsByEvent } = vector.expect;
  awardsByEvent.forEach((awards, index) => checkAwardList(id, `awardsByEvent[${index}]`, awards, fail));
  const all = awardsByEvent.flat();
  const hasUndo = events.some((event) => event.type === "postUndone");
  const xpSum = all.filter((award) => award.award === "xp").reduce((sum, award) => sum + award.amount, 0);
  if (!hasUndo && initial.totalXP + xpSum !== final.totalXP) fail(id, `totalXP: ${initial.totalXP} + awarded ${xpSum} ≠ expected ${final.totalXP}`);
  const streakAwards = all.filter((award) => award.award === "streakTo");
  const lastStreak = streakAwards.length ? streakAwards[streakAwards.length - 1].value : initial.currentStreak;
  if (lastStreak !== final.currentStreak) fail(id, `currentStreak: last streakTo ${lastStreak} ≠ expected ${final.currentStreak}`);
  if (final.longestStreak < final.currentStreak) fail(id, "longestStreak is below currentStreak");
  const longest = Math.max(initial.longestStreak, ...streakAwards.map((award) => award.value));
  if (!hasUndo && final.longestStreak !== longest) fail(id, `longestStreak must be ${longest} (max of initial and every streakTo)`);
  const shields = initial.shields + all.filter((award) => award.award === "shieldEarned").length - all.filter((award) => award.award === "shieldConsumed").length;
  if (shields !== final.shields) fail(id, `shields: awards give ${shields}, expected ${final.shields}`);
  if (final.shields < 0 || final.shields > maxShields) fail(id, `shields ${final.shields} out of range 0..${maxShields}`);
  if (levelFor(initial.totalXP) !== initial.level) fail(id, `initialState.level must be ${levelFor(initial.totalXP)} for ${initial.totalXP} XP`);
  if (levelFor(final.totalXP) !== final.level) fail(id, `expect.state.level must be ${levelFor(final.totalXP)} for ${final.totalXP} XP`);
  const levelUps = all.filter((award) => award.award === "levelUp");
  if (!hasUndo && final.level > initial.level && (levelUps.length === 0 || levelUps[levelUps.length - 1].value !== final.level)) fail(id, `a levelUp(${final.level}) award is required`);
  if (final.level === initial.level && levelUps.length > 0) fail(id, "levelUp awarded without a level change");
  let lastDay = null;
  events.forEach((event, index) => {
    // a postUndone names the day of the post it removes, not the moment of the undo
    if (typeof event.dayKey !== "string" || event.type === "postUndone") return;
    if (lastDay && event.dayKey < lastDay) fail(id, `events[${index}] is out of chronological order`);
    lastDay = event.dayKey;
  });
  events.forEach((event, index) => {
    if (event.type === "dayRolledOver" && awardsByEvent[index].some((award) => award.award === "xp")) fail(id, `events[${index}]: a rollover never awards XP`);
  });
}

export function checkDayKeyCases(vector, fail) {
  vector.cases.forEach((item, index) => {
    if (!isMonday(item.weekKey)) fail(vector.id, `cases[${index}]: weekKey ${item.weekKey} is not a Monday`);
    const offset = daysBetween(item.weekKey, item.dayKey);
    if (offset < 0 || offset > 6) fail(vector.id, `cases[${index}]: dayKey ${item.dayKey} is outside week ${item.weekKey}`);
    const localDate = item.at.slice(0, 10);
    const shift = daysBetween(item.dayKey, localDate);
    if (shift !== 0 && shift !== 1) fail(vector.id, `cases[${index}]: dayKey must be the local date of at (${localDate}) or the day before`);
  });
}

// SPEC: V22 (no retro) · V23 (≤ pauseMaxDays) · Flow 7 (one active pause at a time), checked in that order
export function checkPauseCases(vector, fail) {
  vector.cases.forEach((item, index) => {
    let expected = null;
    if (item.startDay < item.today) expected = "retroactive";
    else if (daysBetween(item.startDay, item.endDay) > pauseMaxDays) expected = "tooLong";
    else if (item.existingPauses.some((pause) => pause.endDay > item.today)) expected = "alreadyPaused";
    const fixture = item.expect.accepted ? null : item.expect.reason;
    if (expected !== fixture) fail(vector.id, `cases[${index}]: rule gives ${expected ?? "accepted"}, fixture says ${fixture ?? "accepted"}`);
  });
}
