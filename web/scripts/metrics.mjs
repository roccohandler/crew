// SPEC: Part IV success targets (≥50% install→first post same day · ≥30% D7 retention · ≥4 posts/user/week · crew retention
// ≥1.5× solo · streak health watched, not targeted) · Part IV "first-party analytics" (events in our DB) · T045 "metrics live" ·
// XII Beta: the owner reads these weekly. Run: `node scripts/metrics.mjs [from] [to]` (YYYY-MM-DD, UTC; default = the last 7
// days) against MONGODB_URI / MONGODB_DB. Plain driver, plain functions; the numbers come from shared/spec-constants.json.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { MongoClient } from "mongodb";

const here = dirname(fileURLToPath(import.meta.url));
const constants = JSON.parse(readFileSync(join(here, "..", "..", "shared", "spec-constants.json"), "utf8"));
const targets = constants.successTargets;
const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_DAYS = 7;
const RETENTION_DAY = 7;

const utcDay = (date) => date.toISOString().slice(0, 10);
const addDays = (day, days) => utcDay(new Date(new Date(`${day}T00:00:00Z`).getTime() + days * DAY_MS));
const pct = (part, whole) => (whole === 0 ? null : Math.round((part / whole) * 1000) / 10);

// GAP (agent, 2026-09-05): Part IV names the metrics, not their exact denominators — these are the plainest readings:
// install = account_created; "same day" = the user's own dayKey of signup (the 3 AM rule, their zone); D7 = any post on or after
// calendar day 7 after signup; posts/user/week over users who posted at least once in the window; crew vs solo = D7 of users
// with a crew membership ÷ D7 of users without one. Crash-free needs device crash reports and is not instrumented here.
export async function computeMetrics(db, { from, to }) {
  const users = await db.collection("users").find({ createdAt: { $gte: new Date(`${from}T00:00:00Z`), $lte: new Date(`${to}T23:59:59.999Z`) } }).toArray();
  const userIds = users.map((user) => user._id);
  const posts = await db.collection("posts").find({ deletedAt: null, $or: [{ userId: { $in: userIds } }, { dayKey: { $gte: from, $lte: to } }] }).toArray();
  const memberIds = new Set((await db.collection("crewMemberships").find({ userId: { $in: userIds } }).toArray()).map((doc) => doc.userId.toHexString()));
  const postsBy = new Map();
  for (const post of posts) {
    const key = post.userId.toHexString();
    postsBy.set(key, [...(postsBy.get(key) ?? []), post.dayKey]);
  }
  const signupDay = (user) => new Intl.DateTimeFormat("en-CA", { timeZone: user.timezone || "UTC", year: "numeric", month: "2-digit", day: "2-digit" }).format(user.createdAt);
  const sameDay = users.filter((user) => (postsBy.get(user._id.toHexString()) ?? []).some((day) => day === signupDay(user)));
  const eligible = users.filter((user) => addDays(signupDay(user), RETENTION_DAY) <= to);
  const retained = (user) => (postsBy.get(user._id.toHexString()) ?? []).some((day) => day >= addDays(signupDay(user), RETENTION_DAY));
  const inCrew = eligible.filter((user) => memberIds.has(user._id.toHexString()));
  const solo = eligible.filter((user) => !memberIds.has(user._id.toHexString()));
  const windowPosts = posts.filter((post) => post.dayKey >= from && post.dayKey <= to);
  const posters = new Set(windowPosts.map((post) => post.userId.toHexString()));
  const weeks = (Math.round((new Date(`${to}T00:00:00Z`).getTime() - new Date(`${from}T00:00:00Z`).getTime()) / DAY_MS) + 1) / WEEK_DAYS;
  const crewD7 = pct(inCrew.filter(retained).length, inCrew.length);
  const soloD7 = pct(solo.filter(retained).length, solo.length);
  return {
    window: { from, to },
    signups: users.length,
    installToFirstPostSameDayPct: pct(sameDay.length, users.length),
    d7RetentionPct: pct(eligible.filter(retained).length, eligible.length),
    postsPerUserPerWeek: posters.size === 0 ? null : Math.round((windowPosts.length / posters.size / weeks) * 100) / 100,
    crewVsSoloRetentionMultiplier: crewD7 === null || soloD7 === null || soloD7 === 0 ? null : Math.round((crewD7 / soloD7) * 100) / 100,
    crashFreePct: null,
    targets: {
      installToFirstPostSameDayPct: targets.targetInstallToFirstPostSameDayPct.value,
      d7RetentionPct: targets.targetD7RetentionPct.value,
      postsPerUserPerWeek: targets.targetPostsPerUserPerWeek.value,
      crewVsSoloRetentionMultiplier: targets.targetCrewVsSoloRetentionMultiplier.value,
      crashFreePct: targets.targetCrashFreePct.value,
    },
  };
}

export function formatReport(report) {
  const line = (label, value, target, unit = "") => `${label.padEnd(34)} ${value === null ? "n/a" : `${value}${unit}`}`.padEnd(48) + `target ${target}${unit}` + (value === null ? "" : value >= target ? "  ✓" : "  ✗");
  return [
    `Crew metrics ${report.window.from} → ${report.window.to} · ${report.signups} signups`,
    line("install → first post same day", report.installToFirstPostSameDayPct, report.targets.installToFirstPostSameDayPct, "%"),
    line("D7 retention", report.d7RetentionPct, report.targets.d7RetentionPct, "%"),
    line("posts / user / week", report.postsPerUserPerWeek, report.targets.postsPerUserPerWeek),
    line("crew ÷ solo D7 retention", report.crewVsSoloRetentionMultiplier, report.targets.crewVsSoloRetentionMultiplier, "×"),
    line("crash-free (needs device reports)", report.crashFreePct, report.targets.crashFreePct, "%"),
  ].join("\n");
}

const isMain = process.argv[1] !== undefined && fileURLToPath(import.meta.url) === process.argv[1];
if (isMain) {
  const to = process.argv[3] ?? utcDay(new Date());
  const from = process.argv[2] ?? addDays(to, -(WEEK_DAYS - 1));
  const client = new MongoClient(process.env.MONGODB_URI ?? "mongodb://127.0.0.1:27017");
  await client.connect();
  try {
    console.log(formatReport(await computeMetrics(client.db(process.env.MONGODB_DB ?? "crew"), { from, to })));
  } finally {
    await client.close();
  }
}
