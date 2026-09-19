// SPEC: A27 (a) as ruled 2026-09-18 (owner-approved) — a day is judged by the training days that were in effect ON that day. A
// change takes effect from the dayKey on which it is saved, forward, never backward; the history is append-only (never edited,
// never deleted), and a completed session is a fact that is never re-judged (its isPlannedDay stays as stamped). Twin:
// ios/Crew/Engine/TrainingDays.swift — identical names. Pure.
import { isoWeekday } from "@/lib/engine/day-key";

export interface TrainingDaysEntry {
  from: string; // the dayKey these weekdays took effect
  weekdays: number[]; // ISO 1 = Monday … 7 = Sunday, sorted, unique
}

// SPEC: A27 (a) — the entry in effect on dayKey is the last one whose `from` ≤ dayKey. A day before every entry takes the first:
// before its first recorded change a plan has only ever had its first days (R-082). No history → no planned day.
export function weekdaysOn(history: TrainingDaysEntry[], dayKey: string): number[] {
  let weekdays = history[0]?.weekdays ?? [];
  for (const entry of history) if (entry.from <= dayKey) weekdays = entry.weekdays;
  return weekdays;
}

// SPEC: A27 (a) — "was this day planned?", asked of the entry in effect on it; every reader asks it this way
export function isPlannedOn(history: TrainingDaysEntry[], dayKey: string): boolean {
  return weekdaysOn(history, dayKey).includes(isoWeekday(dayKey));
}

// SPEC: A27 (a) — a change is APPENDED, in effect from the day it is saved; never from before the last entry, so a late-arriving
// edit cannot reach behind one already in effect (R-082). The same days again append nothing.
export function appendTrainingDays(history: TrainingDaysEntry[], weekdays: number[], savedDayKey: string): TrainingDaysEntry[] {
  const sorted = [...new Set(weekdays)].sort((left, right) => left - right);
  const last = history[history.length - 1];
  if (last !== undefined && last.weekdays.length === sorted.length && last.weekdays.every((day, index) => day === sorted[index])) return history;
  const from = last !== undefined && last.from > savedDayKey ? last.from : savedDayKey;
  return [...history, { from, weekdays: sorted }];
}
