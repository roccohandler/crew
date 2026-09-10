// SPEC: A17.1 — the sentence that answers "what is this screen for / what are the colours for". Twin of
// ios/CrewTests/WeekSummaryTests.swift: the same cases, the same expected strings, so the eye and VoiceOver on two
// platforms cannot print four different sentences from one week.
import { describe, expect, it } from "vitest";
import { weekSummary } from "@/lib/engine/week-summary";

describe("weekSummary", () => {
  // The owner's actual week when they reported the complaint: trains Mon/Wed/Sun, missed Monday, did Wednesday,
  // opened the app on Thursday, next workout Sunday — and the strip showed Sunday identically to Friday.
  it("names the done day, the missed day and the next one", () => {
    const states = ["missed", "rest", "done", "today", "rest", "rest", "nextUp"];
    expect(weekSummary(states).short).toBe("This week: Wed done · Mon missed · next Sun");
    expect(weekSummary(states).spoken).toBe("This week: Wednesday done, Monday missed, today Thursday, next workout Sunday.");
  });

  // A8 — a week with nothing in it says so in words. Never "0 done", never an empty count.
  it("says nothing logged yet rather than a zero", () => {
    const states = ["rest", "today", "rest", "rest", "nextUp", "rest", "rest"];
    expect(weekSummary(states).short).toBe("This week: nothing logged yet · next Fri");
    expect(weekSummary(states).spoken).toBe("This week: nothing logged yet, today Tuesday, next workout Friday.");
  });

  it("lists several done days in week order", () => {
    const states = ["done", "rest", "done", "rest", "today", "rest", "upcoming"];
    expect(weekSummary(states).short).toBe("This week: Mon, Wed done");
    expect(weekSummary(states).spoken).toBe("This week: Monday, Wednesday done, today Friday.");
  });

  // A plan with no further training day this week omits the clause rather than inventing one
  it("omits the next clause when there is no next training day", () => {
    const states = ["done", "rest", "missed", "rest", "today", "rest", "rest"];
    expect(weekSummary(states).short).toBe("This week: Mon done · Wed missed");
    expect(weekSummary(states).spoken).toBe("This week: Monday done, Wednesday missed, today Friday.");
  });

  // `upcoming` is a planned day that is NOT the next one — it is deliberately silent, so the sentence names one
  // future day, not three (A17.4: mark the next training day only)
  it("never names an upcoming day that is not the next one", () => {
    const states = ["today", "nextUp", "upcoming", "rest", "upcoming", "rest", "rest"];
    expect(weekSummary(states).short).toBe("This week: nothing logged yet · next Tue");
  });

  // The strip can be rendered before a plan exists; an empty week must not crash or print a dangling separator
  it("handles an empty week", () => {
    expect(weekSummary([]).short).toBe("This week: nothing logged yet");
    expect(weekSummary([]).spoken).toBe("This week: nothing logged yet.");
  });
});
