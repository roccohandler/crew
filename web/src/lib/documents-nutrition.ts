// SPEC: nutrition addendum §2 (RATIFIED 2026-09-18) — the four nutrition collections as MongoDB documents. PRIVATE by
// construction: none of them is ever joined into a stream, a pulse or a profile query (clause ④ — asserted by a route test), all
// four are in the JSON export and the delete cascade (E9), and no write to any of them touches gamification (clause ③, V63).
import type { ObjectId } from "mongodb";
import type { DayKey } from "@/lib/documents";

// One document per user; the ONLY body stat in the system (E1's exception). Deleting it deletes the bodyweight with it (V64).
export interface NutritionTargetsDoc {
  _id: ObjectId;
  userId: ObjectId; // unique
  bodyweightTenths: number; // tenths of `bodyweightUnit` — integer arithmetic on both engines (addendum §3)
  bodyweightUnit: "lb" | "kg"; // the account's weightUnit at entry (A9): a preference change never reinterprets it
  proteinG: number;
  carbsG: number;
  fatG: number;
  source: "derived" | "manual"; // manual once the user overwrites any of the three grams; "Recalculate" derives again
  updatedAt: Date;
}

// A seed-sourced meal COPIES the grams at save time, so a later seed edit never rewrites a user's history
export type SavedMealSource = { kind: "manual" } | { kind: "seed"; chainId: string; itemId: string };

export interface SavedMealDoc {
  _id: ObjectId;
  clientId: string; // unique — the id the creating client chose (8.2 ④; the phone's queue addresses it by this)
  userId: ObjectId;
  name: string; // ≤ savedMealNameMaxChars
  proteinG: number; // integers within bounds and nothing else is checked (clause ⑤)
  carbsG: number;
  fatG: number;
  source: SavedMealSource;
  createdAt: Date;
  deletedAt: Date | null;
}

// A checklist, never a requirement: a skipped slot is simply unlogged
export interface DayTemplateDoc {
  _id: ObjectId;
  userId: ObjectId; // unique
  slots: { savedMealId: ObjectId; label: string }[]; // 0 … dayTemplateMaxSlots; deleting a meal removes its slots
  updatedAt: Date;
}

// A log is its own object: no XP, no streak, no shield, no achievement (V63)
export interface MealLogDoc {
  _id: ObjectId;
  clientId: string; // unique — idempotent on it (8.2 ④, V62)
  userId: ObjectId;
  dayKey: DayKey; // 3 AM boundary, server clock (E15)
  savedMealId: ObjectId | null;
  name: string;
  proteinG: number;
  carbsG: number;
  fatG: number;
  quickAdd: boolean;
  createdAt: Date;
  deletedAt: Date | null;
}
