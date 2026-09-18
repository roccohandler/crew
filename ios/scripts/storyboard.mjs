// Turns `xcrun xcresulttool export attachments --output-path <raw>` into a STORYBOARD the agent can read from any machine:
//   storyboard/<TestClass>/NN-<slug>.png   one file per journey step, numbered in the order the test took them
//   storyboard/index.md                     test · step · screen · action · file — one row per shot, grouped by test
// The attachment names come from CrewUITests/Screenshots.swift ("NN-<screen> — <action>"); the manifest comes from Xcode 16+'s
// exporter (an array of { testIdentifier, attachments: [{ exportedFileName, suggestedHumanReadableName, … }] } — or, on an older
// exporter, a flat array of attachments). Anything it cannot parse still lands in the storyboard under its raw name, so a
// manifest change never hides a picture. Owner order 2026-09-18, item 1. Usage: node ios/scripts/storyboard.mjs <raw> <out>
import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { basename, extname, join } from "node:path";

const [rawDir, outDir] = process.argv.slice(2);
if (!rawDir || !outDir) {
  console.error("usage: node ios/scripts/storyboard.mjs <exported-attachments-dir> <storyboard-dir>");
  process.exit(2);
}

function slug(text) {
  return text.normalize("NFKD").replace(/[^\w\s-]/g, "").trim().replace(/\s+/g, "-").replace(/-+/g, "-").toLowerCase() || "shot";
}

// The exporter names a file "<attachment name>_<index>_<UUID>.png"; the storyboard wants the attachment name alone
function cleanName(name) {
  return name.replace(/\.(png|jpe?g|heic)$/i, "").replace(/_\d+_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, "");
}

// "03-S04 the week, built" → { step: "03", screen: "S04", action: "the week, built" }; "S07 Home — rest day" → screen "S07 Home", action "rest day"
function parseName(raw) {
  const name = cleanName(raw);
  const numbered = /^(\d{2})-(.*)$/.exec(name);
  const step = numbered ? numbered[1] : "";
  const rest = numbered ? numbered[2] : name;
  const dash = rest.split(" — ");
  if (dash.length >= 2) return { step, screen: dash[0].trim(), action: dash.slice(1).join(" — ").trim() };
  const screenToken = /^(S\d{2}[^\s]*|1D|1C)\s+(.*)$/.exec(rest);
  if (screenToken) return { step, screen: screenToken[1], action: screenToken[2].trim() };
  return { step, screen: "", action: rest.trim() };
}

function readManifest(dir) {
  const manifestPath = join(dir, "manifest.json");
  if (!existsSync(manifestPath)) return [];
  const parsed = JSON.parse(readFileSync(manifestPath, "utf8"));
  const groups = Array.isArray(parsed) ? parsed : [parsed];
  const rows = [];
  for (const group of groups) {
    const test = group.testIdentifier ?? group.test ?? "";
    const attachments = Array.isArray(group.attachments) ? group.attachments : (group.exportedFileName ? [group] : []);
    for (const attachment of attachments) {
      rows.push({ test: attachment.testIdentifier ?? test, file: attachment.exportedFileName ?? "", name: attachment.suggestedHumanReadableName ?? attachment.exportedFileName ?? "" });
    }
  }
  return rows;
}

const manifest = readManifest(rawDir);
const files = existsSync(rawDir) ? readdirSync(rawDir).filter((file) => file !== "manifest.json") : [];
const rows = (manifest.length > 0 ? manifest : files.map((file) => ({ test: "", file, name: basename(file, extname(file)) })))
  .map((row) => ({ ...row, parsed: parseName(row.name) }))
  .sort((a, b) => a.test.localeCompare(b.test) || a.parsed.step.localeCompare(b.parsed.step) || a.name.localeCompare(b.name)); // a test's steps in the order taken

mkdirSync(outDir, { recursive: true });
const lines = ["# Storyboard — every journey step, in the order it was taken", "", "| Test | Step | Screen | Action | File |", "|---|---|---|---|---|"];
let copied = 0;
for (const row of rows) {
  const source = join(rawDir, row.file);
  if (!row.file || !existsSync(source)) continue;
  const testClass = (row.test.split("/")[0] || "unknown").replace(/\(\)$/, "");
  const { step, screen, action } = row.parsed;
  const ext = extname(row.file) || ".png";
  const fileName = `${step ? `${step}-` : ""}${slug(`${screen} ${action}`)}${ext}`;
  const dir = join(outDir, slug(testClass));
  mkdirSync(dir, { recursive: true });
  copyFileSync(source, join(dir, fileName));
  lines.push(`| ${row.test || "—"} | ${step || "—"} | ${screen || "—"} | ${action} | ${slug(testClass)}/${fileName} |`);
  copied += 1;
}
writeFileSync(join(outDir, "index.md"), `${lines.join("\n")}\n`);
console.log(`storyboard: ${copied} shot(s) from ${rows.length} manifest row(s) → ${outDir}/index.md`);
