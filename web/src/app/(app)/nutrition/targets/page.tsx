// SPEC: nutrition addendum §4 (Settings → Nutrition targets: bodyweight, the three grams, Recalculate — Q1: no goal) · E1's one
// exception. Reached from Settings; behind the 18+ gate. Twin: ios NutritionTargetsScreen.
import { ObjectId } from "mongodb";
import { BirthYearAsk } from "@/components/nutrition/BirthYearAsk";
import { TargetsForm } from "@/components/nutrition/TargetsForm";
import { findTargets, targetsResponse } from "@/lib/nutrition-targets-store";
import { openNutrition } from "@/app/(app)/nutrition/gate";

export default async function NutritionTargetsPage() {
  const { user, askBirthYear } = await openNutrition();
  if (askBirthYear) return <BirthYearAsk />;
  const targets = await findTargets(new ObjectId(user.id));
  return (
    <div className="stack">
      <h1>Nutrition targets</h1>
      <TargetsForm targets={targets === null ? null : targetsResponse(targets)} unit={user.weightUnit} next={null} />
    </div>
  );
}
