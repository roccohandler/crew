// SPEC: nutrition addendum §4 ("Quick add": three gram steppers and Add) · 6.9 Screen Density (A25; R-077) — /nutrition/quick-add:
// one job on its own screen, one tap from Today. Behind the 18+ gate. Twin: ios QuickAddScreen.
import { BirthYearAsk } from "@/components/nutrition/BirthYearAsk";
import { QuickAddForm } from "@/components/nutrition/DayLogViews";
import { openNutrition } from "@/app/(app)/nutrition/gate";

export default async function QuickAddPage() {
  const { user, askBirthYear } = await openNutrition();
  if (askBirthYear) return <BirthYearAsk />;
  return (
    <div className="stack">
      <h1>Quick add</h1>
      <QuickAddForm timezone={user.timezone} />
    </div>
  );
}
