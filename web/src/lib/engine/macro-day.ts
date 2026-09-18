// SPEC: nutrition addendum §4 (Today: P / C / F and, fourth, Calories — Q2) · §7 · clauses ② ③ · V61–V63. remaining(targets, logs) →
// per line { logged, target, toGo, over }: "N to go" or "N over" are two facts in ink, never a colour and never a verdict (clause ②).
// The calorie line is the three macros in Atwater kilocalories on both sides, so it always agrees with the grams the user set.
// A macro entry is NEVER a game event (clause ③, V63): it pays no XP, moves no streak, fills no shield, earns no achievement.
// Twin: ios/Crew/Engine/MacroDay.swift — identical names. Pure.
import { SpecConstants } from "@/generated/spec-constants";
import type { GameEvent } from "@/lib/engine/gamification";

export interface MealLogFacts {
  clientId: string;
  proteinG: number;
  carbsG: number;
  fatG: number;
}

export interface MacroLine {
  logged: number;
  target: number;
  toGo: number;
  over: number;
}

export interface MacroRemaining {
  protein: MacroLine;
  carbs: MacroLine;
  fat: MacroLine;
  calories: MacroLine;
}

export function kcalOf(proteinG: number, carbsG: number, fatG: number): number {
  return proteinG * SpecConstants.kcalPerGramProtein + carbsG * SpecConstants.kcalPerGramCarbs + fatG * SpecConstants.kcalPerGramFat;
}

// SPEC: V61 — to go = target − logged floored at 0; over = the other side of the same subtraction; never both above 0
export function macroLine(logged: number, target: number): MacroLine {
  return { logged, target, toGo: Math.max(0, target - logged), over: Math.max(0, logged - target) };
}

export function remaining(targets: { proteinG: number; carbsG: number; fatG: number }, logs: MealLogFacts[]): MacroRemaining {
  const proteinG = logs.reduce((sum, log) => sum + log.proteinG, 0);
  const carbsG = logs.reduce((sum, log) => sum + log.carbsG, 0);
  const fatG = logs.reduce((sum, log) => sum + log.fatG, 0);
  return {
    protein: macroLine(proteinG, targets.proteinG),
    carbs: macroLine(carbsG, targets.carbsG),
    fat: macroLine(fatG, targets.fatG),
    calories: macroLine(kcalOf(proteinG, carbsG, fatG), kcalOf(targets.proteinG, targets.carbsG, targets.fatG)),
  };
}

// SPEC: V62 · 8.2 ④ — a log is idempotent on its clientId: a template slot tapped twice (or replayed by the queue) logs once
export function logging(entry: MealLogFacts, logs: MealLogFacts[]): MealLogFacts[] {
  return logs.some((log) => log.clientId === entry.clientId) ? logs : [...logs, entry];
}

// SPEC: clause ③ · V63 (load-bearing) — the ONE place a macro entry could become a game event, and it never does
export function gameEvents(logs: MealLogFacts[]): GameEvent[] {
  return logs.flatMap((): GameEvent[] => []);
}
