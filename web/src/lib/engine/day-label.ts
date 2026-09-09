// SPEC: A6 (owner-directed 2026-09-08) — readable day labels: Today · Yesterday · a weekday name up to
// dayLabelWeekdayWithinDays back · Mon Sep 8 · Mon Sep 8, 2025; week headers This week · Last week · Week of Sep 1.
// The English names live here (the app ships in English). Twin: ios/Crew/Engine/DayLabel.swift — identical names. Pure.
import { addDays, daysBetween, isoWeekday } from "@/lib/engine/day-key";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function parts(dayKey: string): { year: number; month: number; day: number } {
  const [year, month, day] = dayKey.split("-").map(Number);
  return { year: year ?? 0, month: month ?? 0, day: day ?? 0 };
}

// "Sep 8" — no leading zero
function monthDay(dayKey: string): string {
  const { month, day } = parts(dayKey);
  return `${monthNames[month - 1] ?? ""} ${day}`;
}

// SPEC: A6 — dayLabel(dayKey, todayKey): same → Today; yesterday → Yesterday; within dayLabelWeekdayWithinDays back →
// weekday name; same year → Mon Sep 8; else Mon Sep 8, 2025 (a future day, e.g. a pause's return day, reads as a date)
export function dayLabel(dayKey: string, todayKey: string): string {
  const daysBack = daysBetween(dayKey, todayKey);
  if (daysBack === 0) return "Today";
  if (daysBack === 1) return "Yesterday";
  const weekday = weekdayNames[isoWeekday(dayKey) - 1] ?? "";
  if (daysBack > 1 && daysBack <= SpecConstants.dayLabelWeekdayWithinDays) return weekday;
  const { year } = parts(dayKey);
  return year === parts(todayKey).year ? `${weekday} ${monthDay(dayKey)}` : `${weekday} ${monthDay(dayKey)}, ${year}`;
}

// SPEC: A6 — weekHeader(weekKey, todayWeekKey): This week · Last week · Week of Sep 1
export function weekHeader(weekKey: string, todayWeekKey: string): string {
  if (weekKey === todayWeekKey) return "This week";
  if (addDays(weekKey, TimeUnits.daysPerWeek) === todayWeekKey) return "Last week";
  return `Week of ${monthDay(weekKey)}`;
}
