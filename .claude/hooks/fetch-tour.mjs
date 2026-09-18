// SPEC: Appendix A 2026-09-18 A24 (5) — AUTO-DELIVERY of the `ui-tour` artifact (tour shots · TOUR.md · CHANGES.md) from GitHub to disk.
// Three ways in, one download routine:
//   (no flag)   the SessionStart hook (.claude/settings.json): the newest SUCCESSFUL `ci` run with a `ui-tour` artifact for the CURRENT
//               branch; prints hookSpecificOutput.additionalContext (run date, commit, CHANGES.md summary). It must NEVER block or fail a
//               session: offline, no runs, gh missing — each exits 0 with a one-line note. The download gets 40 s in the foreground (the
//               12 MB artifact took 90 s on the owner's line, 2026-09-18); past that the same script finishes it detached.
//   --run <id>  /ui-check: that run exactly, green or red, plain-text output, no deadline.
//   --sync      the owner's scheduled task (every 10 min, no Claude session needed): EVERY branch with a newer tour, no deadline.
// WHERE IT LANDS. By default design/tour/latest/ (git-ignored). When the machine sets CREW_TOUR_DIR — the owner's is a OneDrive folder —
// each branch gets its own folder there: <CREW_TOUR_DIR>/<branch>/, so the sync task and a session never overwrite one another.
import { execFileSync, spawn } from "node:child_process";
import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const flag = (name) => (process.argv.includes(name) ? process.argv[process.argv.indexOf(name) + 1] ?? "" : null);
const forcedRun = flag("--run");
const syncAll = process.argv.includes("--sync");
const background = process.argv.includes("--background"); // the detached second attempt of the hook: no deadline, no output
const asHook = !forcedRun && !syncAll && !background;
const tourRoot = (process.env.CREW_TOUR_DIR ?? "").trim();
const tourDir = (branch) => (tourRoot ? join(tourRoot, branch.replace(/[^\w.-]+/g, "_")) : join(root, "design", "tour", "latest"));

function finish(text) {
  if (asHook) console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: text } }));
  else console.log(text);
  process.exit(0);
}
if (asHook) setTimeout(() => finish("ui-tour: gave up after 55 s — the tour folder was left as it was."), 55_000).unref();
process.on("uncaughtException", (error) => finish(`ui-tour: not fetched (${String(error.message ?? error).split("\n")[0]}).`));

function run(command, args, timeoutMs) {
  return execFileSync(command, args, { cwd: root, encoding: "utf8", timeout: timeoutMs, stdio: ["ignore", "pipe", "pipe"], windowsHide: true }).trim();
}

// The part of CHANGES.md a session needs up front: the summary line and every changed / new / removed screen
function changesSummary(dir) {
  const path = join(dir, "CHANGES.md");
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

const hasTour = (runId) => run("gh", ["api", `repos/{owner}/{repo}/actions/runs/${runId}/artifacts`, "--jq", ".artifacts[] | select(.expired == false) | .name"], 15_000).split("\n").includes("ui-tour");
const runFields = "databaseId,headSha,headBranch,createdAt,conclusion";

// The newest successful run on the branch that carries the artifact (a branch run whose UI did not move has no ios job, so none)
function newestTour(branch) {
  const runs = JSON.parse(run("gh", ["run", "list", "--workflow", "ci.yml", "--branch", branch, "--status", "success", "--limit", "8", "--json", runFields], 20_000));
  return runs.find((candidate) => hasTour(candidate.databaseId)) ?? null;
}

// Replaces the folder's CONTENTS, never the folder: an Explorer window (or OneDrive) holding it open keeps working. The old tour goes
// only once the new one is whole. → "downloaded" | "current" | "busy"
function deliver(found, downloadTimeoutMs) {
  const dir = tourDir(found.headBranch);
  const runId = String(found.databaseId);
  const have = existsSync(join(dir, ".run-id")) ? readFileSync(join(dir, ".run-id"), "utf8").trim() : "";
  if (have === runId) return "current";
  const incoming = `${dir}.incoming`;
  if (existsSync(incoming) && Date.now() - statSync(incoming).mtimeMs < 10 * 60_000) return "busy"; // another fetch is mid-download
  rmSync(incoming, { recursive: true, force: true, maxRetries: 5, retryDelay: 300 });
  mkdirSync(incoming, { recursive: true });
  run("gh", ["run", "download", runId, "--name", "ui-tour", "--dir", incoming], downloadTimeoutMs);
  writeFileSync(join(incoming, ".run-id"), `${runId}\n`);
  writeFileSync(join(incoming, "_SOURCE.txt"), `branch ${found.headBranch}\ncommit ${found.headSha}\nci run ${runId} (${found.conclusion}) · ${found.createdAt}\nhttps://github.com/${run("gh", ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], 15_000)}/actions/runs/${runId}\n`);
  mkdirSync(dir, { recursive: true });
  for (const entry of readdirSync(dir)) rmSync(join(dir, entry), { recursive: true, force: true, maxRetries: 5, retryDelay: 300 });
  cpSync(incoming, dir, { recursive: true });
  rmSync(incoming, { recursive: true, force: true, maxRetries: 5, retryDelay: 300 });
  return "downloaded";
}

const describe = (found, state) => `UI tour — ci run ${found.databaseId} (${found.conclusion}) · ${found.createdAt} · commit ${String(found.headSha).slice(0, 7)} · branch ${found.headBranch} · ${state === "downloaded" ? "downloaded just now" : state === "busy" ? "another fetch is downloading it right now" : "already on disk"}.`;

if (syncAll) {
  // Every branch that ran a tour lately: the newest successful run per branch, newest first
  const recent = JSON.parse(run("gh", ["run", "list", "--workflow", "ci.yml", "--status", "success", "--limit", "30", "--json", runFields], 30_000));
  const lines = [];
  for (const branch of [...new Set(recent.map((candidate) => candidate.headBranch))]) {
    const found = recent.filter((candidate) => candidate.headBranch === branch).find((candidate) => hasTour(candidate.databaseId));
    if (found) lines.push(describe(found, deliver(found, 600_000)));
  }
  if (tourRoot) writeFileSync(join(tourRoot, "_last-sync.txt"), `${new Date().toISOString()}\n${lines.join("\n") || "no tours found"}\n`);
  finish(lines.join("\n") || "ui-tour: no successful ci run with a ui-tour artifact yet.");
}

const branch = flag("--branch") || run("git", ["rev-parse", "--abbrev-ref", "HEAD"], 5_000);
const found = forcedRun ? JSON.parse(run("gh", ["run", "view", forcedRun, "--json", runFields], 20_000)) : newestTour(branch);
if (!found) finish(`ui-tour: no successful ci run with a ui-tour artifact on ${branch} yet — nothing fetched.`);
const dir = tourDir(found.headBranch);
const instruction = `Screenshots are in ${tourRoot ? dir : "design/tour/latest/"}. View changed screens before any UI work.`;
let state;
try {
  state = deliver(found, asHook ? 40_000 : 600_000);
} catch (error) {
  if (!asHook) throw error;
  rmSync(`${dir}.incoming`, { recursive: true, force: true, maxRetries: 5, retryDelay: 300 }); // the killed download's half — or the detached attempt reads it as "busy"
  spawn(process.execPath, [fileURLToPath(import.meta.url), "--background", "--branch", branch], { cwd: root, detached: true, stdio: "ignore", windowsHide: true }).unref();
  finish(`UI tour — ci run ${found.databaseId} · ${found.createdAt} · commit ${String(found.headSha).slice(0, 7)} · branch ${branch}: the download did not finish in 40 s and is continuing in the background; the folder updates in a minute or two — read its CHANGES.md then. ${instruction}`);
}
finish(`${describe(found, state)}\n${changesSummary(dir)}\n${instruction}`);
