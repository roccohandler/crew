// SPEC: A6 — the Journal's rows, pure and server-only: one readable line per post (workout / cardio = the summary the server
// wrote at completion, else the same line computed from the session; meal = "{Breakfast|Lunch|Dinner|Snack} · {time}" in the
// user's zone), a day's "Rest day" tag, and the days newest first. The page renders; this file decides the words.
import type { SessionDoc } from "@/lib/documents";
import type { PostDoc } from "@/lib/documents-social";
import { completionFacts } from "@/lib/engine/completion";
import { isoWeekday, weekKeyFor } from "@/lib/engine/day-key";
import { sessionSummaryLine } from "@/lib/engine/session-summary-line";
import { TimeUnits } from "@/lib/time-units";

const mealNames = { breakfast: "Breakfast", lunch: "Lunch", dinner: "Dinner", snack: "Snack" } as const;

// "4:31 PM" on the poster's clock (Intl carries the zone; the app ships in English)
export function clockTime(instant: Date, timeZone: string): string {
  return new Intl.DateTimeFormat("en-US", { timeZone, hour: "numeric", minute: "2-digit" }).format(instant);
}

// SPEC: A6 — a workout post without a server summary (pre-A6) reads the same line computed from its session: sets from the
// completion facts (V32: warm-ups excluded), wall-clock minutes rounded like the server's
export function summaryFromSession(session: SessionDoc, distanceUnit: string): string {
  const facts = completionFacts(session.exercises.flatMap((exercise) => exercise.sets));
  const minutes = session.completedAt ? Math.round((session.completedAt.getTime() - session.startedAt.getTime()) / TimeUnits.msPerMinute) : 0;
  return sessionSummaryLine(session.workoutName, session.workoutKind === "cardio", facts.setsDone, facts.setsPlanned, minutes, null, null, distanceUnit);
}

// SPEC: A6 — workout: "{summary}"; meal: "{Meal} · {time}" (+ " · earlier today" for a same-day backfill, Flow 4; the same
// backfill read on a later day says "earlier that day"); a caption-less, tag-less plate is still "Meal · {time}"
export function postLine(post: PostDoc, timeZone: string, sessionLine: string | null, isToday: boolean): string {
  // A14: workout and cardio are two row types now; both read the server summary the completion wrote ("Push day · 12/12
  // sets · 44 min" / "Walk · 25 min · 2.1 km"), so the words do not change — only which count each falls into.
  if (post.type === "workout") return post.summary ?? sessionLine ?? "Workout ✓";
  if (post.type === "cardio") return post.summary ?? sessionLine ?? "Cardio ✓";
  const meal = post.mealTag ? mealNames[post.mealTag] : "Meal";
  const backfill = post.earlierToday ? (isToday ? " · earlier today" : " · earlier that day") : "";
  return `${meal} · ${clockTime(post.createdAt, timeZone)}${backfill}`;
}

// SPEC: A6 — "Rest day" tags a day that was not a training day and holds no workout (A1: rest = weekday ∉ trainingWeekdays)
// A14: cardio counts here exactly as it did when it WAS a "workout" post — a day you walked is not tagged "Rest day".
// The tag describes what you did, not what the plan scheduled, and this keeps the pre-A14 reading byte-identical.
export function isRestDay(dayKey: string, dayPosts: PostDoc[], trainingWeekdays: number[]): boolean {
  return !trainingWeekdays.includes(isoWeekday(dayKey)) && !dayPosts.some((post) => post.type === "workout" || post.type === "cardio");
}

// The days that hold posts, newest first (a backfilled post sorts by its dayKey, not by when it was written)
export function dayKeysOf(docs: PostDoc[]): string[] {
  return [...new Set(docs.map((post) => post.dayKey))].sort((left, right) => right.localeCompare(left));
}

// SPEC: A6 — the days grouped under their week (weekHeader names it: This week · Last week · Week of Sep 1), newest first
export function weeksOf(dayKeys: string[]): { weekKey: string; dayKeys: string[] }[] {
  const weeks: { weekKey: string; dayKeys: string[] }[] = [];
  for (const dayKey of dayKeys) {
    const weekKey = weekKeyFor(dayKey);
    const last = weeks[weeks.length - 1];
    if (last && last.weekKey === weekKey) last.dayKeys.push(dayKey); else weeks.push({ weekKey, dayKeys: [dayKey] });
  }
  return weeks;
}
