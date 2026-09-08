"use client";
// SPEC: 1B — one input per screen, one obvious action; a single-select answer auto-advances on tap after a 250 ms beat
// (no redundant Continue). Web twin of ios SingleSelectQuestion.
import { useState } from "react";
import { SpecConstants } from "@/generated/spec-constants";

export interface SelectOption { value: string; label: string; symbol: string }

export function SingleSelect({ number, title, options, selected, onChoose }: { number: number; title: string; options: SelectOption[]; selected: string | null; onChoose: (value: string) => void }) {
  const [chosen, setChosen] = useState<string | null>(null);
  const pick = (value: string) => {
    setChosen(value);
    window.setTimeout(() => onChoose(value), SpecConstants.autoAdvanceDelayMs);
  };
  return (
    <div className="stack">
      <header className="stack stack--tight">
        <h1>{title}</h1>
        <p className="whisper">{number} of {SpecConstants.onboardingQuestionCount}</p>
      </header>
      {options.map((option) => (
        <button key={option.value} type="button" className="card row" aria-pressed={(chosen ?? selected) === option.value} onClick={() => pick(option.value)}>
          <span aria-hidden="true">{option.symbol}</span>
          <strong>{option.label}</strong>
        </button>
      ))}
    </div>
  );
}
