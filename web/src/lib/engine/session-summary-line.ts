// SPEC: A6 (owner-directed 2026-09-08) — one summary line per post: strength "Push day · 12/12 sets · 44 min"; cardio
// "Walk · 25 min" + " · 2.1 km" when a distance exists (the poster's units: kg → km, lb → mi; one decimal). A2 — a
// distance is stored in meters. Twin: ios/Crew/Engine/SessionSummaryLine.swift — identical names. Pure.
import { SpecConstants } from "@/generated/spec-constants";

// SPEC: A2 · A6 — meters → "2.1 km" (units kg) or "1.3 mi" (units lb), rounded half-up to tenths with integer arithmetic
// so both engines print the same digit on an exact half (2250 m → 2.3 km)
export function distanceText(distanceMeters: number, units: string): string {
  const metric = units === "kg";
  const metersPerUnit = metric ? SpecConstants.metersPerKilometer : SpecConstants.metersPerMile;
  const tenths = Math.round((distanceMeters / metersPerUnit) * SpecConstants.distanceDecimalScale);
  const whole = Math.floor(tenths / SpecConstants.distanceDecimalScale);
  const fraction = tenths % SpecConstants.distanceDecimalScale;
  return `${whole}.${fraction} ${metric ? "km" : "mi"}`;
}

// SPEC: A6 — sessionSummaryLine(workoutName, isCardio, setsDone, setsPlanned, minutes, cardioMinutes, distanceMeters, units):
// a strength session reads sets and wall-clock minutes; a cardio log reads its logged minutes (the session's own minutes
// when none were logged) and, when known, the distance
export function sessionSummaryLine(workoutName: string, isCardio: boolean, setsDone: number, setsPlanned: number, minutes: number, cardioMinutes: number | null, distanceMeters: number | null, units: string): string {
  if (!isCardio) return `${workoutName} · ${setsDone}/${setsPlanned} sets · ${minutes} min`;
  const line = `${workoutName} · ${cardioMinutes ?? minutes} min`;
  return distanceMeters === null ? line : `${line} · ${distanceText(distanceMeters, units)}`;
}
