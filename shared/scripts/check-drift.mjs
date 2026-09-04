// Exits 1 when any Generated file differs from what generate.mjs would write right now —
// either a hand edit under Generated/ or a shared/ change that was not regenerated.
// Run: node shared/scripts/check-drift.mjs
// SPEC: Part V 5.2 check-drift.mjs · 5.3 lint (no hand edits in Generated/) · CLAUDE.md rule 3

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { renderAll, repoRoot } from "./generate.mjs";

function normalizeLineEndings(text) {
  return text.replace(/\r\n/g, "\n");
}

function firstDifferingLine(expected, actual) {
  const expectedLines = expected.split("\n");
  const actualLines = actual.split("\n");
  const count = Math.max(expectedLines.length, actualLines.length);
  for (let index = 0; index < count; index += 1) {
    if (expectedLines[index] !== actualLines[index]) return index + 1;
  }
  return 0;
}

let drifted = 0;
for (const { path, content } of renderAll()) {
  const fullPath = join(repoRoot, path);
  if (!existsSync(fullPath)) {
    console.log(`MISSING  ${path}`);
    drifted += 1;
    continue;
  }
  const expected = normalizeLineEndings(content);
  const actual = normalizeLineEndings(readFileSync(fullPath, "utf8"));
  if (expected === actual) {
    console.log(`ok       ${path}`);
    continue;
  }
  console.log(`DRIFT    ${path}  (first difference at line ${firstDifferingLine(expected, actual)})`);
  drifted += 1;
}

if (drifted > 0) {
  console.log(`check-drift: ${drifted} file(s) drifted — run \`node shared/scripts/generate.mjs\`; never hand-edit Generated files.`);
  process.exit(1);
}
console.log("check-drift: all Generated files match shared/");
