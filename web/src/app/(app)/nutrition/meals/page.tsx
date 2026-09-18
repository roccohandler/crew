// SPEC: nutrition addendum §4 — /nutrition/meals: the Saved meals half of "Saved meals & template" (the segment's other half is
// /nutrition/template). Reached from Today's text link; behind the 18+ gate. Twin: ios SavedMealsScreen (segment .meals).
import { ObjectId } from "mongodb";
import { BirthYearAsk } from "@/components/nutrition/BirthYearAsk";
import { NutritionSegments } from "@/components/nutrition/NutritionSegments";
import { SavedMealsView } from "@/components/nutrition/SavedMealsView";
import { listSavedMeals, savedMealResponse } from "@/lib/nutrition-meals";
import { openNutrition } from "@/app/(app)/nutrition/gate";

export default async function SavedMealsPage() {
  const { user, askBirthYear } = await openNutrition();
  if (askBirthYear) return <BirthYearAsk />;
  const meals = await listSavedMeals(new ObjectId(user.id));
  return (
    <div className="stack">
      <h1>Saved meals &amp; template</h1>
      <NutritionSegments active="meals" />
      <SavedMealsView initialMeals={meals.map(savedMealResponse)} />
    </div>
  );
}
