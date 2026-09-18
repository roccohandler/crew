// SPEC: nutrition addendum §4 · clause ② · §7.4 encoder ⑤ — the words, the bar and the template ticks on Today. Twin of
// ios/CrewTests/MacroDayTests.swift: the same cases, the same expected values, so two platforms cannot print two different lines
// from one day. (V61–V63 pin remaining / logging / gameEvents; these pin what the screen derives from them.)
import { describe, expect, it } from "vitest";
import { amountText, barPercent, gramsSpoken, gramsText, horizonText, macroLine, remaining, restText, slotTicks, spokenLine } from "@/lib/engine/macro-day";

describe("the words on a macro line", () => {
  it("prints the amounts, then to go", () => {
    const line = macroLine(95, 145);
    expect(amountText(line, "g")).toBe("95 / 145 g");
    expect(restText(line)).toBe("50 to go");
  });

  it("prints over as a second fact, never both", () => {
    const line = macroLine(2700, 2660);
    expect(amountText(line, "kcal")).toBe("2700 / 2660 kcal");
    expect(restText(line)).toBe("40 over");
  });

  it("speaks a line as one sentence", () => {
    expect(spokenLine("Protein", macroLine(95, 145), "g")).toBe("Protein: 95 / 145 g, 50 to go");
    expect(spokenLine("Calories", macroLine(2660, 2660), "kcal")).toBe("Calories: 2660 / 2660 kcal");
  });

  // A8 — exactly on target prints no "0 to go": the amounts already say it, and a zero is never a verdict
  it("says nothing more when the target is met exactly", () => {
    expect(restText(macroLine(145, 145))).toBeNull();
  });
});

// Clause ② — an overage names tomorrow in the same breath; a day on or under target says nothing at all
describe("the horizon line", () => {
  const targets = { proteinG: 145, carbsG: 385, fatG: 60 };
  it("is silent while nothing is over", () => {
    expect(horizonText(remaining(targets, []))).toBeNull();
    expect(horizonText(remaining(targets, [{ clientId: "a", proteinG: 145, carbsG: 385, fatG: 60 }]))).toBeNull();
  });

  it("names tomorrow as a fact the moment any line is over", () => {
    expect(horizonText(remaining(targets, [{ clientId: "a", proteinG: 0, carbsG: 0, fatG: 65 }]))).toBe("Tomorrow starts from your full targets.");
  });
});

describe("a meal's three numbers", () => {
  it("prints them in the fixed order with their letters, and speaks them in words", () => {
    const grams = { proteinG: 30, carbsG: 45, fatG: 10 };
    expect(gramsText(grams)).toBe("P 30 · C 45 · F 10");
    expect(gramsSpoken(grams)).toBe("30 grams protein, 45 grams carbs, 10 grams fat");
  });
});

describe("the bar", () => {
  it("fills toward the hairline at 80 % of the track", () => {
    expect(barPercent(macroLine(0, 145))).toBe(0);
    expect(barPercent(macroLine(145, 145))).toBe(80);
    expect(barPercent(macroLine(72, 145))).toBe(39); // floor(72 × 80 / 145)
  });

  it("shows an overage as length and stops at the end of the track", () => {
    expect(barPercent(macroLine(160, 145))).toBe(88);
    expect(barPercent(macroLine(400, 145))).toBe(100);
  });

  it("never divides by a zero target", () => {
    expect(barPercent(macroLine(0, 0))).toBe(0);
    expect(barPercent(macroLine(10, 0))).toBe(100);
  });
});

describe("the template's ticks", () => {
  it("ticks a slot with the log of its meal", () => {
    expect(slotTicks(["oats", "shake"], [{ clientId: "log-1", savedMealId: "shake" }])).toEqual([null, "log-1"]);
  });

  it("ticks the same meal in two slots one log at a time, in order", () => {
    const logs = [{ clientId: "log-1", savedMealId: "shake" }, { clientId: "log-2", savedMealId: "shake" }];
    expect(slotTicks(["shake", "oats", "shake"], logs.slice(0, 1))).toEqual(["log-1", null, null]);
    expect(slotTicks(["shake", "oats", "shake"], logs)).toEqual(["log-1", null, "log-2"]);
  });

  it("is never ticked by a quick add or by a meal that is not in the template", () => {
    expect(slotTicks(["oats"], [{ clientId: "log-1", savedMealId: null }, { clientId: "log-2", savedMealId: "wrap" }])).toEqual([null]);
  });
});
