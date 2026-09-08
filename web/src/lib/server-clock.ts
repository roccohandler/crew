// SPEC: E15 (server clock wins; no backdating) reconciled with E6/E19 (offline queues; delivery lag never retro-breaks a
// streak) and 8.2 Sync (device-clock skew reconciled to server time): a client's creation timestamp stands when it lies
// within [now − syncClientTimestampMaxAgeDays, now + clientClockSkewToleranceMinutes]; otherwise the server clock wins.
import { dayKeyFor } from "@/lib/engine/day-key";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export function reconciledInstant(clientInstant: Date | undefined, now: Date = new Date()): Date {
  if (clientInstant === undefined || Number.isNaN(clientInstant.getTime())) return now;
  const oldest = now.getTime() - SpecConstants.syncClientTimestampMaxAgeDays * TimeUnits.msPerDay;
  const newest = now.getTime() + SpecConstants.clientClockSkewToleranceMinutes * TimeUnits.msPerMinute;
  if (clientInstant.getTime() < oldest || clientInstant.getTime() > newest) return now;
  return clientInstant;
}

export function serverDayKey(clientInstant: Date | undefined, timezone: string, now: Date = new Date()): string {
  return dayKeyFor(reconciledInstant(clientInstant, now), timezone);
}
