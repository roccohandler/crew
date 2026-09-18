// SPEC: nutrition addendum §4 (RATIFIED 2026-09-18) · Q3 — /nutrition: Today, reached from Home's "Log macros" row. Behind the 18+
// gate (gate.ts); an account with no birth year is asked for it once, here; with no targets yet the screen is its first-run state
// (one number → the estimate). Server-rendered from the same stores the API serves; private to the signed-in user — nothing on
// this page is ever read by a crew, a pulse or a profile (clauses ③ ④). Twin: ios NutritionTodayScreen.
import { ObjectId } from "mongodb";
import { BirthYearAsk } from "@/components/nutrition/BirthYearAsk";
import { NutritionToday } from "@/components/nutrition/NutritionToday";
import { TargetsForm } from "@/components/nutrition/TargetsForm";
import { dayKeyFor } from "@/lib/engine/day-key";
import { listLogs, mealLogResponse } from "@/lib/nutrition-logs";
import { templateSlots } from "@/lib/nutrition-meals";
import { findTargets } from "@/lib/nutrition-targets-store";
import { openNutrition } from "@/app/(app)/nutrition/gate";

export default async function NutritionTodayPage() {
  const { user, askBirthYear } = await openNutrition();
  if (askBirthYear) return <BirthYearAsk />;
  const userId = new ObjectId(user.id);
  const todayKey = dayKeyFor(new Date(), user.timezone);
  const [targets, slots, logs] = await Promise.all([findTargets(userId), templateSlots(userId), listLogs(userId, todayKey)]);
  if (targets === null) {
    return (
      <div className="stack">
        <h1>Today</h1>
        <p className="muted">Start with your bodyweight. It sets a first estimate of your protein, carbs and fat, and you can change any of it.</p>
        <TargetsForm targets={null} unit={user.weightUnit} next="/nutrition" />
      </div>
    );
  }
  return <NutritionToday targets={{ proteinG: targets.proteinG, carbsG: targets.carbsG, fatG: targets.fatG }} slots={slots} initialLogs={logs.map(mealLogResponse)} todayKey={todayKey} timezone={user.timezone} />;
}
