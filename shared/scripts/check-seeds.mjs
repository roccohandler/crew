// Validates shared/seed/exercises.json + plan-templates.json (+ achievements.json when present) against
// Part IX seed shape, Flow 1 step 3 counts, the mobility block budget, E20 name limits and the swap promise
// (Flow 1 step 4: 3–5 alternatives that do the same job) and the A2 cardio rows (owner-directed 2026-09-08: duration-based
// like mobility, pattern cardio; templates stay strength-only). A21.1 (owner-approved 2026-09-17): every user has full
// commercial gym access — no equipment tier, the swap pool is the whole catalog of the same type, and no exercise name or
// cue may lean on a home object. A26 (owner-approved 2026-09-18): the templates are the OWNER'S three lists — kind → exercise
// ids, the same rows at every experience, sets by experience at one rep count; a row may repeat an exercise; every swap the
// owner named is always offered; every equipment tag has one SF Symbol. Exits 1 on any problem.
// Run: node shared/scripts/check-seeds.mjs   SPEC: Part XI T004–T006 · Appendix B · 8.3 (plan generator property) · A21.1 · A26

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

const COUNT_FOR = { push: K("planGeneration", "templatePushExerciseCount"), pull: K("planGeneration", "templatePullExerciseCount"), legs: K("planGeneration", "templateLegsExerciseCount") };
const byId = new Map();

// SPEC: A21.1 (owner-approved 2026-09-17) — the catalog is gym-only. A rule with no mechanism drifts, so the home OBJECTS a
// name or cue must never lean on are checked here rather than remembered (objects only: the rowing cue's "on the way home" is
// rowing, not a living room). Ids are exempt: they are stable contracts that saved plans and sessions resolve by
// (couch-stretch, doorway-pec-stretch, doorframe-row keep their ids under gym names).
const HOME_WORDS = /\b(couch|sofa|doorframe|doorway|door|table|counter|towel|chair|bed)\b/i;

for (const exercise of seed.exercises) {
  if (byId.has(exercise.id)) fail(`exercises: duplicate id ${exercise.id}`);
  byId.set(exercise.id, exercise);
  if (!/^[a-z0-9-]+$/.test(exercise.id)) fail(`exercises: id ${exercise.id} must be kebab-case`);
  if (typeof exercise.name !== "string" || exercise.name.length === 0 || exercise.name.length > K("limits", "exerciseNameMaxChars")) fail(`exercises: ${exercise.id} name must be 1–${K("limits", "exerciseNameMaxChars")} chars`);
  for (const field of ["pattern", "equipment", "level", "type"]) if (!seed.enums[field].includes(exercise[field])) fail(`exercises: ${exercise.id}.${field} = ${exercise[field]} is not in the enum`);
  if (typeof exercise.swapGroup !== "string" || typeof exercise.cueLine !== "string" || exercise.cueLine.length < 20) fail(`exercises: ${exercise.id} needs swapGroup + a real cueLine`);
  if (exercise.type === "mobility" && (!Number.isInteger(exercise.holdSeconds) || exercise.holdSeconds <= 0 || typeof exercise.perSide !== "boolean" || exercise.pattern !== "mobility")) fail(`exercises: mobility ${exercise.id} needs holdSeconds > 0, perSide, pattern mobility`);
  // SPEC: A2 — a cardio activity is duration-based (holdSeconds = its default seconds) and carries the cardio pattern
  if (exercise.type === "cardio" && (!Number.isInteger(exercise.holdSeconds) || exercise.holdSeconds <= 0 || exercise.pattern !== "cardio")) fail(`exercises: cardio ${exercise.id} needs holdSeconds > 0 and pattern cardio`);
  if (exercise.type === "strength" && (exercise.holdSeconds !== undefined || exercise.pattern === "mobility" || exercise.pattern === "cardio")) fail(`exercises: strength ${exercise.id} must not carry holdSeconds, the mobility pattern or the cardio pattern`);
  for (const field of ["name", "cueLine"]) {
    const hit = typeof exercise[field] === "string" ? exercise[field].match(HOME_WORDS) : null;
    if (hit) fail(`exercises: ${exercise.id}.${field} leans on a home object ("${hit[0]}") — the catalog is gym-only (A21.1)`);
  }
}
if (seed.enums.equipmentAccess !== undefined) fail("exercises.enums.equipmentAccess must not exist — the equipment tiers are gone (A21.1)");

const region = seed.enums.region;
// SPEC: exercises.json swapRule — tiers widen only while fewer than swapCandidatesMin are found; the pool is every exercise of
// the same type (A21.1: no equipment tier)
function alternativesFor(exercise) {
  const usable = (candidate) => candidate.id !== exercise.id && candidate.type === exercise.type;
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

// SPEC: A26 — three lists, kind → exercise ids. No level gate: the owner's rows are the rows at every experience (the barbell
// bench opens a brand-new lifter's Push). A row MAY repeat an exercise (Pull's three rope curls); rows are addressed by order.
if (Object.keys(templates.templates).join() !== templates.split.pplCycle.join()) fail(`templates: must be exactly the pplCycle's kinds (${templates.split.pplCycle.join(", ")}) — A26 replaced every other list`);
for (const [kind, ids] of Object.entries(templates.templates)) {
  const where = `templates.${kind}`;
  if (!Array.isArray(ids) || ids.some((id) => typeof id !== "string")) { fail(`${where}: must be a flat list of exercise ids — templates nest kind → ids (A26)`); continue; }
  if (ids.length !== COUNT_FOR[kind]) fail(`${where}: ${ids.length} exercises, A26 says ${COUNT_FOR[kind]}`);
  if (ids.length > K("limits", "planMaxExercisesPerDay")) fail(`${where}: over planMaxExercisesPerDay`);
  for (const id of ids) {
    const exercise = byId.get(id);
    if (!exercise) { fail(`${where}: unknown exercise ${id}`); continue; }
    if (exercise.type !== "strength") fail(`${where}: ${id} is not a strength exercise`);
    const alternatives = alternativesFor(exercise);
    if (alternatives.length < K("planGeneration", "swapCandidatesMin")) fail(`${where}: ${id} has only ${alternatives.length} swap alternatives (Flow 1 step 4 promises ${K("planGeneration", "swapCandidatesMin")}–${K("planGeneration", "swapCandidatesMax")})`);
  }
}
// SPEC: A26 — "seated row · swaps: dumbbell row, barbell row (barbell never the default)": the owner's Pull opens no row on a barbell
for (const id of templates.templates.pull ?? []) if (byId.get(id)?.equipment === "barbell") fail(`templates.pull: ${id} is a barbell row — barbell is never the default on Pull (A26)`);

// SPEC: A26 — every swap the owner named is ALWAYS offered. SwapFinder stops at the swap-group tier once it holds
// swapCandidatesMin others and caps at swapCandidatesMax, so a group of min…max others is returned whole — whatever the
// user's experience and however the two engines order names.
const templated = new Set(Object.values(templates.templates).flat());
for (const [rowId, named] of Object.entries(templates.namedSwaps ?? {})) {
  const where = `namedSwaps.${rowId}`;
  const row = byId.get(rowId);
  if (!row || !templated.has(rowId)) { fail(`${where}: not a template row`); continue; }
  const others = seed.exercises.filter((candidate) => candidate.id !== rowId && candidate.type === row.type && candidate.swapGroup === row.swapGroup);
  if (others.length < K("planGeneration", "swapCandidatesMin") || others.length > K("planGeneration", "swapCandidatesMax")) fail(`${where}: swap group ${row.swapGroup} holds ${others.length} others — a row with a named swap needs ${K("planGeneration", "swapCandidatesMin")}–${K("planGeneration", "swapCandidatesMax")} so the finder offers them all`);
  for (const id of named) if (!others.some((candidate) => candidate.id === id)) fail(`${where}: ${id} is not in swap group ${row.swapGroup}, so the finder would not offer it`);
}

// SPEC: A26 — one SF Symbol per equipment tag, in ONE place; the phone's chips read it through SeedCatalog
const symbols = seed.enums.equipmentSymbol ?? {};
if (Object.keys(symbols).join() !== seed.enums.equipment.join()) fail("enums.equipmentSymbol: must name exactly the equipment tags, in their order");
for (const [tag, symbol] of Object.entries(symbols)) if (typeof symbol !== "string" || !/^[a-z0-9]+(\.[a-z0-9]+)*$/.test(symbol)) fail(`enums.equipmentSymbol.${tag}: "${symbol}" is not an SF Symbol name`);

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

// SPEC: A26 — experience changes SETS only: every template row is sets × templateTargetReps, no rep range
const targets = templates.targets;
const SETS_FOR = { brandNew: K("planGeneration", "beginnerTargetSets"), some: K("planGeneration", "someExperienceTargetSets"), experienced: K("planGeneration", "experiencedTargetSets") };
if (Object.keys(targets).join() !== seed.enums.level.join()) fail("targets: must name exactly the three experience levels");
for (const [level, target] of Object.entries(targets)) if (target.sets !== SETS_FOR[level] || target.reps !== K("planGeneration", "templateTargetReps") || target.repsMax !== undefined) fail(`targets.${level} must be ${SETS_FOR[level]}×${K("planGeneration", "templateTargetReps")} with no rep range (A26)`);
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

// SPEC: nutrition addendum §5 — the fast-food seed. Flow 4 clause ①'s mechanism lives here: no food is judged, ranked or pictured.
{
  const fastFood = read("shared/seed/fast-food.json");
  const QUALITY_WORDS = /\b(healthy|healthier|clean|junk|lite|light|guilt[- ]?free|guiltless|skinny|fit|smart|cheat|sinful|naughty|superfood)\b/i;
  const ICONS = ["fork.knife", "cup.and.saucer", "takeoutbag.and.cup.and.straw"];
  const CHAIN_KEYS = ["id", "name", "icon", "sourceUrl", "retrievedOn"];
  const ITEM_KEYS = ["id", "chainId", "name", "servingLabel", "proteinG", "carbsG", "fatG"];
  const onlyKeys = (thing, keys) => Object.keys(thing).every((key) => keys.includes(key)) && keys.every((key) => key in thing);
  const chainIds = fastFood.chains.map((chain) => chain.id);
  for (const chain of fastFood.chains) {
    if (!onlyKeys(chain, CHAIN_KEYS)) fail(`fast-food: chain ${chain.id} must carry exactly ${CHAIN_KEYS.join(", ")} — no logo, no image, no rating, no rank`);
    if (!/^[a-z0-9-]+$/.test(chain.id) || typeof chain.name !== "string" || chain.name.length === 0) fail(`fast-food: chain ${chain.id} needs a kebab-case id and a name`);
    if (!ICONS.includes(chain.icon)) fail(`fast-food: chain ${chain.id} icon must be one of the neutral set (${ICONS.join(", ")})`);
    if (!/^https:\/\//.test(chain.sourceUrl) || !/^\d{4}-\d{2}-\d{2}$/.test(chain.retrievedOn)) fail(`fast-food: chain ${chain.id} needs an https sourceUrl and a retrievedOn date`);
    if (fastFood.items.filter((item) => item.chainId === chain.id).length < K("nutrition", "fastFoodItemsPerChainMin")) fail(`fast-food: chain ${chain.id} has fewer than ${K("nutrition", "fastFoodItemsPerChainMin")} items`);
  }
  if (new Set(chainIds).size !== chainIds.length) fail("fast-food: duplicate chain id");
  if (fastFood.chains.length !== K("nutrition", "fastFoodChainCount")) fail(`fast-food: ${fastFood.chains.length} chains, spec-constants says ${K("nutrition", "fastFoodChainCount")} — counts are stated honestly, in one place`);
  const itemIds = new Set();
  let previous = null;
  for (const item of fastFood.items) {
    if (!onlyKeys(item, ITEM_KEYS)) fail(`fast-food: item ${item.id} must carry exactly ${ITEM_KEYS.join(", ")}`);
    if (itemIds.has(item.id)) fail(`fast-food: duplicate item id ${item.id}`);
    itemIds.add(item.id);
    if (!chainIds.includes(item.chainId) || !String(item.id).startsWith(`${item.chainId}/`)) fail(`fast-food: item ${item.id} must belong to a listed chain and carry its id as a prefix`);
    for (const field of ["name", "servingLabel"]) {
      if (typeof item[field] !== "string" || item[field].length === 0) fail(`fast-food: item ${item.id} needs ${field}`);
      const hit = typeof item[field] === "string" ? item[field].match(QUALITY_WORDS) : null;
      if (hit) fail(`fast-food: item ${item.id}.${field} carries a quality word ("${hit[0]}") — no food is judged (clause ①)`);
    }
    if (String(item.name).length > K("nutrition", "savedMealNameMaxChars") + K("nutrition", "savedMealNameMaxChars")) fail(`fast-food: item ${item.id} name is unreasonably long`);
    for (const field of ["proteinG", "carbsG", "fatG"]) if (!Number.isInteger(item[field]) || item[field] < 0 || item[field] > K("nutrition", "macroGramsMaxPerEntry")) fail(`fast-food: item ${item.id}.${field} must be an integer 0–${K("nutrition", "macroGramsMaxPerEntry")}`);
    const order = [chainIds.indexOf(item.chainId), item.name];
    if (previous !== null && (order[0] < previous[0] || (order[0] === previous[0] && order[1] < previous[1]))) fail(`fast-food: item ${item.id} is out of order — items sort by chain, then by name (a sort is not a ranking)`);
    previous = order;
  }
  console.log(`fast-food.json: ${fastFood.chains.length} chains, ${fastFood.items.length} items — published facts only, no judgement words, no pictures`);
}

const countByType = seed.enums.type.map((type) => `${seed.exercises.filter((exercise) => exercise.type === type).length} ${type}`);
console.log(`exercises.json: ${seed.exercises.length} exercises (${countByType.join(", ")}) — gym-only, no home cues`);
console.log(`plan-templates.json: ${Object.keys(templates.templates).length} lists (${Object.entries(templates.templates).map(([kind, ids]) => `${kind} ${ids.length}`).join(" · ")}) — the owner's canonical templates (A26), sets by experience × ${K("planGeneration", "templateTargetReps")}; ${Object.keys(templates.namedSwaps ?? {}).length} rows with named swaps, all always offered`);
for (const problem of problems) console.log(`PROBLEM  ${problem}`);
if (problems.length > 0) { console.log(`check-seeds: ${problems.length} problem(s)`); process.exit(1); }
console.log("check-seeds: seeds are complete and consistent");
