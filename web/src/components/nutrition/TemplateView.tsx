"use client";
// SPEC: nutrition addendum §4 (Template: up to dayTemplateMaxSlots slots — add from saved meals, reorder, remove) · §2 — the template
// is an ordered CHECKLIST of saved meals, never a requirement: nothing counts a skipped slot and nothing scores a day. Every change
// PUTs the whole ordered list (the server replaces it) and is optimistic with a rollback, written out here (C5). The optional label
// ("Breakfast") is the user's own word. Ink only. Twin: ios Features/Nutrition/DayTemplateView.swift.
import Link from "next/link";
import { Whisper } from "@/components/Whisper";
import { useState } from "react";
import { isApiClientError } from "@/lib/api-client";
import { putDayTemplate } from "@/lib/api-client-nutrition";
import { gramsText } from "@/lib/engine/macro-day";
import type { SavedMealResponse, TemplateSlotResponse } from "@/lib/nutrition-meals";
import { SpecConstants } from "@/generated/spec-constants";

// Swap a slot with its neighbour; out of range → unchanged
export function moved(slots: TemplateSlotResponse[], index: number, direction: number): TemplateSlotResponse[] {
  const target = index + direction;
  const slot = slots[index];
  const other = slots[target];
  if (slot === undefined || other === undefined) return slots;
  return slots.map((kept, position) => (position === index ? other : position === target ? slot : kept));
}

function AddSlot({ meals, onAdd }: { meals: SavedMealResponse[]; onAdd: (meal: SavedMealResponse, label: string) => void }) {
  const [mealId, setMealId] = useState(meals[0]?.id ?? "");
  const [label, setLabel] = useState("");
  const meal = meals.find((candidate) => candidate.id === mealId) ?? null;
  return (
    <section className="card stack stack--tight" aria-label="Add a slot">
      <h2>Add a slot</h2>
      <label className="field"><span>Saved meal</span><select value={mealId} onChange={(event) => setMealId(event.target.value)}>{meals.map((candidate) => <option key={candidate.id} value={candidate.id}>{candidate.name}</option>)}</select></label>
      <label className="field"><span>Label (optional)</span><input type="text" maxLength={SpecConstants.dayTemplateSlotLabelMaxChars} placeholder="Breakfast" value={label} onChange={(event) => setLabel(event.target.value)} /></label>
      <button type="button" className="button button--secondary" disabled={meal === null} onClick={() => { if (meal !== null) { onAdd(meal, label.trim()); setLabel(""); } }}>Add to template</button>
    </section>
  );
}

export function TemplateView({ initialSlots, meals }: { initialSlots: TemplateSlotResponse[]; meals: SavedMealResponse[] }) {
  const [slots, setSlots] = useState(initialSlots);
  const [error, setError] = useState<string | null>(null);
  const put = async (next: TemplateSlotResponse[]) => {
    const before = slots;
    setError(null);
    setSlots(next);
    try {
      setSlots((await putDayTemplate(next.map((slot) => ({ savedMealId: slot.savedMealId, label: slot.label })))).slots);
    } catch (caught) {
      setSlots(before);
      setError(isApiClientError(caught) ? caught.message : "Couldn't save the template. Try again.");
    }
  };
  if (meals.length === 0) return <div className="stack"><p className="muted">A template is built from saved meals. Add one first.</p><Link className="button button--secondary" href="/nutrition/meals">Saved meals</Link></div>;
  return (
    <div className="stack">
      {error ? <p className="notice" role="alert">{error}</p> : null}
      {slots.length === 0 ? <p className="muted">Your usual day, in order. One tap on Today logs each slot.</p> : null}
      <ol className="worklist">
        {slots.map((slot, index) => (
          <li key={`${slot.savedMealId}-${index}`} className="mealrow">
            <span>{slot.label === "" ? slot.meal.name : `${slot.label} · ${slot.meal.name}`}<span className="worklist__detail"> · {gramsText(slot.meal)}</span></span>
            <span className="mealrow__actions">
              <button type="button" className="button button--text" disabled={index === 0} aria-label={`Move ${slot.meal.name} up`} onClick={() => void put(moved(slots, index, -1))}>Up</button>
              <button type="button" className="button button--text" disabled={index === slots.length - 1} aria-label={`Move ${slot.meal.name} down`} onClick={() => void put(moved(slots, index, 1))}>Down</button>
              <button type="button" className="button button--text" aria-label={`Remove ${slot.meal.name} from the template`} onClick={() => void put(slots.filter((_, position) => position !== index))}>Remove</button>
            </span>
          </li>
        ))}
      </ol>
      {slots.length > 0 ? <Whisper id="why.freeDinner" /> : null}
      {slots.length < SpecConstants.dayTemplateMaxSlots ? <AddSlot meals={meals} onAdd={(meal, label) => void put([...slots, { savedMealId: meal.id, label, meal }])} /> : <p className="muted">{`That's all ${SpecConstants.dayTemplateMaxSlots} slots.`}</p>}
    </div>
  );
}
