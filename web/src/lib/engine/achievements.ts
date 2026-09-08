// SPEC: shared/seed/achievements.json rules (earned once, the first time its trigger counter reaches threshold, never
// removed — V35) · README kind `achievements` (V45–V50) · 5.6.1 Award.achievement(id) · E8 (unlocks fold into the
// celebration). Pure: counters in, seed-ordered awards out. Twin: ios/Crew/Engine/Achievements.swift.
import type { Award } from "@/lib/engine/gamification";
import { achievements as seedAchievements, type SeedAchievement } from "@/generated/seed";

export interface AchievementCounters {
  postsTotal: number;
  workoutsCompleted: number;
  currentStreak: number;
  perfectWeeks: number;
  prCount: number;
  shieldsConsumed: number;
  comebacks: number;
  crewJoined: number;
  reactionsGiven: number;
  crewFullPulseDays: number;
  crewFullPulseWeeks: number;
}

export function achievementsEarned(counters: Partial<AchievementCounters>, alreadyEarned: string[], definitions: SeedAchievement[] = seedAchievements): Award[] {
  const awards: Award[] = [];
  for (const achievement of definitions) {
    if (alreadyEarned.includes(achievement.id)) continue;
    const counter = counters[achievement.trigger as keyof AchievementCounters] ?? 0;
    if (counter >= achievement.threshold) awards.push({ award: "achievement", id: achievement.id });
  }
  return awards;
}

export function achievementTitle(id: string): string | null {
  return seedAchievements.find((achievement) => achievement.id === id)?.title ?? null;
}
