"use client";
// SPEC: S03 / 1B — seven circular toggles ≥ 56 pt, Mon/Wed/Fri pre-selected, the encouragement line reads live, Continue ≥ 1 day,
// "1 of 3" whisper (never a progress bar) · A1 (PPL rotates at every frequency; the neutral whisper "Most people start at 3 days").
// Web twin of ios DaysQuestionScreen. The toggles are also the plan screen's "Change days" (A4).
import { SpecConstants } from "@/generated/spec-constants";

const LETTERS = ["M", "T", "W", "T", "F", "S", "S"];
export const WEEKDAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

export function encouragementLine(count: number): string {
  if (count === 0) return "Pick at least one day.";
  if (count === 1) return "1 day a week — a start is a start.";
  return `${count} days a week — solid.`;
}

export function DayToggles({ days, onToggle }: { days: number[]; onToggle: (weekday: number) => void }) {
  return (
    <div className="row" role="group" aria-label="Training days">
      {LETTERS.map((letter, index) => {
        const weekday = index + 1;
        return (
          <button key={weekday} type="button" className="toggle" aria-pressed={days.includes(weekday)} aria-label={WEEKDAY_NAMES[index]} onClick={() => onToggle(weekday)}>
            {letter}
          </button>
        );
      })}
    </div>
  );
}

export function DaysQuestion({ days, onToggle, onContinue }: { days: number[]; onToggle: (weekday: number) => void; onContinue: () => void }) {
  return (
    <div className="stack">
      <header className="stack stack--tight">
        <h1>Which days do you train?</h1>
        <p className="whisper">1 of {SpecConstants.onboardingQuestionCount}</p>
      </header>
      <DayToggles days={days} onToggle={onToggle} />
      <p className="muted" aria-live="polite">{encouragementLine(days.length)}</p>
      <p className="whisper">Most people start at {SpecConstants.defaultTrainingWeekdays.length} days.</p>
      <button type="button" className="button button--primary" disabled={days.length < SpecConstants.minTrainingDaysToContinue} onClick={onContinue}>
        Continue
      </button>
    </div>
  );
}
