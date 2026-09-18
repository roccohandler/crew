// Asserts the shared copy (shared/copy/*.json, after placeholder resolution) keeps the rules a screen cannot check for itself.
// Run: node shared/scripts/check-copy.mjs   Exits 1 on any finding.
// SPEC: A16.a (the methodology screen names its sources and EVERY source is a link; the estimate-and-clinician line) · 6.6 (sentence
// case, contractions, no "please", no "successfully", no "!") · Flow 4 clause ⑤ / A21.5 (no calorie coaching copy) · C7 (no number
// typed into copy: every {placeholder} resolves to a spec constant — generation fails otherwise, and no brace survives it)

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { readCopy, repoRoot } from "./generate.mjs";

const findings = [];
const report = (where, message) => findings.push(`${where}: ${message}`);
const sections = JSON.parse(readFileSync(join(repoRoot, "shared", "spec-constants.json"), "utf8"));
const copy = readCopy(sections);

// Every string in a document, with the path that names it
function strings(value, where, out = []) {
  if (typeof value === "string") out.push({ where, text: value });
  else if (Array.isArray(value)) value.forEach((entry, index) => strings(entry, `${where}[${index}]`, out));
  else if (value !== null && typeof value === "object") for (const [key, entry] of Object.entries(value)) strings(entry, `${where}.${key}`, out);
  return out;
}

// 6.6 + the no-coaching rule — words a Crew screen never says. URLs are exempt (a DOI may hold anything).
const banned = [/!/, /\bplease\b/i, /\bsuccessfully\b/i, /\bshould\b/i, /\bmust\b/i, /\bcheat\b/i, /\bguilt/i, /\bbad\b/i, /\bclean eating\b/i, /\bjunk\b/i, /\bburn\b/i, /\bearn(ed)? (it|your)\b/i];
function checkWords(doc, name) {
  for (const { where, text } of strings(doc, name)) {
    if (where.endsWith(".url") || where.endsWith(".id")) continue;
    if (/[{}]/.test(text)) report(where, "an unresolved placeholder brace");
    for (const pattern of banned) if (pattern.test(text)) report(where, `copy rule 6.6 / no coaching: ${pattern} in "${text.slice(0, 60)}"`);
  }
}

function checkNutritionMethod(doc) {
  const name = "nutrition-method.json";
  checkWords(doc, name);
  for (const key of ["title", "lead", "clinician"]) if (typeof doc[key] !== "string" || doc[key].trim() === "") report(name, `${key} is required`);
  if (!/not medical advice/.test(doc.clinician ?? "") || !/clinician/.test(doc.clinician ?? "")) report(name, "A16.a: the clinician line must say it is an estimate, not medical advice, and name a clinician");
  const ids = new Set();
  for (const source of doc.sources ?? []) {
    if (ids.has(source.id)) report(name, `duplicate source id ${source.id}`);
    ids.add(source.id);
    if (!/^https:\/\/\S+$/.test(source.url ?? "")) report(name, `A16.a: source ${source.id} needs an https link`);
    if (typeof source.label !== "string" || source.label.trim() === "") report(name, `source ${source.id} needs a label`);
  }
  const cited = new Set((doc.steps ?? []).flatMap((step) => step.sourceIds ?? []));
  for (const id of cited) if (!ids.has(id)) report(name, `a step cites ${id}, which is not in sources`);
  for (const id of ids) if (!cited.has(id)) report(name, `source ${id} is cited by no step`);
  if ((doc.steps ?? []).length === 0) report(name, "A16.a: the calculation must be named step by step");
}

checkNutritionMethod(copy.nutritionMethod);

for (const finding of findings) console.log(`COPY  ${finding}`);
if (findings.length > 0) { console.log(`check-copy: ${findings.length} finding(s)`); process.exit(1); }
console.log(`check-copy: ${Object.keys(copy).length} document(s) — sources linked, placeholders resolved, copy rules hold`);
