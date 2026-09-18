// SPEC: nutrition addendum §4 — /nutrition/template: the Template half of "Saved meals & template" (the segment's other half is
// /nutrition/meals). An ordered checklist of saved meals — never a requirement. Behind the 18+ gate.
// Twin: ios SavedMealsScreen (segment .template).
import { ObjectId } from "mongodb";
import { BirthYearAsk } from "@/components/nutrition/BirthYearAsk";
import { NutritionSegments } from "@/components/nutrition/NutritionSegments";
import { TemplateView } from "@/components/nutrition/TemplateView";
import { listSavedMeals, savedMealResponse, templateSlots } from "@/lib/nutrition-meals";
import { openNutrition } from "@/app/(app)/nutrition/gate";

export default async function DayTemplatePage() {
  const { user, askBirthYear } = await openNutrition();
  if (askBirthYear) return <BirthYearAsk />;
  const userId = new ObjectId(user.id);
  const [slots, meals] = await Promise.all([templateSlots(userId), listSavedMeals(userId)]);
  return (
    <div className="stack">
      <h1>Saved meals &amp; template</h1>
      <NutritionSegments active="template" />
      <TemplateView initialSlots={slots} meals={meals.map(savedMealResponse)} />
    </div>
  );
}
