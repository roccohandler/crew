"use client";
// SPEC: S03 / 1B — seven circular toggles ≥ 56 pt, Mon/Wed/Fri pre-selected, the encouragement line reads live, Continue ≥ 1 day,
// "1 of 3" whisper (never a progress bar). Web twin of ios DaysQuestionScreen.
import { SpecConstants } from "@/generated/spec-constants";

const LETTERS = ["M", "T", "W", "T", "F", "S", "S"];

export function encouragementLine(count: number): string {
  if (count === 0) return "Pick at least one day.";
  if (count === 1) return "1 day a week — a start is a start.";
  if (count === SpecConstants.fullBodyMaxTrainingDays) return "2 days a week — full body, done right.";
  return `${count} days a week — solid.`;
}

export function DaysQuestion({ days, onToggle, onContinue }: { days: number[]; onToggle: (weekday: number) => void; onContinue: () => void }) {
  return (
    <div className="stack">
      <header className="stack stack--tight">
        <h1>Which days do you train?</h1>
        <p className="whisper">1 of {SpecConstants.onboardingQuestionCount}</p>
      </header>
      <div className="row" role="group" aria-label="Training days">
        {LETTERS.map((letter, index) => {
          const weekday = index + 1;
          const selected = days.includes(weekday);
          return (
            <button key={weekday} type="button" className="toggle" aria-pressed={selected} aria-label={["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][index]} onClick={() => onToggle(weekday)}>
              {letter}
            </button>
          );
        })}
      </div>
      <p className="muted" aria-live="polite">{encouragementLine(days.length)}</p>
      <button type="button" className="button button--primary" disabled={days.length < SpecConstants.minTrainingDaysToContinue} onClick={onContinue}>
        Continue
      </button>
    </div>
  );
}
