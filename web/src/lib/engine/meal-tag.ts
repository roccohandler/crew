// SPEC: Flow 4 time-smart tags (7 AM → 🍳 · 12:30 → 🥗 · 7 PM → 🍽 · odd hours → 🥤) · Decision Registry G10 (breakfast
// 04:00–10:30 · lunch 10:30–15:30 · dinner 15:30–21:00 · snack otherwise), local minutes of the day. Twin: MealTag.swift.
import { SpecConstants } from "@/generated/spec-constants";

export type MealTag = "breakfast" | "lunch" | "dinner" | "snack";

export function mealTagFor(minuteOfDay: number): MealTag {
  if (minuteOfDay >= SpecConstants.mealTagBreakfastFromMinute && minuteOfDay < SpecConstants.mealTagLunchFromMinute) return "breakfast";
  if (minuteOfDay >= SpecConstants.mealTagLunchFromMinute && minuteOfDay < SpecConstants.mealTagDinnerFromMinute) return "lunch";
  if (minuteOfDay >= SpecConstants.mealTagDinnerFromMinute && minuteOfDay < SpecConstants.mealTagDinnerUntilMinute) return "dinner";
  return "snack";
}

export const mealTagEmoji: Record<MealTag, string> = { breakfast: "🍳", lunch: "🥗", dinner: "🍽", snack: "🥤" };
