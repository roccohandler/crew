"use client";
// SPEC: nutrition addendum §4 ("three gram steppers") · 6.3 (44 px targets) · clause ⑤ — one gram amount: − / + step by
// macroGramsRoundTo and the number itself is typeable, because forty grams is eight taps otherwise. Whole grams inside 0…max and
// nothing else is checked: no food is judged. Ink only — a macro colour is identity on a BAR, never on a control (§7.4).
// Twin: ios Features/Nutrition/GramField.swift.
import { SpecConstants } from "@/generated/spec-constants";

export const clampGrams = (grams: number, max: number): number => (Number.isFinite(grams) ? Math.min(max, Math.max(0, Math.round(grams))) : 0);

export function GramField({ label, grams, max, onChange }: { label: string; grams: number; max: number; onChange: (grams: number) => void }) {
  return (
    <div className="gramfield" role="group" aria-label={label}>
      <span className="gramfield__label" aria-hidden="true">{label}</span>
      <span className="stepper">
        <button type="button" onClick={() => onChange(clampGrams(grams - SpecConstants.macroGramsRoundTo, max))} aria-label={`Decrease ${label}`}>−</button>
        <input className="gramfield__input" type="number" inputMode="numeric" min={0} max={max} step={1} value={grams} aria-label={`${label} grams`} onChange={(event) => onChange(clampGrams(Number(event.target.value), max))} />
        <button type="button" onClick={() => onChange(clampGrams(grams + SpecConstants.macroGramsRoundTo, max))} aria-label={`Increase ${label}`}>+</button>
      </span>
    </div>
  );
}

// The three of them, always in the fixed order Protein → Carbs → Fat (§7.4 encoder ①)
export function GramFields({ value, max, onChange }: { value: { proteinG: number; carbsG: number; fatG: number }; max: number; onChange: (value: { proteinG: number; carbsG: number; fatG: number }) => void }) {
  return (
    <div className="stack stack--tight">
      <GramField label="Protein" grams={value.proteinG} max={max} onChange={(proteinG) => onChange({ ...value, proteinG })} />
      <GramField label="Carbs" grams={value.carbsG} max={max} onChange={(carbsG) => onChange({ ...value, carbsG })} />
      <GramField label="Fat" grams={value.fatG} max={max} onChange={(fatG) => onChange({ ...value, fatG })} />
    </div>
  );
}
