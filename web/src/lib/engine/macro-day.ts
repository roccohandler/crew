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

// SPEC: §4 — the words on a line, identical on both platforms: "95 / 145 g" and then "50 to go" or "10 over" — two facts in ordinary
// ink (clause ②). Exactly on target prints no second fact: the amounts already say it, and a zero is never a verdict (A8; R-075).
export function amountText(line: MacroLine, unit: "g" | "kcal"): string {
  return `${line.logged} / ${line.target} ${unit}`;
}

export function restText(line: MacroLine): string | null {
  if (line.over > 0) return `${line.over} over`;
  return line.toGo > 0 ? `${line.toGo} to go` : null;
}

// SPEC: clause ② ("an overage is a measurement stated in ordinary ink on its own line, NAMING TOMORROW IN THE SAME BREATH") — one
// sentence under the four lines whenever any of them is over: the next horizon, as a fact. Never a colour, never an alert, never a
// verb aimed at the user (no coaching copy, A21.5); null while nothing is over, so a day on or under target says nothing (R-075).
export function horizonText(day: MacroRemaining): string | null {
  const anyOver = [day.protein, day.carbs, day.fat, day.calories].some((line) => line.over > 0);
  return anyOver ? "Tomorrow starts from your full targets." : null;
}

// SPEC: 6.5 · E20 — the ONE sentence a screen reader hears for a line, the same on both platforms: "Protein: 95 / 145 g, 50 to go"
export function spokenLine(name: string, line: MacroLine, unit: "g" | "kcal"): string {
  const rest = restText(line);
  return rest === null ? `${name}: ${amountText(line, unit)}` : `${name}: ${amountText(line, unit)}, ${rest}`;
}

// SPEC: §4 · §7.4 encoder ⑤ — the bar's fill as a whole percent of its track. The target marker sits at macroBarTargetPercent, so
// a fill past the hairline IS the overage, shown as length; the colour never changes. No target → an empty track, or a full one.
export function barPercent(line: MacroLine): number {
  if (line.target === 0) return line.logged > 0 ? SpecConstants.macroPercentScale : 0;
  return Math.min(SpecConstants.macroPercentScale, Math.floor((line.logged * SpecConstants.macroBarTargetPercent) / line.target));
}

// SPEC: §4 · §7.4 encoders ① ② — a meal's three numbers in the fixed order, each with its letter; and the sentence VoiceOver reads
export function gramsText(grams: { proteinG: number; carbsG: number; fatG: number }): string {
  return `P ${grams.proteinG} · C ${grams.carbsG} · F ${grams.fatG}`;
}

export function gramsSpoken(grams: { proteinG: number; carbsG: number; fatG: number }): string {
  return `${grams.proteinG} grams protein, ${grams.carbsG} grams carbs, ${grams.fatG} grams fat`;
}

export interface SlotLog {
  clientId: string;
  savedMealId: string | null;
}

// SPEC: §4 "Your template" — one tap logs a slot (✓), undo in place. Which of today's logs ticks which slot: a meal's logs fill that
// meal's slots in order, so the same meal in two slots ticks one at a time; a quick add, or a log whose meal is gone, ticks none.
export function slotTicks(slotMealIds: string[], logs: SlotLog[]): (string | null)[] {
  const used = new Set<string>();
  return slotMealIds.map((mealId) => {
    const match = logs.find((log) => log.savedMealId === mealId && !used.has(log.clientId));
    if (match === undefined) return null;
    used.add(match.clientId);
    return match.clientId;
  });
}

// SPEC: V62 · 8.2 ④ — a log is idempotent on its clientId: a template slot tapped twice (or replayed by the queue) logs once
export function logging(entry: MealLogFacts, logs: MealLogFacts[]): MealLogFacts[] {
  return logs.some((log) => log.clientId === entry.clientId) ? logs : [...logs, entry];
}

// SPEC: clause ③ · V63 (load-bearing) — the ONE place a macro entry could become a game event, and it never does
export function gameEvents(logs: MealLogFacts[]): GameEvent[] {
  return logs.flatMap((): GameEvent[] => []);
}
