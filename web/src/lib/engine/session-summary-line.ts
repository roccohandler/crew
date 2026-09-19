// SPEC: A6 (owner-directed 2026-09-08) as amended by A28 (c) (2026-09-19) — one summary line per post: strength "Push day · 12 of
// 12 sets" (no minutes: nothing shows the time a workout took; "N of M" as mockups 05 and 11 print it); cardio
// "Walk · 25 min" + " · 2.1 km" when a distance exists (the poster's distanceUnit; one decimal). A2 — a distance is stored
// in meters. A9 — the unit is the poster's own distanceUnit, no longer inferred from their weight unit. Twin: ios/Crew/Engine/SessionSummaryLine.swift — identical names. Pure.
import { SpecConstants } from "@/generated/spec-constants";

// SPEC: A2 · A6 · A9 — meters → "2.1 km" or "1.3 mi" in the poster's distanceUnit, rounded half-up to tenths with integer
// arithmetic so both engines print the same digit on an exact half (2250 m → 2.3 km)
export function distanceText(distanceMeters: number, distanceUnit: string): string {
  const metric = distanceUnit === "km";
  const metersPerUnit = metric ? SpecConstants.metersPerKilometer : SpecConstants.metersPerMile;
  const tenths = Math.round((distanceMeters / metersPerUnit) * SpecConstants.distanceDecimalScale);
  const whole = Math.floor(tenths / SpecConstants.distanceDecimalScale);
  const fraction = tenths % SpecConstants.distanceDecimalScale;
  return `${whole}.${fraction} ${metric ? "km" : "mi"}`;
}

// SPEC: A6 · A28 (c) — sessionSummaryLine(workoutName, isCardio, setsDone, setsPlanned, cardioMinutes, distanceMeters, distanceUnit):
// a strength session reads its sets and nothing of the clock; a cardio log reads its ENTERED minutes (GAP 4 in A28: they stand
// until the owner rules) and, when known, the distance — the wall-clock fallback is gone with every session clock
export function sessionSummaryLine(workoutName: string, isCardio: boolean, setsDone: number, setsPlanned: number, cardioMinutes: number | null, distanceMeters: number | null, distanceUnit: string): string {
  if (!isCardio) return `${workoutName} · ${setsDone} of ${setsPlanned} sets`;
  const parts = [workoutName];
  if (cardioMinutes !== null) parts.push(`${cardioMinutes} min`);
  if (distanceMeters !== null) parts.push(distanceText(distanceMeters, distanceUnit));
  return parts.join(" · ");
}

// SPEC: A28 (c) · R-086 — a summary STORED before A28 carries the workout's minutes ("Push day · 12/12 sets · 44 min"); it reads at
// render as "Push day · 12 of 12 sets". A cardio line's entered minutes stand (GAP 4), and nothing stored is rewritten.
export function withoutWorkoutMinutes(stored: string): string {
  const parts = stored.split(" · ");
  const minutes = parts.at(-1);
  const head = parts.slice(0, -1);
  const sets = head.at(-1);
  if (minutes === undefined || sets === undefined || !minutes.endsWith(" min") || !sets.endsWith(" sets")) return stored;
  const counts = sets.slice(0, -" sets".length).split("/");
  const [done, planned, ...extra] = counts;
  if (done === undefined || planned === undefined || extra.length > 0 || !/^\d+$/.test(done) || !/^\d+$/.test(planned)) return stored;
  return [...head.slice(0, -1), `${done} of ${planned} sets`].join(" · ");
}
