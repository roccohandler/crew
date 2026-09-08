// SPEC: V37 (pulse = distinct members posted this 3 AM day) · V38 (the weekly crew ring restarts Monday) · V39 (comeback
// banner: same rule as the engine's comeback) · V40 (membership as of each day; a joiner never breaks prior days).
// Twin: ios/Crew/Engine/CrewRules.swift. Posts carry their stored dayKeys (E15 server clock).
import { addDays, weekKeyFor } from "@/lib/engine/day-key";
import type { Pause } from "@/lib/engine/gamification";
import { quietDaysBetween } from "@/lib/engine/gamification-post";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export interface MemberFacts {
  userId: string;
  joinedDayKey: string;
  leftDayKey?: string;
}

export interface MemberPostFacts {
  userId: string;
  dayKey: string;
}

export interface Pulse {
  posted: number;
  total: number;
}

export function memberOn(member: MemberFacts, dayKey: string): boolean {
  return member.joinedDayKey <= dayKey && (member.leftDayKey === undefined || member.leftDayKey > dayKey);
}

export function crewPulse(members: MemberFacts[], posts: MemberPostFacts[], dayKey: string): Pulse {
  const present = members.filter((member) => memberOn(member, dayKey));
  const ids = new Set(present.map((member) => member.userId));
  const posted = new Set(posts.filter((post) => ids.has(post.userId) && post.dayKey === dayKey).map((post) => post.userId));
  return { posted: posted.size, total: present.length };
}

export function crewWeeklyRing(members: MemberFacts[], posts: MemberPostFacts[], asOfDayKey: string): (Pulse & { dayKey: string })[] {
  const ring: (Pulse & { dayKey: string })[] = [];
  for (let day = weekKeyFor(asOfDayKey); day <= asOfDayKey; day = addDays(day, 1)) ring.push({ dayKey: day, ...crewPulse(members, posts, day) });
  return ring;
}

// One member's posts in order → which of them carry the COMEBACK banner (once per return, never the first post)
export function comebackBanner(posts: { dayKey: string }[], pauses: Pause[]): boolean[] {
  let previous: string | null = null;
  return posts.map((post) => {
    const banner = previous !== null && post.dayKey !== previous && quietDaysBetween(previous, post.dayKey, pauses) >= SpecConstants.comebackMissedDaysThreshold;
    previous = post.dayKey;
    return banner;
  });
}

// README kind achievements: days in [fromDay, toDay] on which the pulse was full with at least crewMinMembers present
export function fullPulseDays(members: MemberFacts[], posts: MemberPostFacts[], fromDay: string, toDay: string): number {
  let count = 0;
  for (let day = fromDay; day <= toDay; day = addDays(day, 1)) {
    const pulse = crewPulse(members, posts, day);
    if (pulse.total >= SpecConstants.crewMinMembers && pulse.posted === pulse.total) count += 1;
  }
  return count;
}

// Complete Mon–Sun weeks (Monday ≥ fromDay, Sunday ≤ toDay) whose seven days were all full
export function fullPulseWeeks(members: MemberFacts[], posts: MemberPostFacts[], fromDay: string, toDay: string): number {
  let count = 0;
  let monday = weekKeyFor(fromDay);
  if (monday < fromDay) monday = addDays(monday, TimeUnits.daysPerWeek);
  for (; addDays(monday, TimeUnits.daysPerWeek - 1) <= toDay; monday = addDays(monday, TimeUnits.daysPerWeek)) {
    if (fullPulseDays(members, posts, monday, addDays(monday, TimeUnits.daysPerWeek - 1)) === TimeUnits.daysPerWeek) count += 1;
  }
  return count;
}
