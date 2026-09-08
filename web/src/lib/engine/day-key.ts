// SPEC: E8 (the day ends 3 AM local; timezones follow the device; edge cases resolve in the user's favor) · E20
// (Monday week-start) · shared/vectors/README.md "Dates, days, weeks": dayKey(instant, tz) is the local date D with
// startOfDay(D) + 3 h ≤ instant < startOfDay(D + 1) + 3 h, counted in absolute seconds — on a DST spring-forward night
// the day keeps a full 24 h (V08). Twin of ios/Crew/Engine/DayKey.swift: identical names. Pure functions; time enters
// as a parameter. SPEC: V05–V10 · T016
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const boundaryMs = SpecConstants.dayBoundaryHour * TimeUnits.msPerHour;
const formatters = new Map<string, Intl.DateTimeFormat>();

function localDateFormatter(timeZone: string): Intl.DateTimeFormat {
  let formatter = formatters.get(timeZone);
  if (formatter === undefined) {
    formatter = new Intl.DateTimeFormat("en-CA", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" });
    formatters.set(timeZone, formatter);
  }
  return formatter;
}

function utcParts(dayKey: string): [number, number, number] {
  const [year, month, day] = dayKey.split("-").map(Number) as [number, number, number];
  return [year, month - 1, day];
}

// The local calendar date of an instant in a zone, as "YYYY-MM-DD"
export function localDateOf(instant: Date, timeZone: string): string {
  return localDateFormatter(timeZone).format(instant);
}

// The UTC instant of local midnight for a calendar date in a zone (two passes absorb an offset change on that day)
export function startOfDayMs(dayKey: string, timeZone: string): number {
  const naive = Date.UTC(...utcParts(dayKey));
  const firstGuess = naive - offsetMs(naive, timeZone);
  return naive - offsetMs(firstGuess, timeZone);
}

function offsetMs(instantMs: number, timeZone: string): number {
  const parts = new Intl.DateTimeFormat("en-US", { timeZone, hourCycle: "h23", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit" }).formatToParts(new Date(instantMs));
  const value = (type: string) => Number(parts.find((part) => part.type === type)?.value ?? "0");
  const asIfUtc = Date.UTC(value("year"), value("month") - 1, value("day"), value("hour"), value("minute"), value("second"));
  return asIfUtc - instantMs;
}

export function addDays(dayKey: string, days: number): string {
  const [year, month, day] = utcParts(dayKey);
  return new Date(Date.UTC(year, month, day + days)).toISOString().slice(0, "YYYY-MM-DD".length);
}

export function daysBetween(fromDayKey: string, toDayKey: string): number {
  return Math.round((Date.UTC(...utcParts(toDayKey)) - Date.UTC(...utcParts(fromDayKey))) / TimeUnits.msPerDay);
}

// SPEC: E8 — dayKey(for: Date, tz: TimeZone) -> String
export function dayKeyFor(instant: Date, timeZone: string): string {
  const instantMs = instant.getTime();
  const local = localDateOf(instant, timeZone);
  for (const candidate of [addDays(local, -1), local, addDays(local, 1)]) {
    const dayStart = startOfDayMs(candidate, timeZone) + boundaryMs;
    const dayEnd = startOfDayMs(addDays(candidate, 1), timeZone) + boundaryMs;
    if (dayStart <= instantMs && instantMs < dayEnd) return candidate;
  }
  throw new Error(`no dayKey for ${instant.toISOString()} in ${timeZone}`);
}

// SPEC: E20 — weekKey(for dayKey: String) -> String: the Monday of that week
export function weekKeyFor(dayKey: string): string {
  const [year, month, day] = utcParts(dayKey);
  const weekdayFromSunday = new Date(Date.UTC(year, month, day)).getUTCDay();
  const daysSinceMonday = (weekdayFromSunday + TimeUnits.daysPerWeek - SpecConstants.weekStartWeekday) % TimeUnits.daysPerWeek;
  return addDays(dayKey, -daysSinceMonday);
}

export function isoWeekday(dayKey: string): number {
  const [year, month, day] = utcParts(dayKey);
  const weekdayFromSunday = new Date(Date.UTC(year, month, day)).getUTCDay();
  return weekdayFromSunday === 0 ? TimeUnits.daysPerWeek : weekdayFromSunday;
}
