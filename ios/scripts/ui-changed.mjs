// SPEC: Appendix A 2026-09-18 A24 (3) — decides whether this ci run pays for the macOS job. master, main, a pull request and a manual
// dispatch always do (as before A24, plus the dispatch). A push to any OTHER branch does only when it touches what the iPhone
// renders — so a scratch branch gets a tour when its UI moved and costs one minute of Linux when it did not.
// Writes run_ios=true|false to $GITHUB_OUTPUT. Usage (ci.yml, contracts job): node ios/scripts/ui-changed.mjs <before-sha>
import { execFileSync } from "node:child_process";
import { appendFileSync } from "node:fs";

const uiPaths = [/^ios\/Crew\/Features\//, /^ios\/Crew\/Shared\//, /^ios\/Crew\/RootView\.swift$/, /^ios\/Crew\/CrewApp\.swift$/, /^ios\/Crew\/Generated\/Ember/, /^ios\/Crew\/Assets\.xcassets\//, /^ios\/CrewUITests\//, /^ios\/scripts\/(storyboard|tour-diff)\.mjs$/, /^shared\/design-tokens\.json$/, /^design\/baselines\//];

const event = process.env.GITHUB_EVENT_NAME ?? "";
const branch = process.env.GITHUB_REF_NAME ?? "";
const before = process.argv[2] ?? "";

function git(args) {
  try { return execFileSync("git", args, { encoding: "utf8" }); } catch { return null; }
}

function changedFiles() {
  const known = /^[0-9a-f]{40}$/.test(before) && !/^0+$/.test(before) && git(["cat-file", "-e", `${before}^{commit}`]) !== null;
  const listed = known ? git(["diff", "--name-only", before, "HEAD"]) : git(["diff", "--name-only", "origin/master...HEAD"]); // a new branch: everything it adds to master
  return listed === null ? null : listed.split("\n").filter(Boolean);
}

let runIos = true;
let why = `${event} on ${branch} — the ios job always runs`;
if (event === "push" && branch !== "master" && branch !== "main") {
  const files = changedFiles();
  const hits = files === null ? [] : files.filter((file) => uiPaths.some((pattern) => pattern.test(file)));
  runIos = files === null || hits.length > 0; // a diff that cannot be read runs the tour rather than hiding a change
  why = files === null ? "the push could not be diffed — running the tour to be safe" : hits.length > 0 ? `UI paths changed: ${hits.slice(0, 5).join(", ")}${hits.length > 5 ? " …" : ""}` : `no UI path among ${files.length} changed file(s) — no tour`;
}
console.log(`ui-changed: run_ios=${runIos} (${why})`);
if (process.env.GITHUB_OUTPUT) appendFileSync(process.env.GITHUB_OUTPUT, `run_ios=${runIos}\n`);
