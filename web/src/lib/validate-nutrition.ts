// SPEC: nutrition addendum §2–§4 (RATIFIED 2026-09-18) — request shapes for /api/v1/nutrition/*. Grams are integers within
// bounds and NOTHING else is checked (clause ⑤: no food is judged); a bodyweight is a number to one decimal in lb or kg, bounded in
// kilograms (R-074). Mirrors ApiNutrition.swift.
import { z } from "zod";
import { kilogramHundredths } from "@/lib/engine/nutrition-targets";
import { clientIdSchema, dayKeySchema, timezoneSchema } from "@/lib/validate";
import { SpecConstants } from "@/generated/spec-constants";

const entryGrams = z.number().int().min(0).max(SpecConstants.macroGramsMaxPerEntry);
const targetGrams = z.number().int().min(0).max(SpecConstants.macroTargetGramsMax);
const mealName = z.string().trim().min(1).max(SpecConstants.savedMealNameMaxChars);

// SPEC: §3 — tenths of the unit; the bounds are kilograms whichever unit was typed
export const bodyweightTenthsOf = (bodyweight: number): number => Math.round(bodyweight * SpecConstants.bodyweightEntryScale);
function withinBounds(input: { bodyweight: number; unit: "lb" | "kg" }): boolean {
  const kg = kilogramHundredths(bodyweightTenthsOf(input.bodyweight), input.unit);
  return kg >= SpecConstants.bodyweightMinKg * SpecConstants.bodyweightKilogramScale && kg <= SpecConstants.bodyweightMaxKg * SpecConstants.bodyweightKilogramScale;
}

// All three grams (the user overwrote them → manual) or none (derive from the bodyweight → derived; this is also "Recalculate")
export const putTargetsSchema = z
  .object({ bodyweight: z.number().positive(), unit: z.enum(["lb", "kg"]), proteinG: targetGrams.optional(), carbsG: targetGrams.optional(), fatG: targetGrams.optional() })
  .refine(withinBounds, "that bodyweight looks like a typo")
  .refine((input) => [input.proteinG, input.carbsG, input.fatG].every((grams) => grams === undefined) || [input.proteinG, input.carbsG, input.fatG].every((grams) => grams !== undefined), "send all three grams or none");
export type PutTargetsInput = z.infer<typeof putTargetsSchema>;

// SPEC: §4 Settings "Delete my nutrition data" — `everything` also deletes saved meals, the template and every log
export const deleteTargetsSchema = z.object({ everything: z.boolean().optional() });

export const savedMealSchema = z.object({
  clientId: clientIdSchema,
  name: mealName,
  proteinG: entryGrams,
  carbsG: entryGrams,
  fatG: entryGrams,
  seed: z.object({ chainId: z.string().min(1), itemId: z.string().min(1) }).optional(),
});
export type SavedMealInput = z.infer<typeof savedMealSchema>;

export const patchSavedMealSchema = z
  .object({ name: mealName.optional(), proteinG: entryGrams.optional(), carbsG: entryGrams.optional(), fatG: entryGrams.optional() })
  .refine((input) => Object.values(input).some((value) => value !== undefined), "nothing to change");
export type PatchSavedMealInput = z.infer<typeof patchSavedMealSchema>;

export const putTemplateSchema = z.object({
  slots: z.array(z.object({ savedMealId: z.string().min(1), label: z.string().trim().max(SpecConstants.dayTemplateSlotLabelMaxChars).optional() })).max(SpecConstants.dayTemplateMaxSlots),
});
export type PutTemplateInput = z.infer<typeof putTemplateSchema>;

export const createLogSchema = z.object({
  clientId: clientIdSchema,
  timezone: timezoneSchema,
  savedMealId: z.string().min(1).optional(),
  name: mealName,
  proteinG: entryGrams,
  carbsG: entryGrams,
  fatG: entryGrams,
  quickAdd: z.boolean(),
  createdAt: z.iso.datetime().optional(),
});
export type CreateLogInput = z.infer<typeof createLogSchema>;

export const logsQuerySchema = z.object({ dayKey: dayKeySchema });
