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
//
// A28 (2026-09-19): the values are the owner's Focus Card table (design/focus-card-system.md §2). The pairs below keep the
// legacy names Home's code still draws with — each is now an alias of one table row, resolved here the way the generator
// resolves it — and the table's own pairs are asserted beside them.
import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

type Color = { light: string; dark: string; lightOpacity?: number; darkOpacity?: number };
const root = join(__dirname, "..", "..");
const tokens = JSON.parse(readFileSync(join(root, "shared", "design-tokens.json"), "utf8")) as {
  colors: Record<string, Color>;
  macroColors: { colors: Record<string, Color> };
  colorAliases: { aliases: Record<string, { token: string }> };
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
  const alias = tokens.colorAliases.aliases[name];
  const token = tokens.colors[alias === undefined ? name : alias.token] ?? tokens.macroColors.colors[name];
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
  { what: "week strip · next-up mark", fg: "inkText", bg: "canvas" },
  { what: "log row · logged dot", fg: "inkText", bg: "canvas" },
  // A18.11 — the boundary of every outline control, on both surfaces it is ever drawn on. This is the pair that
  // `secondaryButtonOutline` could not make: 1.26:1 on a card, 1.19:1 on the canvas.
  { what: "outline control · boundary on the canvas", fg: "controlOutline", bg: "canvas" },
  { what: "outline control · boundary on a card", fg: "controlOutline", bg: "card" },
  { what: "crew dot · not posted ring", fg: "secondaryText", bg: "card" },
  { what: "crew dot · posted", fg: "ember", bg: "card" },
  // A28 (a) REPAYS the unlit flame's half of the 2026-09-10 missedGray debt: it was #A8A29A at 2.39:1 on bone; its alias is
  // now the table's inkMuted, 3.32:1 on the canvas, so the pair the old file could only list as "known" is asserted.
  { what: "streak flame · unlit (missedGray → inkMuted)", fg: "missedGray", bg: "canvas" },
  // nutrition addendum §4 · ux-plan 7.4 — the three macro identity fills, on both surfaces a bar is drawn on. Carbs measures 2.8:1
  // against its own TRACK, which is exactly why its fill carries an ink hairline and every bar a numeric label (encoders ④ and ③):
  // the ratio that matters for the fill is against the surface, and that one is gated here. (Dark carbs on the Midnight card is the
  // one pair A28 breaks — asserted as KNOWN FAILING below, never skipped.)
  { what: "macro bar · protein fill on the canvas", fg: "macroProtein", bg: "canvas" },
  { what: "macro bar · protein fill on a card", fg: "macroProtein", bg: "card" },
  { what: "macro bar · carbs fill on the canvas", fg: "macroCarbs", bg: "canvas" },
  { what: "macro bar · fat fill on the canvas", fg: "macroFat", bg: "canvas" },
  { what: "macro bar · fat fill on a card", fg: "macroFat", bg: "card" },
];

const TEXT: { what: string; fg: string; bg: string }[] = [
  { what: "Home · body and headings", fg: "inkText", bg: "canvas" },
  { what: "Home · card text", fg: "inkText", bg: "card" },
  { what: "Home · the week summary sentence", fg: "secondaryText", bg: "canvas" },
  { what: "Home · secondary text on a card", fg: "secondaryText", bg: "card" },
  // A28 (b): orange words retire, so the legacy emberText is ink — this pair now guards that no small word is left orange
  { what: "a legacy orange WORD (emberText, law ③; ink under A28 (b))", fg: "emberText", bg: "canvas" },
  { what: "primary button label", fg: "primaryButtonLabel", bg: "primaryButtonFill" },
  // the error line and the delete label (danger → destructive) until their screens move red into a destructive confirm
  { what: "an error line (danger → destructive) on the canvas", fg: "danger", bg: "canvas" },
];

// A28 (a) — the Focus Card table's own pairs, the measurements design/focus-card-system.md §2 publishes, asserted.
const TABLE_TEXT: { what: string; fg: string; bg: string }[] = [
  { what: "ink on the canvas", fg: "ink", bg: "canvas" },
  { what: "ink on a card", fg: "ink", bg: "card" },
  { what: "inkSecondary on the canvas", fg: "inkSecondary", bg: "canvas" },
  { what: "inkSecondary on a card", fg: "inkSecondary", bg: "card" },
  { what: "the primary capsule's label (onInk on ink)", fg: "onInk", bg: "ink" },
  { what: "destructive on its confirm sheet (a card)", fg: "destructive", bg: "card" },
];
const TABLE_GRAPHICAL: { what: string; fg: string; bg: string }[] = [
  { what: "the flame glyph / the ring's arc (accent) on the canvas", fg: "accent", bg: "canvas" },
  { what: "the flame glyph / the ring's arc (accent) on a card", fg: "accent", bg: "card" },
  { what: "the unlit flame (inkMuted) on the canvas", fg: "inkMuted", bg: "canvas" },
  { what: "the unlit flame (inkMuted) on a card", fg: "inkMuted", bg: "card" },
  { what: "a heat-map done-day / a done check / a done segment (ink) on a card", fg: "ink", bg: "card" },
];
// The celebration's XP numeral and unit are the ONE orange word A28 (b) keeps, and only as LARGE text — ≥ 24 pt, or ≥ 18.66 pt
// Bold (WCAG 1.4.3; R-083 (3)) — so their gate is 3:1 on the full-bleed canvas the celebration draws on. The numeral is
// ringNumeral (46 pt Bold); the unit must be set at a large-text size too — heroUnit (22 pt Semibold) does NOT qualify.
const LARGE_TEXT_GATE = 3;

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

describe("A28 (a) — the Focus Card table's own pairs", () => {
  for (const mode of MODES) {
    for (const { what, fg, bg } of TABLE_TEXT) {
      it(`${mode}: ${what} clears ${TEXT_GATE}:1`, () => {
        const ratio = contrast(color(fg, mode), color(bg, mode));
        expect(ratio, `${color(fg, mode)} on ${color(bg, mode)} = ${ratio.toFixed(2)}:1`).toBeGreaterThanOrEqual(TEXT_GATE);
      });
    }
    for (const { what, fg, bg } of TABLE_GRAPHICAL) {
      it(`${mode}: ${what} clears ${GRAPHICAL_GATE}:1`, () => {
        const ratio = contrast(color(fg, mode), color(bg, mode));
        expect(ratio, `${color(fg, mode)} on ${color(bg, mode)} = ${ratio.toFixed(2)}:1`).toBeGreaterThanOrEqual(GRAPHICAL_GATE);
      });
    }
    it(`${mode}: the celebration's XP numeral and unit (accent, large text) on the canvas clear ${LARGE_TEXT_GATE}:1`, () => {
      const ratio = contrast(color("accent", mode), color("canvas", mode));
      expect(ratio, `${color("accent", mode)} on ${color("canvas", mode)} = ${ratio.toFixed(2)}:1`).toBeGreaterThanOrEqual(LARGE_TEXT_GATE);
    });
  }

  // "Nothing in the UI uses a colour that is not on it" (§2) and "Do not re-pick either" (the two accents): the table in
  // shared/design-tokens.json is the owner's table, row for row, value for value — a re-pick in one place fails here.
  it("the token table IS the owner's table in design/focus-card-system.md §2, row for row", () => {
    const doc = readFileSync(join(root, "design", "focus-card-system.md"), "utf8");
    const rows = [...doc.matchAll(/^\| `(\w+)`[^|]*\| `([^`]+)` \| `([^`]+)` \|$/gm)].map((match) => ({ name: match[1] ?? "", light: match[2] ?? "", dark: match[3] ?? "" }));
    const rgba = (value: string) => value.match(/^rgba\((\d+),(\d+),(\d+),([\d.]+)\)$/);
    expect(rows.map((row) => row.name)).toEqual(Object.keys(tokens.colors));
    for (const { name, light, dark } of rows) {
      const token = tokens.colors[name];
      if (token === undefined) throw new Error(`the system's row ${name} has no token`);
      for (const [mode, value] of [["light", light], ["dark", dark]] as const) {
        const parts = rgba(value);
        if (parts === null) {
          expect(token[mode], `${name} ${mode}`).toBe(value);
          continue;
        }
        const hex = `#${[parts[1], parts[2], parts[3]].map((channelValue) => Number(channelValue).toString(16).padStart(2, "0").toUpperCase()).join("")}`;
        expect(token[mode], `${name} ${mode}`).toBe(hex);
        expect(mode === "light" ? token.lightOpacity : token.darkOpacity, `${name} ${mode} opacity`).toBe(Number(parts[4]));
      }
    }
  });
});

describe("the accent is one orange, and stays one (A17.4's repayment, carried by A28 (a))", () => {
  // A17.4: #FF6600 measured 2.77:1 on bone. If someone restores it "because it is the brand colour", this fails.
  it("the light accent is not the value that failed the gate", () => {
    expect(color("accent", "light")).not.toBe("#FF6600");
  });

  // The point of the repair was that it is the SAME orange, not a different one — and A28's two accents are "the same hue: the
  // dark accent is the light one lifted for its ground, not a second colour". Guard both ends in both modes: each must stay
  // red-dominant inside the ember wedge (a future "fix" that darkens it into brown would pass 3:1 and break the system), and the
  // two must stay within a degree of each other.
  const hueOf = (hex: string) => {
    const n = Number.parseInt(hex.slice(1), 16);
    const r = ((n >> 16) & 255) / 255;
    const g = ((n >> 8) & 255) / 255;
    const b = (n & 255) / 255;
    const max = Math.max(r, g, b);
    const delta = max - Math.min(r, g, b);
    return { redDominant: max === r, hue: (60 * (((g - b) / delta) % 6) + 360) % 360 }; // red is the max channel for every accent we would accept
  };
  for (const mode of MODES) {
    it(`the ${mode} accent is still the ember orange`, () => {
      const { redDominant, hue } = hueOf(color("accent", mode));
      expect(redDominant, "accent must stay red-dominant").toBe(true);
      expect(hue, `hue ${hue.toFixed(1)}° must stay inside the ember wedge`).toBeGreaterThanOrEqual(15);
      expect(hue, `hue ${hue.toFixed(1)}° must stay inside the ember wedge`).toBeLessThanOrEqual(35);
    });
  }
  it("light and dark are one hue (27.0° / 26.9°)", () => {
    expect(Math.abs(hueOf(color("accent", "light")).hue - hueOf(color("accent", "dark")).hue)).toBeLessThan(1);
  });
});

// KNOWN FAILING — asserted as failing, never skipped, so it turns red the day it is repaired and this block must be rewritten
// as a plain gate. A16's dark carbs fill (#3D7392) measured against the OLD dark card; on A28's Midnight card (#1B2A42) it is
// 2.79:1. A28 does not re-pick a macro colour (the system is silent on nutrition — docs/debt.md 2026-09-19, A28), and dark is
// unreachable while the light lock of A21.10 (as amended 2026-09-18) stands. The lock may not lift while this fails.
describe("KNOWN FAILING — A16's dark carbs fill on A28's dark card (owed to the Nutrition ruling before the light lock lifts)", () => {
  it.fails("dark: macro bar · carbs fill on a card clears 3:1", () => {
    expect(contrast(color("macroCarbs", "dark"), color("card", "dark"))).toBeGreaterThanOrEqual(GRAPHICAL_GATE);
  });
  it("light: macro bar · carbs fill on a card clears 3:1", () => {
    expect(contrast(color("macroCarbs", "light"), color("card", "light"))).toBeGreaterThanOrEqual(GRAPHICAL_GATE);
  });
});

// KNOWN AND DELIBERATELY NOT ASSERTED, so this file never reads as broader coverage than it has:
//   · `hairline` (now the table's hairlineOnCanvas, 1.21:1 on the canvas and 1.33:1 on a card) is still the boundary between
//     two SURFACES — a card edge, a divider — and is deliberately NOT asserted: a surface boundary is not a UI component, and 1.4.11 does not
//     govern it. What it is no longer allowed to be is the boundary of a CONTROL; A18.11 gave that its own `controlOutline`
//     token, asserted above, and the grep below is what stops it drifting back.
//   · `emberTint` (now the table's ringTrack, 1.28:1) is exempt: WeeklyRing prints its fraction in ink inside the ring, so
//     the track encodes nothing a reader needs. The same holds for heatEmpty and segmentEmpty — absence, beside an ink mark.
//     The accent arc meets its ringTrack at 2.45:1 in light (the system's own ring, §8); against the canvas it clears 3.15:1,
//     and the count inside the ring is ink.
//   · `controlBorder` (~1.6:1) is the stepper's ring and never a control's only mark — the ink glyph inside it is (R-083).
//   · `chevron` / `segmentCurrent` (2.41–3.33:1) decorate a row whose name identifies it and a bar whose current segments are
//     also taller; the Logger session judges the bar on the device.

// SPEC: A18.11 — the repair only holds if nothing draws a control boundary with the hairline family again. This is
// the same shape of guard as "the light ember is not the value that failed the gate": the token exists, so the way
// it comes undone is a future edit reaching for the old name, not a future edit changing the new value.
describe("A18.11 — outline controls draw their boundary with controlOutline, not with a hairline", () => {
  // `hairline` is still correct for a boundary between two SURFACES — a card edge, the tab bar's rule, a divider
  // between two rows — because 1.4.11 governs UI COMPONENTS, not the seam between regions. Every rule allowed to
  // keep it is named here, so a NEW control that reaches for it fails this test rather than shipping invisible.
  const SURFACE_RULES = new Set([".tabs", ".card", ".banner", ".logrow + .logrow"]);

  it("app.css — only surface rules draw with --ember-hairline; every control draws with --ember-control-outline", () => {
    const css = readFileSync(join(root, "web", "src", "app", "app.css"), "utf8");
    const offenders: string[] = [];
    let selector = "";
    for (const raw of css.split(/\r?\n/)) {
      const line = raw.trim();
      if (line.endsWith("{")) selector = line.slice(0, -1).trim();
      if (/solid var\(--ember-hairline\)/.test(line) && !SURFACE_RULES.has(selector)) offenders.push(`${selector} { ${line} }`);
    }
    expect(offenders, "control boundaries still drawn with the 1.26:1 hairline family").toEqual([]);
  });

  // The iOS half, swept across the WHOLE app rather than the two files A18 happened to touch (A19 adopted the token
  // on seven more control surfaces). These five are the only places a hairline stroke is still correct, each because
  // it outlines a SURFACE rather than a component — a card edge, a read-only status chip, a banner, a snackbar.
  // Anything else that reaches for the 1.26:1 family fails here.
  const SURFACE_STROKES = new Set([
    "ios/Crew/Shared/Card.swift", // the card itself
    "ios/Crew/Shared/EquipmentChip.swift", // EquipmentChip — a read-only label, not a button (A26 moved it out of ExerciseSheet.swift with its SF Symbol)
    "ios/Crew/Features/Progress/JournalRow.swift", // the "Sending ↻" status chip
    "ios/Crew/Features/Session/UnitConfirmLine.swift", // the one-line unit banner
    "ios/Crew/Features/Plan/WorkoutEditorScreen.swift", // the Undo snackbar's own edge (its Undo is a control inside it)
  ]);

  it("ios — every .stroke of the hairline family outlines a surface, never a control", () => {
    const files = execSync("git ls-files ios/Crew/**/*.swift", { cwd: root, encoding: "utf8" }).split(/\r?\n/).filter((path) => path.endsWith(".swift") && !path.includes("/Generated/"))
      .filter((path) => existsSync(join(root, path))); // git ls-files still lists a file deleted in the working tree
    const offenders: string[] = [];
    for (const path of files) {
      if (SURFACE_STROKES.has(path)) continue;
      const lines = readFileSync(join(root, path), "utf8").split(/\r?\n/).map((line) => line.trim());
      for (const line of lines) {
        // comments are where the OLD value is explained, and explaining it is the point of the repair
        if (line.startsWith("//") || line.startsWith("*")) continue;
        if (!/\.stroke\(/.test(line)) continue;
        // a line that names controlOutline has already made the choice deliberately — WeekRow strokes one or the
        // other depending on whether the row opens a workout, so it legitimately mentions both
        if (/controlOutline/.test(line)) continue;
        if (/secondaryButtonOutline|EmberColors\.hairline\b/.test(line)) offenders.push(`${path}: ${line.slice(0, 90)}`);
      }
    }
    expect(offenders, "control boundaries still stroked with the 1.26:1 hairline family").toEqual([]);
  });
});
