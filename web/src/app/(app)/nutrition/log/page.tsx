// SPEC: nutrition addendum §4 (today's log, every row with its visible Delete — 6.3) · 6.9 Screen Density (A25; R-077) —
// /nutrition/log: what was logged today, one tap from Today. Private to the signed-in user (clause ④). Behind the 18+ gate.
// Twin: ios NutritionLogScreen.
import { ObjectId } from "mongodb";
import { BirthYearAsk } from "@/components/nutrition/BirthYearAsk";
import { DayLogList } from "@/components/nutrition/DayLogViews";
import { dayKeyFor } from "@/lib/engine/day-key";
import { listLogs, mealLogResponse } from "@/lib/nutrition-logs";
import { openNutrition } from "@/app/(app)/nutrition/gate";

export default async function NutritionLogPage() {
  const { user, askBirthYear } = await openNutrition();
  if (askBirthYear) return <BirthYearAsk />;
  const logs = await listLogs(new ObjectId(user.id), dayKeyFor(new Date(), user.timezone));
  return (
    <div className="stack">
      <h1>Logged today</h1>
      <DayLogList initialLogs={logs.map(mealLogResponse)} />
    </div>
  );
}
