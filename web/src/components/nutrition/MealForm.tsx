"use client";
// SPEC: nutrition addendum §4 ("Add a meal": name + P / C / F grams, manual) · §2 · clause ⑤ — a saved meal is a name and three
// whole numbers, and NOTHING else is checked: no food is judged, scored or labelled. The same form edits a meal and receives a chain
// item's published numbers (copied, then the user's to change). Ink only. Twin: ios Features/Nutrition/MealFormSheet.swift.
import { useState } from "react";
import { GramFields } from "@/components/nutrition/GramField";
import { SpecConstants } from "@/generated/spec-constants";

export interface MealDraft { name: string; proteinG: number; carbsG: number; fatG: number; seed?: { chainId: string; itemId: string } }

export const emptyDraft: MealDraft = { name: "", proteinG: 0, carbsG: 0, fatG: 0 };

export function MealForm({ title, initial, busy, onSave, onCancel }: { title: string; initial: MealDraft; busy: boolean; onSave: (draft: MealDraft) => void; onCancel: () => void }) {
  const [draft, setDraft] = useState(initial);
  const [error, setError] = useState<string | null>(null);
  const submit = () => {
    const name = draft.name.trim();
    if (name.length === 0) return setError("Give it a name, like Oats and whey.");
    setError(null);
    onSave({ ...draft, name });
  };
  return (
    <section className="card stack stack--tight" aria-label={title}>
      <h2>{title}</h2>
      <label className="field"><span>Name</span><input type="text" maxLength={SpecConstants.savedMealNameMaxChars} value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} /></label>
      <GramFields value={draft} max={SpecConstants.macroGramsMaxPerEntry} onChange={(grams) => setDraft({ ...draft, ...grams })} />
      {error ? <p className="notice" role="alert">{error}</p> : null}
      <button type="button" className="button button--primary" disabled={busy} onClick={submit}>Save meal</button>
      <button type="button" className="button button--text" onClick={onCancel}>Cancel</button>
    </section>
  );
}
