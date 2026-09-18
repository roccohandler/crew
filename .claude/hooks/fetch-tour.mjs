// SPEC: Appendix A 2026-09-18 A24 (5) — AUTO-DELIVERY. A SessionStart hook (.claude/settings.json): finds the newest SUCCESSFUL `ci`
// run for the current branch that carries a `ui-tour` artifact and, when its run id differs from design/tour/latest/.run-id,
// replaces design/tour/latest/ with it. It then tells the session what it is looking at: run date, commit, the CHANGES.md summary.
// It must NEVER block or fail a session: offline, no runs, gh missing, a slow network — each one exits 0 with a one-line note, and
// the whole script gives up at 55 s (the hook's own timeout is 60).
// /ui-check reuses it with `--run <id>`: that run exactly, green or red, with plain-text output instead of the hook's JSON.
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const latestDir = join(root, "design", "tour", "latest");
const incomingDir = join(root, "design", "tour", ".incoming");
const runIdFile = join(latestDir, ".run-id");
const forcedRun = process.argv.includes("--run") ? process.argv[process.argv.indexOf("--run") + 1] : null;
const instruction = "Screenshots are in design/tour/latest/. View changed screens before any UI work.";

function finish(text) {
  if (forcedRun) console.log(text);
  else console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: text } }));
  process.exit(0);
}
setTimeout(() => finish("ui-tour: gave up after 55 s — design/tour/latest/ was left as it was."), 55_000).unref();
process.on("uncaughtException", (error) => finish(`ui-tour: not fetched (${String(error.message ?? error).split("\n")[0]}).`));

function run(command, args, timeoutMs) {
  return execFileSync(command, args, { cwd: root, encoding: "utf8", timeout: timeoutMs, stdio: ["ignore", "pipe", "pipe"], windowsHide: true }).trim();
}

// The part of CHANGES.md a session needs up front: the summary line and every changed / new / removed screen
function changesSummary() {
  const path = join(latestDir, "CHANGES.md");
  if (!existsSync(path)) return "CHANGES.md is missing from this tour.";
  const lines = readFileSync(path, "utf8").split("\n");
  const summary = lines.find((line) => line.startsWith("SUMMARY:")) ?? "SUMMARY: (none)";
  const wanted = [];
  let keep = false;
  for (const line of lines) {
    if (line.startsWith("## ")) keep = /^## (Changed \(|New|Removed)/.test(line);
    if (keep && (line.startsWith("## ") || (line.startsWith("- ") && line !== "- none"))) wanted.push(line.startsWith("## ") ? line.replace(/^## /, "").replace(/ \(.*$/, ":") : line);
  }
  const listed = wanted.filter((line, index) => line.startsWith("- ") || (wanted[index + 1] ?? "").startsWith("- "));
  return [summary, ...listed.slice(0, 40)].join("\n");
}

function findRun(branch) {
  if (forcedRun) return JSON.parse(run("gh", ["run", "view", forcedRun, "--json", "databaseId,headSha,createdAt,conclusion"], 20_000));
  const runs = JSON.parse(run("gh", ["run", "list", "--workflow", "ci.yml", "--branch", branch, "--status", "success", "--limit", "8", "--json", "databaseId,headSha,createdAt,conclusion"], 20_000));
  for (const candidate of runs) { // a branch run whose UI did not move has no ios job, so no artifact: take the newest run that has one
    const names = run("gh", ["api", `repos/{owner}/{repo}/actions/runs/${candidate.databaseId}/artifacts`, "--jq", ".artifacts[] | select(.expired == false) | .name"], 15_000);
    if (names.split("\n").includes("ui-tour")) return candidate;
  }
  return null;
}

const branch = run("git", ["rev-parse", "--abbrev-ref", "HEAD"], 5_000);
const found = findRun(branch);
if (!found) finish(`ui-tour: no successful ci run with a ui-tour artifact on ${branch} yet — nothing fetched.`);

const runId = String(found.databaseId);
const have = existsSync(runIdFile) ? readFileSync(runIdFile, "utf8").trim() : "";
let fetched = "already in design/tour/latest/";
if (have !== runId) {
  rmSync(incomingDir, { recursive: true, force: true });
  mkdirSync(incomingDir, { recursive: true });
  run("gh", ["run", "download", runId, "--name", "ui-tour", "--dir", incomingDir], 45_000);
  writeFileSync(join(incomingDir, ".run-id"), `${runId}\n`);
  rmSync(latestDir, { recursive: true, force: true }); // the old tour goes only once the new one is whole
  renameSync(incomingDir, latestDir);
  fetched = "downloaded just now";
}
finish(`UI tour — ci run ${runId} (${found.conclusion}) · ${found.createdAt} · commit ${String(found.headSha).slice(0, 7)} · branch ${branch} · ${fetched}.\n${changesSummary()}\n${instruction}`);
