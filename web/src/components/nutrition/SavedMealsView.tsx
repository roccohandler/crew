"use client";
// SPEC: nutrition addendum §4 (Saved meals: the list · "Add a meal" · "Add from a chain") · §2 — a saved meal is created with a
// clientId (idempotent, 8.2 ④), edited and deleted by either id; deleting one removes its template slots on the server and never
// touches a day already logged (a log keeps its own copy). Writes wait for the server here — a meal is set up once, not tapped
// all day — and an error is said in ink. Twin: ios Features/Nutrition/SavedMealsScreen.swift.
import { useState } from "react";
import { ChainPicker } from "@/components/nutrition/ChainPicker";
import { emptyDraft, MealForm, type MealDraft } from "@/components/nutrition/MealForm";
import { isApiClientError } from "@/lib/api-client";
import { createSavedMeal, deleteSavedMeal, patchSavedMeal } from "@/lib/api-client-nutrition";
import { gramsSpoken, gramsText } from "@/lib/engine/macro-day";
import type { SavedMealResponse } from "@/lib/nutrition-meals";
import { SpecConstants } from "@/generated/spec-constants";

type Mode = { kind: "list" } | { kind: "chains" } | { kind: "form"; title: string; draft: MealDraft; editingId: string | null };

function MealRows({ meals, onEdit, onDelete }: { meals: SavedMealResponse[]; onEdit: (meal: SavedMealResponse) => void; onDelete: (meal: SavedMealResponse) => void }) {
  if (meals.length === 0) return <p className="muted">No saved meals yet. Add the ones you eat most, once.</p>;
  return (
    <ul className="worklist">
      {meals.map((meal) => (
        <li key={meal.id} className="mealrow">
          <span>{meal.name}<span className="worklist__detail"> · {gramsText(meal)}</span></span>
          <span className="mealrow__actions">
            <button type="button" className="button button--text" aria-label={`Edit ${meal.name}, ${gramsSpoken(meal)}`} onClick={() => onEdit(meal)}>Edit</button>
            <button type="button" className="button button--text" aria-label={`Delete ${meal.name}`} onClick={() => onDelete(meal)}>Delete</button>
          </span>
        </li>
      ))}
    </ul>
  );
}

export function SavedMealsView({ initialMeals }: { initialMeals: SavedMealResponse[] }) {
  const [meals, setMeals] = useState(initialMeals);
  const [mode, setMode] = useState<Mode>({ kind: "list" });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const run = async (work: () => Promise<void>) => {
    setBusy(true);
    setError(null);
    try { await work(); setMode({ kind: "list" }); } catch (caught) { setError(isApiClientError(caught) ? caught.message : "Couldn't save that. Try again."); }
    setBusy(false);
  };
  const save = (draft: MealDraft, editingId: string | null) => run(async () => {
    if (editingId === null) {
      const reply = await createSavedMeal({ clientId: crypto.randomUUID(), ...draft });
      setMeals((current) => [...current.filter((meal) => meal.id !== reply.meal.id), reply.meal]);
    } else {
      const reply = await patchSavedMeal(editingId, { name: draft.name, proteinG: draft.proteinG, carbsG: draft.carbsG, fatG: draft.fatG });
      setMeals((current) => current.map((meal) => (meal.id === editingId ? reply.meal : meal)));
    }
  });
  const remove = (meal: SavedMealResponse) => run(async () => { await deleteSavedMeal(meal.id); setMeals((current) => current.filter((kept) => kept.id !== meal.id)); });
  return (
    <div className="stack">
      {error ? <p className="notice" role="alert">{error}</p> : null}
      {mode.kind === "form" ? <MealForm key={mode.title} title={mode.title} initial={mode.draft} busy={busy} onSave={(draft) => void save(draft, mode.editingId)} onCancel={() => setMode({ kind: "list" })} /> : null}
      {mode.kind === "chains" ? <ChainPicker onCancel={() => setMode({ kind: "list" })} onPick={(item) => setMode({ kind: "form", title: "Add from a chain", editingId: null, draft: { name: item.name.slice(0, SpecConstants.savedMealNameMaxChars), proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG, seed: { chainId: item.chainId, itemId: item.id } } })} /> : null}
      {mode.kind === "list" ? (
        <>
          <MealRows meals={meals} onEdit={(meal) => setMode({ kind: "form", title: "Edit meal", editingId: meal.id, draft: { name: meal.name, proteinG: meal.proteinG, carbsG: meal.carbsG, fatG: meal.fatG } })} onDelete={(meal) => void remove(meal)} />
          <button type="button" className="button button--secondary" onClick={() => setMode({ kind: "form", title: "Add a meal", editingId: null, draft: emptyDraft })}>Add a meal</button>
          <button type="button" className="button button--secondary" onClick={() => setMode({ kind: "chains" })}>Add from a chain</button>
        </>
      ) : null}
    </div>
  );
}
