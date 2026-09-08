// SPEC: E4 / S18 — 14+ quiet days → one warm screen ("Your record still stands" → Keep my plan · Rebuild), no guilt recap, ever ·
// S01 — a stale (> a day) in-progress session triggers the stale-session prompt. Pure twin of ios Engine/LapsedUser.swift. T042
import { daysBetween } from "@/lib/engine/day-key";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export function quietDays(lastActivityDay: string, todayKey: string): number {
  return Math.max(0, daysBetween(lastActivityDay, todayKey));
}

// GAP: "quiet" = no post of any kind (a completed workout always leaves a workout post). A user with no post yet is on the
// bridge, never lapsed. The choice is remembered per quiet spell: an acknowledgement dated after the last activity silences the
// screen until the user is active again and then goes quiet for another 14 days.
export function shouldShowWelcomeBack(lastActivityDay: string | null, ackDay: string | null, todayKey: string): boolean {
  if (lastActivityDay === null) return false;
  if (quietDays(lastActivityDay, todayKey) < SpecConstants.lapsedUserQuietDays) return false;
  return ackDay === null || ackDay <= lastActivityDay;
}

export function isStaleSession(startedAt: Date, now: Date): boolean {
  return now.getTime() - startedAt.getTime() > SpecConstants.staleInProgressSessionAfterHours * TimeUnits.msPerHour;
}
