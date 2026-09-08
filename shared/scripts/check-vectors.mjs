// Validates shared/vectors/*.vectors.json against the fixture contract in shared/vectors/README.md:
// file shape, unique ids, V01–V50 (+V18b) coverage, the per-kind shape checks in vector-shapes.mjs and
// the arithmetic invariants in vector-invariants.mjs. Exits 1 on any problem.
// Run: node shared/scripts/check-vectors.mjs
// SPEC: Part XI T003 (Verify: JSON schema check) · 8.1 (append-only; both engines must match EXACTLY)

import { readdirSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { shapeChecks } from "./vector-shapes.mjs";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const vectorsDir = join(repoRoot, "shared", "vectors");
const REQUIRED_IDS = [...Array.from({ length: 50 }, (_, index) => `V${String(index + 1).padStart(2, "0")}`), "V18b"]; // V41–V44 (S02) · V45–V50 achievements (2026-09-04)
const problems = [];
const fail = (id, message) => problems.push(`${id}: ${message}`);

const seen = new Map();
let total = 0;
const files = readdirSync(vectorsDir).filter((name) => name.endsWith(".vectors.json")).sort();
for (const file of files) {
  const doc = JSON.parse(readFileSync(join(vectorsDir, file), "utf8"));
  if (doc.file !== file || typeof doc.spec !== "string" || !Array.isArray(doc.vectors)) fail(file, "needs file (its own name), spec, vectors[]");
  for (const vector of doc.vectors ?? []) {
    total += 1;
    if (typeof vector.id !== "string" || !/^V\d{2}[a-z]?$/.test(vector.id)) fail(file, `bad id ${vector.id}`);
    if (seen.has(vector.id)) fail(vector.id, `duplicate id (also in ${seen.get(vector.id)})`);
    seen.set(vector.id, file);
    for (const field of ["title", "spec", "kind", "rule"]) if (typeof vector[field] !== "string") fail(vector.id, `missing ${field}`);
    if (shapeChecks[vector.kind]) shapeChecks[vector.kind](vector, fail);
    else fail(vector.id, `unknown kind ${vector.kind}`);
  }
  console.log(`${file}: ${(doc.vectors ?? []).map((vector) => vector.id).join(" ")}`);
}
for (const id of REQUIRED_IDS) if (!seen.has(id)) fail(id, "required vector is missing");

for (const problem of problems) console.log(`PROBLEM  ${problem}`);
if (problems.length > 0) {
  console.log(`check-vectors: ${problems.length} problem(s)`);
  process.exit(1);
}
console.log(`check-vectors: ${total} vectors across ${files.length} files — shape and invariants hold`);
