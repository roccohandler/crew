// SPEC: 6.5 (`spec:960`) — text ≥ 4.5:1, graphical objects and UI components ≥ 3:1. WCAG 2.2 SC 1.4.3 and 1.4.11.
//
// WHY THIS FILE EXISTS (A17.4, 2026-09-10). Six of the seven status marks on Home shipped below the 3:1 non-text gate,
// and the pass that shipped them CERTIFIED THEM AS COMPLIANT — by answering the wrong rule. The plan, the iOS source
// and the web twin all argued that the marks "carry a shape as well as a colour, so the strip reads in grayscale."
// That answers **WCAG 1.4.1** (colour is not the only channel), which the shapes genuinely do satisfy. The gate the
// spec actually states is **1.4.11** (non-text contrast), which is about the ratio, and nothing in the repo measured
// one. There was no contrast test anywhere. That is the whole failure mode: a human argued a plausible-sounding case
// for the wrong criterion and nothing could contradict them.
//
// So this asserts ratios, in both modes, from the ONE source of truth. If a token moves and breaks a gate, this goes
// red before a phone ever sees it.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const root = join(__dirname, "..", "..");
const tokens = JSON.parse(readFileSync(join(root, "shared", "design-tokens.json"), "utf8")) as {
  colors: Record<string, { light: string; dark: string }>;
};

type Mode = "light" | "dark";
const MODES: Mode[] = ["light", "dark"];
const TEXT_GATE = 4.5;
const GRAPHICAL_GATE = 3;

// WCAG 2.x relative luminance, then the contrast ratio. Written out rather than imported: a dependency that computed
// this for us would be a dependency we would then have to trust about the exact thing under test.
function channel(value: number): number {
  const s = value / 255;
  return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}

function luminance(hex: string): number {
  const n = Number.parseInt(hex.slice(1), 16);
  return 0.2126 * channel((n >> 16) & 255) + 0.7152 * channel((n >> 8) & 255) + 0.0722 * channel(n & 255);
}

export function contrast(foreground: string, background: string): number {
  const one = luminance(foreground);
  const two = luminance(background);
  return (Math.max(one, two) + 0.05) / (Math.min(one, two) + 0.05);
}

const color = (name: string, mode: Mode): string => {
  const token = tokens.colors[name];
  if (token === undefined) throw new Error(`no such token: ${name}`);
  return token[mode];
};

// Every foreground/background pair Home actually renders, named by the thing that renders it.
const GRAPHICAL: { what: string; fg: string; bg: string }[] = [
  { what: "week strip · done mark", fg: "ember", bg: "canvas" },
  { what: "week strip · missed ring", fg: "secondaryText", bg: "canvas" },
  { what: "week strip · rest / upcoming tick", fg: "secondaryText", bg: "canvas" },
  { what: "week strip · today ring", fg: "inkText", bg: "canvas" },
  { what: "weekly ring · arc", fg: "ember", bg: "canvas" },
  { what: "streak flame · lit", fg: "ember", bg: "canvas" },
  { what: "vector slot · unlogged ring", fg: "secondaryText", bg: "card" },
  { what: "vector slot · logged dot", fg: "inkText", bg: "card" },
  { what: "crew dot · not posted ring", fg: "secondaryText", bg: "card" },
  { what: "crew dot · posted", fg: "ember", bg: "card" },
];

const TEXT: { what: string; fg: string; bg: string }[] = [
  { what: "Home · body and headings", fg: "inkText", bg: "canvas" },
  { what: "Home · card text", fg: "inkText", bg: "card" },
  { what: "Home · the week summary sentence", fg: "secondaryText", bg: "canvas" },
  { what: "Home · secondary text on a card", fg: "secondaryText", bg: "card" },
  { what: "any orange WORD (law ③)", fg: "emberText", bg: "canvas" },
  { what: "primary button label", fg: "primaryButtonLabel", bg: "primaryButtonFill" },
];

describe("6.5 — non-text contrast on Home (WCAG 1.4.11, the gate the A14 pass did not measure)", () => {
  for (const mode of MODES) {
    for (const { what, fg, bg } of GRAPHICAL) {
      it(`${mode}: ${what} (${fg} on ${bg}) clears ${GRAPHICAL_GATE}:1`, () => {
        const ratio = contrast(color(fg, mode), color(bg, mode));
        expect(ratio, `${color(fg, mode)} on ${color(bg, mode)} = ${ratio.toFixed(2)}:1`).toBeGreaterThanOrEqual(GRAPHICAL_GATE);
      });
    }
  }
});

describe("6.5 — text contrast on Home (WCAG 1.4.3)", () => {
  for (const mode of MODES) {
    for (const { what, fg, bg } of TEXT) {
      it(`${mode}: ${what} (${fg} on ${bg}) clears ${TEXT_GATE}:1`, () => {
        const ratio = contrast(color(fg, mode), color(bg, mode));
        expect(ratio, `${color(fg, mode)} on ${color(bg, mode)} = ${ratio.toFixed(2)}:1`).toBeGreaterThanOrEqual(TEXT_GATE);
      });
    }
  }
});

describe("the ember repayment is real, and stays real", () => {
  // A17.4: #FF6600 measured 2.77:1 on bone. If someone restores it "because it is the brand colour", this fails.
  it("the light ember is not the value that failed the gate", () => {
    expect(color("ember", "light")).not.toBe("#FF6600");
  });

  // The point of #DF5908 was that it is the SAME orange, not a different one. Guard both ends: it must pass the gate
  // AND it must stay orange — a future "fix" that darkens it into brown would pass 3:1 and break Part III.
  it("the light ember is still the same orange, one shade deeper", () => {
    const hex = color("ember", "light");
    const n = Number.parseInt(hex.slice(1), 16);
    const r = ((n >> 16) & 255) / 255;
    const g = ((n >> 8) & 255) / 255;
    const b = (n & 255) / 255;
    const max = Math.max(r, g, b);
    const delta = max - Math.min(r, g, b);
    const hue = (60 * (((g - b) / delta) % 6) + 360) % 360; // red is the max channel for every ember we would accept
    expect(max, "ember must stay red-dominant").toBe(r);
    expect(hue, `hue ${hue.toFixed(0)}° must stay inside the ember wedge`).toBeGreaterThanOrEqual(15);
    expect(hue, `hue ${hue.toFixed(0)}° must stay inside the ember wedge`).toBeLessThanOrEqual(35);
  });
});

// KNOWN AND DELIBERATELY NOT ASSERTED, so this file never reads as broader coverage than it has:
//   · `missedGray` (#A8A29A, 2.39:1 on bone) is still a graphical object on the Progress heat map and the unlit
//     streak flame. Home no longer uses it as one. Logged in debt.md 2026-09-10; repaying it means darkening a
//     Part III table value, which needs owner ratification.
//   · `hairline` / `secondaryButtonOutline` (#E9E4DD, 1.26:1) is the visible boundary of every outline control in
//     the app. Logged in debt.md 2026-09-10; the repair is a distinct `controlOutline` token as its own ratified
//     sweep. Home's vector slot works around it by dropping its card fill so the canvas step separates it.
//   · `emberTint` (the ring track, 1.06:1) is exempt: WeeklyRing prints its fraction in ink inside the ring, so the
//     track encodes nothing a reader needs.
