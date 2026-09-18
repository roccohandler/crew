// SPEC: Appendix A 2026-09-18 A24 (5) — /approve-screens. Copies the named tour shots (or "all") from design/tour/latest/ into
// design/baselines/ and commits ONLY those files as "Approve baselines: <list>". A name matches a shot when it equals the file
// name, with or without its NN_ step prefix and .png ("plan_editor_filled", "03_plan_editor_filled.png"), or its full
// "<tour class>/<file>" path. "all" also deletes baselines the latest tour no longer produces, so the folder mirrors the tour.
// Usage: node .claude/skills/approve-screens/approve.mjs all | <name> [<name> …]        (add --no-commit to stage without committing)
import { execFileSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readdirSync, rmSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..", "..");
const latestDir = join(root, "design", "tour", "latest");
const baselinesDir = join(root, "design", "baselines");
const names = process.argv.slice(2).filter((arg) => !arg.startsWith("--"));
const commit = !process.argv.includes("--no-commit");

function shotsIn(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).filter((entry) => /^tour/i.test(entry) && statSync(join(dir, entry)).isDirectory())
    .flatMap((tourClass) => readdirSync(join(dir, tourClass)).filter((file) => file.toLowerCase().endsWith(".png")).map((file) => `${tourClass}/${file}`)).sort();
}

const bare = (shot) => shot.split("/")[1].replace(/\.png$/i, "").replace(/^\d{2}_/, "");
const available = shotsIn(latestDir);
if (names.length === 0) { console.error("approve-screens: name the screens to approve, or say all."); process.exit(2); }
if (available.length === 0) { console.error("approve-screens: design/tour/latest/ holds no tour — run /ui-check (or start a session so the fetch hook runs) first."); process.exit(1); }

const everything = names.length === 1 && names[0].toLowerCase() === "all";
const chosen = [];
const unknown = [];
for (const name of everything ? [] : names) {
  const wanted = name.replace(/\\/g, "/").replace(/\.png$/i, "");
  const hits = available.filter((shot) => shot.replace(/\.png$/i, "") === wanted || shot.split("/")[1].replace(/\.png$/i, "") === wanted || bare(shot) === wanted.replace(/^\d{2}_/, ""));
  if (hits.length === 0) unknown.push(name); else chosen.push(...hits);
}
if (unknown.length > 0) { console.error(`approve-screens: not in design/tour/latest/: ${unknown.join(", ")}\nAvailable: ${available.map(bare).join(", ")}`); process.exit(1); }

const approved = everything ? available : [...new Set(chosen)];
const paths = [];
for (const shot of approved) {
  mkdirSync(join(baselinesDir, shot.split("/")[0]), { recursive: true });
  copyFileSync(join(latestDir, shot), join(baselinesDir, shot));
  paths.push(`design/baselines/${shot}`);
}
if (everything) {
  for (const stale of shotsIn(baselinesDir).filter((shot) => !available.includes(shot))) {
    rmSync(join(baselinesDir, stale));
    paths.push(`design/baselines/${stale}`);
  }
}

const git = (args) => execFileSync("git", args, { cwd: root, encoding: "utf8" });
git(["add", "-A", "--", ...paths]);
const staged = git(["diff", "--cached", "--name-only", "--", "design/baselines"]).split("\n").filter(Boolean);
if (staged.length === 0) { console.log("approve-screens: the baselines already match — nothing to commit."); process.exit(0); }
const list = everything ? `all (${approved.length} screens)` : approved.map(bare).join(", ");
if (commit) git(["commit", "-m", `Approve baselines: ${list}`, "--", ...paths]);
console.log(`approve-screens: ${staged.length} file(s) ${commit ? "committed" : "staged"} — Approve baselines: ${list}`);
