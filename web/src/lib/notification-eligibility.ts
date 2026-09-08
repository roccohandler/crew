// SPEC: Flow 2 (7:00 AM "Push day is ready 💪" — the reminder at the user's chosen time, G12) · Flow 4 rhythm reminder (one gentle
// nudge at YOUR usual time, only when the streak's at risk) · Flow 7 (paused → reminders stop) · Flow 6 (no nudge pings) ·
// Part IV email rules (no digests) · E5 (denied → in-app). Pure decision functions; the sender calls them on a schedule. T033
import { SpecConstants } from "@/generated/spec-constants";

export interface ReminderFacts {
  reminderTime: string | null; // "HH:MM" local, user-chosen (G12)
  localTime: string; // "HH:MM" now, in the user's zone
  isPlannedDay: boolean;
  workoutDoneToday: boolean;
  postedToday: boolean;
  paused: boolean;
  hasPushToken: boolean;
  alreadySentToday: boolean;
}

// The morning reminder names the day's workout; rest days get nothing (Flow 5: no guilt)
export function reminderDue(facts: ReminderFacts): boolean {
  if (!facts.hasPushToken || facts.paused || facts.alreadySentToday || facts.reminderTime === null) return false;
  if (!facts.isPlannedDay || facts.workoutDoneToday) return false;
  return facts.localTime === facts.reminderTime;
}

export interface StreakRiskFacts {
  currentStreak: number;
  postedToday: boolean;
  paused: boolean;
  hasPushToken: boolean;
  alreadySentToday: boolean;
  localMinuteOfDay: number; // minutes since local midnight
  usualPostMinuteOfDay: number | null; // the user's median post time, null until there is history
}

// SPEC: Flow 4 rhythm reminder — one nudge at the user's usual time, only when a live streak has nothing posted yet
export function streakRiskDue(facts: StreakRiskFacts): boolean {
  if (!facts.hasPushToken || facts.paused || facts.alreadySentToday || facts.postedToday) return false;
  if (facts.currentStreak <= 0 || facts.usualPostMinuteOfDay === null) return false;
  return facts.localMinuteOfDay >= facts.usualPostMinuteOfDay && facts.localMinuteOfDay < facts.usualPostMinuteOfDay + SpecConstants.streakRiskNudgeWindowMinutes;
}

export interface CrewActivityFacts {
  hasPushToken: boolean;
  muted: boolean;
  isOwnPost: boolean;
  kind: "reaction" | "post";
}

// SPEC: Flow 2 ("Buzz: 💪 from Alex") — reactions on YOUR post notify; Flow 6 says NO nudge pings, so a crew-mate's post does not
export function crewActivityDue(facts: CrewActivityFacts): boolean {
  if (!facts.hasPushToken || facts.muted) return false;
  return facts.kind === "reaction" && facts.isOwnPost;
}

// Digests are rejected by Part IV; the function exists so the "digest" row of 8.3 is a tested NO, not an absence
export function digestDue(): boolean {
  return false;
}
