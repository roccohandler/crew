// Validates shared/seed/exercises.json + plan-templates.json (+ achievements.json when present) against
// Part IX seed shape, Flow 1 step 3 counts, the mobility block budget, E20 name limits and the swap promise
// (Flow 1 step 4: 3–5 alternatives that do the same job). Exits 1 on any problem.
// Run: node shared/scripts/check-seeds.mjs   SPEC: Part XI T004–T006 · Appendix B · 8.3 (plan generator property)

import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const read = (relative) => JSON.parse(readFileSync(join(repoRoot, relative), "utf8"));
const constants = read("shared/spec-constants.json");
const K = (section, name) => constants[section][name].value;
const seed = read("shared/seed/exercises.json");
const templates = read("shared/seed/plan-templates.json");
const problems = [];
const fail = (message) => problems.push(message);

const LEVEL_RANK = { brandNew: 0, some: 1, experienced: 2 };
const COUNT_FOR = { brandNew: K("planGeneration", "beginnerExerciseCount"), some: K("planGeneration", "someExperienceExerciseCount"), experienced: K("planGeneration", "experiencedExerciseCount") };
const byId = new Map();

for (const exercise of seed.exercises) {
  if (byId.has(exercise.id)) fail(`exercises: duplicate id ${exercise.id}`);
  byId.set(exercise.id, exercise);
  if (!/^[a-z0-9-]+$/.test(exercise.id)) fail(`exercises: id ${exercise.id} must be kebab-case`);
  if (typeof exercise.name !== "string" || exercise.name.length === 0 || exercise.name.length > K("limits", "exerciseNameMaxChars")) fail(`exercises: ${exercise.id} name must be 1–${K("limits", "exerciseNameMaxChars")} chars`);
  for (const field of ["pattern", "equipment", "level", "type"]) if (!seed.enums[field].includes(exercise[field])) fail(`exercises: ${exercise.id}.${field} = ${exercise[field]} is not in the enum`);
  if (typeof exercise.swapGroup !== "string" || typeof exercise.cueLine !== "string" || exercise.cueLine.length < 20) fail(`exercises: ${exercise.id} needs swapGroup + a real cueLine`);
  if (exercise.type === "mobility" && (!Number.isInteger(exercise.holdSeconds) || exercise.holdSeconds <= 0 || typeof exercise.perSide !== "boolean" || exercise.pattern !== "mobility")) fail(`exercises: mobility ${exercise.id} needs holdSeconds > 0, perSide, pattern mobility`);
  if (exercise.type === "strength" && (exercise.holdSeconds !== undefined || exercise.pattern === "mobility")) fail(`exercises: strength ${exercise.id} must not carry holdSeconds or the mobility pattern`);
}

const allowed = seed.enums.equipmentAccess;
const region = seed.enums.region;
// SPEC: exercises.json swapRule — tiers widen only while fewer than swapCandidatesMin are found
function alternativesFor(exercise, access) {
  const usable = (candidate) => candidate.id !== exercise.id && candidate.type === exercise.type && allowed[access].includes(candidate.equipment);
  const tiers = [
    (candidate) => candidate.swapGroup === exercise.swapGroup,
    (candidate) => candidate.pattern === exercise.pattern,
    (candidate) => region[candidate.pattern] === region[exercise.pattern],
  ];
  let found = [];
  for (const tier of tiers) {
    found = seed.exercises.filter((candidate) => usable(candidate) && tier(candidate));
    if (found.length >= K("planGeneration", "swapCandidatesMin")) break;
  }
  return found;
}
for (const pattern of seed.enums.pattern) if (!region[pattern]) fail(`enums.region: no region for pattern ${pattern}`);

for (const [kind, byLevel] of Object.entries(templates.templates)) {
  for (const [level, byAccess] of Object.entries(byLevel)) {
    for (const [access, ids] of Object.entries(byAccess)) {
      const where = `templates.${kind}.${level}.${access}`;
      if (ids.length !== COUNT_FOR[level]) fail(`${where}: ${ids.length} exercises, Flow 1 / G7 require ${COUNT_FOR[level]}`);
      if (ids.length > K("limits", "planMaxExercisesPerDay")) fail(`${where}: over planMaxExercisesPerDay`);
      if (new Set(ids).size !== ids.length) fail(`${where}: repeated exercise`);
      for (const id of ids) {
        const exercise = byId.get(id);
        if (!exercise) { fail(`${where}: unknown exercise ${id}`); continue; }
        if (exercise.type !== "strength") fail(`${where}: ${id} is not a strength exercise`);
        if (!allowed[access].includes(exercise.equipment)) fail(`${where}: ${id} needs ${exercise.equipment}, not available with ${access}`);
        if (LEVEL_RANK[exercise.level] > LEVEL_RANK[level]) fail(`${where}: ${id} is level ${exercise.level}, too advanced for ${level}`);
        const alternatives = alternativesFor(exercise, access);
        if (alternatives.length < K("planGeneration", "swapCandidatesMin")) fail(`${where}: ${id} has only ${alternatives.length} swap alternatives with ${access} (Flow 1 step 4 promises ${K("planGeneration", "swapCandidatesMin")}–${K("planGeneration", "swapCandidatesMax")})`);
      }
    }
  }
}

for (const [kind, ids] of Object.entries(templates.mobilityBlocks)) {
  const where = `mobilityBlocks.${kind}`;
  if (!templates.templates[kind]) fail(`${where}: no such workout kind`);
  if (ids.length < K("planGeneration", "mobilityHoldsMin") || ids.length > K("planGeneration", "mobilityHoldsMax")) fail(`${where}: ${ids.length} holds, spec says ${K("planGeneration", "mobilityHoldsMin")}–${K("planGeneration", "mobilityHoldsMax")}`);
  let seconds = 0;
  for (const id of ids) {
    const exercise = byId.get(id);
    if (!exercise || exercise.type !== "mobility") { fail(`${where}: ${id} is not a mobility hold`); continue; }
    seconds += exercise.holdSeconds * (exercise.perSide ? 2 : 1);
  }
  const min = K("planGeneration", "mobilityMinutesMin") * 60;
  const max = K("planGeneration", "mobilityMinutesMax") * 60;
  if (seconds < min || seconds > max) fail(`${where}: ${seconds}s total, spec says ~${min}–${max}s`);
}
for (const kind of Object.keys(templates.templates)) if (!templates.mobilityBlocks[kind]) fail(`mobilityBlocks: ${kind} has no closing block (Flow 1 step 3)`);

const targets = templates.targets;
if (targets.brandNew.sets !== K("planGeneration", "beginnerTargetSets") || targets.brandNew.reps !== K("planGeneration", "beginnerTargetReps")) fail("targets.brandNew must be 3×10 (Flow 1 step 3)");
if (targets.some.sets !== K("planGeneration", "someExperienceTargetSets") || targets.some.reps !== K("planGeneration", "someExperienceTargetRepsMin") || targets.some.repsMax !== K("planGeneration", "someExperienceTargetRepsMax")) fail("targets.some must be 3×8–10 (G7)");
if (templates.split.fullBodyMaxTrainingDays !== K("planGeneration", "fullBodyMaxTrainingDays")) fail("split.fullBodyMaxTrainingDays must match spec-constants");

if (existsSync(join(repoRoot, "shared/seed/achievements.json"))) {
  const achievements = read("shared/seed/achievements.json");
  const ids = new Set();
  for (const achievement of achievements.achievements) {
    if (ids.has(achievement.id)) fail(`achievements: duplicate id ${achievement.id}`);
    ids.add(achievement.id);
    for (const field of ["id", "title", "line", "scope", "trigger"]) if (typeof achievement[field] !== "string") fail(`achievements: ${achievement.id ?? "?"} needs ${field}`);
    if (!["solo", "crew"].includes(achievement.scope)) fail(`achievements: ${achievement.id} scope must be solo | crew`);
    if (!Number.isInteger(achievement.threshold) || achievement.threshold < 1) fail(`achievements: ${achievement.id} needs an integer threshold ≥ 1`);
  }
  console.log(`achievements.json: ${achievements.achievements.length} achievements`);
}

const strength = seed.exercises.filter((exercise) => exercise.type === "strength").length;
console.log(`exercises.json: ${seed.exercises.length} exercises (${strength} strength, ${seed.exercises.length - strength} mobility)`);
console.log(`plan-templates.json: ${Object.keys(templates.templates).length} workout kinds × 3 levels × 3 equipment access = ${Object.keys(templates.templates).length * 9} lists`);
for (const problem of problems) console.log(`PROBLEM  ${problem}`);
if (problems.length > 0) { console.log(`check-seeds: ${problems.length} problem(s)`); process.exit(1); }
console.log("check-seeds: seeds are complete and consistent");
