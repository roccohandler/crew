// SPEC: A17.1 (owner-directed 2026-09-10) — the one ink sentence under Home's week strip.
//
// The owner's complaint was "I don't know what this screen is for or what the colors are for". The cause: the flame,
// the ring, the strip and the crew avatar each build a complete English sentence and render it ONLY to VoiceOver, so
// a sighted user gets a glyph, two bare numerals and seven dots. This function is that sentence, made visible.
//
// It returns BOTH forms from one pass — `short` for the eye, `spoken` for VoiceOver — because the alternative is two
// code paths that drift, and the strip's spoken label previously said something the screen did not.
//
// It names the colours IN SITU rather than in a legend: a legend is a split-attention lookup, and A16 already ratified
// "direct numeric labels, never a colour-only legend".
// Pure, and CONCRETE (C1: no generics) — the same shape the Swift twin takes.
// Twin of ios/Crew/Engine/WeekSummary.swift.

// Mon..Sun, matching the ISO ordering every other engine function uses. SHORT duplicates day-label.ts's list (C5: the
// second occurrence duplicates; the third extracts) and FULL is its first occurrence in the engine — VoiceOver reads
// "Wednesday", never "Wed", because a screen reader says an abbreviation letter by letter.
const SHORT = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const FULL = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

export interface WeekSummary {
  short: string;
  spoken: string;
}

function namesOf(states: string[], match: string, list: string[]): string[] {
  return states.map((state, index) => (state === match ? (list[index] ?? "") : "")).filter((name) => name !== "");
}

// SPEC: A17.1 — `states` is Mon..Sun: "done" | "missed" | "rest" | "today" | "nextUp" | "upcoming".
export function weekSummary(states: string[]): WeekSummary {
  const doneShort = namesOf(states, "done", SHORT);
  const doneFull = namesOf(states, "done", FULL);
  const missedShort = namesOf(states, "missed", SHORT);
  const missedFull = namesOf(states, "missed", FULL);
  const nextIndex = states.indexOf("nextUp");
  const todayIndex = states.indexOf("today");

  const shortParts: string[] = [];
  const spokenParts: string[] = [];
  if (doneShort.length > 0) {
    shortParts.push(`${doneShort.join(", ")} done`);
    spokenParts.push(`${doneFull.join(", ")} done`);
  }
  if (missedShort.length > 0) {
    shortParts.push(`${missedShort.join(", ")} missed`);
    spokenParts.push(`${missedFull.join(", ")} missed`);
  }
  // A8 — a week with nothing in it says so in words; it never renders as a zero or an empty count.
  if (shortParts.length === 0) {
    shortParts.push("nothing logged yet");
    spokenParts.push("nothing logged yet");
  }
  if (todayIndex >= 0) spokenParts.push(`today ${FULL[todayIndex] ?? ""}`);
  if (nextIndex >= 0) {
    shortParts.push(`next ${SHORT[nextIndex] ?? ""}`);
    spokenParts.push(`next workout ${FULL[nextIndex] ?? ""}`);
  }
  return { short: `This week: ${shortParts.join(" · ")}`, spoken: `This week: ${spokenParts.join(", ")}.` };
}
