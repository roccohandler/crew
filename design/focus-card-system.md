# Crew — design system

> Ratified by the owner as Appendix A **A28** (2026-09-19). The registry resolves conflicts: where this file and an older spec
> section disagree, A28 names what it supersedes, and anything A28 does not rule is listed there as a SPECIFICATION GAP — the spec
> stands on it until the owner rules. The tokens live in `shared/design-tokens.json`; the rules are read from `design/DESIGN.md`.

Final specification. Light mode is Varsity cream, dark mode is Midnight navy. SwiftUI, iOS 17, iPhone only, portrait.

This document is the source of truth for colour, type, spacing, components and copy. Where it conflicts with anything earlier, this wins. Reference frames live on the Design canvas ("Crew — Varsity, light and dark"): twelve screens, each drawn in both modes, exported at 390×844.

---

## 1. Tone

Serious, optimistic, unbothered. The app never asks you to do anything and never scolds you for not; it states what is true and what happens if you show up. It speaks in seasons: you are *in season* or *off-season*, you are *this season* or comparing against your *best season*. A short workout counts, because *something beats nothing*. A missed day is reported and not judged, because *a miss is a fact, not a verdict* — the streak shows what it shows, the ring fills as far as it filled, and nothing anywhere says "don't break the chain" or "you've been away". No exclamation marks. No second-person imperatives outside button labels. No encouragement that would sound strange said aloud by a training partner who respects you.

Fixed vocabulary: **in season · off-season · this season · best season · something beats nothing · a miss is a fact, not a verdict.**

Copy that is already settled and should ship as written:

| where | string |
|---|---|
| Home, first day (card sub-line) | `Your season starts today` |
| Home, off-season (card sub-line) | `Off-season until Friday 25 September. Reminders are off.` |
| Home, off-season (streak label) | `OFF-SEASON` |
| Home, rest day (card sub-line) | `Rest is part of the season. Nothing to do today.` |
| Progress (fact line) | `This season · 6 weeks · 18 workouts` |
| Home, quiet fact row | `Macros · 2 logged` / `Macros · nothing logged yet` |
| Logger, phone-free path | `Quick complete` |
| Mobility target, anywhere it is listed | `4 holds` — never a duration |

---

## 2. Colour

One table, both modes. Nothing in the UI uses a colour that is not on it. Ship these as Asset Catalog Color Sets with Any/Dark appearances, named as in the token column.

| token | light (Varsity) | dark (Midnight) |
|---|---|---|
| `canvas` | `#F7F1E4` | `#0E1A2E` |
| `card` (also sheet surface) | `#FFFCF6` | `#1B2A42` |
| `ink` | `#142744` | `#F2EEE6` |
| `inkSecondary` | `#4E5E78` | `#95A6BE` |
| `inkMuted` | `#7E8496` | `#687A93` |
| `hairlineOnCard` | `#EFE8D9` | `#26364E` |
| `hairlineOnCanvas` | `#E6DCC8` | `#223049` |
| `controlBorder` | `#D3C7AE` | `#33475F` |
| `segmentEmpty` | `#E0D6C0` | `#27384F` |
| `segmentCurrent` | `#A89C84` | `#5A6E88` |
| `chevron` | `#A89C84` | `#5A6E88` |
| `ringTrack` | `#E0D6C0` | `#27384F` |
| `heatEmpty` | `#E4E3E1` | `#27384F` |
| `tabBar` | `#FBF7EE` | `#12203A` |
| `accent` | `#DE6400` | `#FF8A2B` |
| `onInk` (label on an ink fill) | `#FFFCF6` | `#0E1A2E` |
| `destructive` | `#BC2A1C` | `#FF8575` |
| `sheetScrim` | `rgba(20,39,68,0.34)` | `rgba(4,9,17,0.58)` |

**Measured contrast**, light then dark, canvas / card: `ink` 13.29 / 14.61 and 15.05 / 12.46. `inkSecondary` 5.84 / 6.42 and 7.03 / 5.82. `inkMuted` 3.32 / 3.64 and 3.98 / 3.29 — it carries no text below 24pt. `accent` 3.15 / 3.46 and 7.40 / 6.13. `destructive` on its sheet 5.88 and 6.09. `onInk` on `ink` 14.61 and 15.05. Card against canvas 1.10:1 light and 1.21:1 dark. `heatEmpty` against card 1.25:1 and 1.21:1.

The two accents are the same hue: `#DE6400` is hue 27.0°, `#FF8A2B` is hue 26.9°, both fully saturated. The dark accent is the light one lifted for its ground, not a second colour. Do not re-pick either.

**The ink is navy, not charcoal.** Anywhere older notes say "a single dark ink" or `#1B1A17`, read `ink`. That covers the filled capsule's fill, every icon and glyph, every text button, the stepper's plus and minus, the completed check's circle, completed progress segments, heat-map done-days and the selected tab. The filled capsule inverts with the mode: navy fill with a cream label in light, cream fill with a navy label in dark.

---

## 3. Orange is a point, not a field

`accent` is permitted in exactly three places, and nowhere else in the app:

1. **the flame glyph** — as a `fill`
2. **the weekly ring's progress arc** — as a `stroke`
3. **the celebration's XP numeral and its unit** — as a text `color`

Everything that was once orange is now ink or a neutral token. Specifically: the **streak numeral is `ink`** (only the small flame beside it is accent); the **ring's interior numeral is `ink`**; **heat-map done-days are `ink`**; **day-mark fills are `ink`**; the **ring track is `ringTrack`**, a neutral tone in both modes — it can no longer be a tint of the accent, because a 15% wash over a 140pt circle is a field.

Hard constraints: accent is never a `background`, never on a control, never behind text, and never fills an area larger than a fingertip. Ink and neutral tokens carry all structure and all state.

**Per-screen budget**, which an implementation should be able to assert in a test: seven of the twelve screens show no accent at all (first day, no plan, logger start, mid-set, whole-workout sheet, mobility, Progress). Home on a training day, a rest day and a done day show two instances — flame plus ring. Off-season Home shows one — the ring only. The celebration shows three — flame, XP numeral, XP unit.

**Flame state machine:** `accent` while the streak is alive; `inkMuted` at zero; off-season it is replaced by a snowflake in `inkSecondary` while the ring stays `accent`, because those workouts happened.

**Red** appears only inside a destructive confirm sheet, in both modes, and nowhere else.

---

## 4. Typeface and scale

SF Pro throughout — Display above 28pt, Text below. **Every numeral is SF Pro Rounded Bold**: set counts, weights, reps, streak, ring, XP, targets, week and workout counts. Words are never rounded; numbers always are. In SwiftUI, `.system(size:weight:design: .rounded)` for numerals and `.default` for everything else.

| role | size | weight | tracking |
|---|---|---|---|
| celebration numeral | 96 | Bold | −5% |
| hero numeral (reps, weight) | 76 | Bold | −4% |
| streak numeral | 54 | Bold | −3% |
| ring numeral, XP numeral | 46 | Bold | −2% |
| screen title | 38 | Heavy | −3% |
| screen title, bare screen | 44 | Heavy | −3.5% |
| celebration phrase | 30 | Heavy | −3% |
| sheet title | 27 | Heavy | −3% |
| exercise title | 24 | Bold | −2% |
| card sub-heading | 20 | Bold | −1.5% |
| unit label beside a hero numeral | 22 | Semibold | — |
| body | 17 | Medium / Semibold | — |
| secondary | 15 | Medium | — |
| caption | 13 | Semibold | — |
| eyebrow (uppercase) | 11 | Bold | +14% (+12% under ring and streak, +6% Progress weekday letters) |
| tab label | 10 | Semibold | — |

---

## 5. Spacing and safe areas

A 4pt base, used at 4, 6, 7, 8, 12, 13, 14, 15, 16, 18, 20, 22, 26, 30. Screen gutter is 20pt everywhere. Card padding is 22pt on Home and Progress; the set card and the checklist card use 20pt horizontal with 15–16pt vertical per row. Safe areas are 59pt top and 34pt bottom, with a 49pt tab bar above the bottom inset. Reward block to card, 30pt.

No status bar is drawn and no keyboard is painted — the real ones render on top, so that space is left alone.

---

## 6. Elevation

**Light** separates a card from the canvas with a one-step lift to `card` plus a two-layer shadow: `0 1 3 rgba(20,39,68,0.05)` and `0 14 34 rgba(20,39,68,0.08)`.

**Dark uses tone alone and no shadow.** A shadow on a near-black ground is invisible and a glow is a gradient by another name. The step is small in ratio (1.21:1) and that is sufficient, because a card is a large filled field; the hairlines and control borders inside it are pushed to roughly 1.5:1 for the same reason in reverse. Gate the shadow on `colorScheme` rather than defining a dark shadow.

---

## 7. Screen types

Six. Every screen in the app is one of them; nothing else gets invented.

- **Home screen** — the reward block over one card, optically centred, with quiet rows beneath.
- **Set screen** — a header, one card of two metric rows, a fact line, one filled button.
- **Checklist screen** — a header with "Mark all done", a count line, one card of name-plus-cue rows each with a check. Mobility at the end of every workout; the same screen serves a warm-up at the start. The only screen type with more than one tick target.
- **Sheet** — a bottom surface with a grabber, a title row, list rows, one filled button.
- **Celebration** — a full-bleed centred stack, no nav.
- **Data screen** — a large title, one fact line, one card carrying the figure. Progress is the first.

---

## 8. Components

- **Primary button** — a filled `ink` capsule, `onInk` label at 17pt Bold, 56pt tall on Home and 58pt elsewhere, corner radius always half the height. **At most one per screen**, and several screens correctly have none (rest day, done).
- **Text button** — a label alone in `ink`, 15pt Semibold, 44pt minimum tap height, no background, border or underline. Quick complete, Swap exercise, Skip, Whole workout, Mark all done, Edit today's log, Keep it private.
- **Quiet fact row** — the same 44pt row, set entirely in `inkSecondary` at 15pt Medium with its numeral rounded. States a fact and opens a screen on tap; carries no chevron and never looks like a control.
- **Stepper** — a 52pt circle, 1.5pt `controlBorder`, 22pt `ink` glyph, no fill.
- **Icon button** — 44×44 transparent, 22pt `ink` glyph, always an accessibility label.
- **Value button** — the big numeral itself, tappable, opening the numeric keypad. No box, no underline, no field chrome: the number is the control.
- **Check** — a 44pt target holding a 28pt circle: 2pt `ink` ring when open, solid `ink` with an `onInk` tick when done.
- **Row button** — a full-width list row: name, value, chevron, 56pt minimum, with the current row tinted one step off the sheet.
- **Weekly ring** — 140pt box, radius 60, 16pt stroke, round cap, rotated −90°, `ringTrack` beneath and `accent` above. Interior: the count at 46pt Rounded Bold in `ink` over an 11pt eyebrow in `inkSecondary`.
- **Segmented workout bar** — grouped by exercise, 4pt gaps within a group and 14pt between groups; the current exercise's segments are 8pt tall and the rest 6pt. Done is `ink`, current is `segmentCurrent`, pending is `segmentEmpty`. Each group is a 44pt-tall button that jumps to that exercise; the count at the right end opens the whole-workout sheet.
- **Heat map** — a 7-column grid, 30pt cells, 7pt gaps, radius 8. Done is `ink`, empty is `heatEmpty`.

**Radii.** Capsule for every button. 28pt for cards and the sheet's top corners. 26pt for the stepper, 14pt for a check, 8pt for a heat-map cell, 4pt and 3pt for progress segments, 3pt for the grabber. Nothing else is rounded.

---

## 9. Screen inventory

Twelve screens, each drawn in both modes.

| screen | job | notes |
|---|---|---|
| Home — first day | get them to start | no reward block at all; a zero is never shown as a verdict |
| Home — no plan | get a plan built | no reward block; card is the hero at 44pt |
| Home — training day | say what today is and start it | reward block, card, Quick complete, Macros row |
| Home — rest day | say there is nothing to do | no filled button; card carries tomorrow |
| Home — done | confirm and show tomorrow | no filled button; "Edit today's log" as a text button |
| Home — off-season | resume or wait | snowflake, ring stays accent, one filled button |
| Logger — start | log set 1 | last-time reference sits below the card |
| Logger — mid-set | log the current set | running ledger replaces the last-time line |
| Logger — whole workout | jump between exercises, finish | reached from the bar; **Finish lives here** |
| Logger — mobility | tick the holds, finish | last screen of every workout; reused for warm-up |
| Logger — after Finish | reward | flame, streak, XP, share or keep private |
| Progress — top | how the season is going | title, season line, heat map; no accent |

Placement decisions that are settled: `+ set` and `+ warm-up` live in the logger's `⋯` menu, so Swap and Skip can stay visible. Cardio and a bonus workout on a rest day live behind the `＋` in the Home nav bar. lb/kg lives in Settings.

---

## 10. Motion, haptics, Dynamic Type

**Haptics only, no sound of any kind.** Light impact per stepper tap and per check, medium impact on Log set, one success notification on Finish. Nothing else vibrates.

**Dynamic Type.** Every screen is a single column. At accessibility sizes the metric row breaks to numeral over steppers, card exercise rows break to name over target, checklist rows move the check below the cue, and eyebrow-and-value pairs stack. The Progress heat map keeps seven columns and lets the cells shrink. Nothing truncates: the card grows and the screen scrolls. Target: legible at accessibility-XXL on a 375pt screen.

---

## 11. Banned

- Accent on anything interactive — buttons, tabs, links, toggles, selected states, checks, focus rings, and the workout progress bar, which is ink.
- Accent as a background or a fill of any area larger than a fingertip.
- A third hue. No green for done, no blue for links; red exists only inside a destructive confirm.
- More than one filled button on a screen.
- **Timers of every kind** — no rest countdown between sets, no hold duration, no session clock, no elapsed minutes in a summary. Nothing happens between sets except the next set. A row reads "4 holds", never "6 min".
- Field chrome — boxed inputs, underlined fields, uppercase labels stacked above values, sliders, rulers, dials, segmented unit pickers. The unit is a word beside the number.
- Per-workout settings.
- Coaching copy as permanent furniture. A tip appears once, or on demand.
- Stacked redundancy: one fact gets one rendering. The ring is the week; there is no second dot row beneath it.
- Fake chrome: no drawn status bar, no painted keyboard.
- Gradients, glass blur, any shadow beyond the light-mode card shadow, emoji as glyphs, icons from outside SF Symbols.
- Type below 10pt, tap targets below 44pt, text below 4.5:1 (3:1 at 24pt and above).

---

## 12. Implementation notes

- Ship every row of the colour table as an Asset Catalog Color Set with Any and Dark appearances, named exactly as the token. No colour literals in views.
- The ring: `Circle().trim(from: 0, to: progress).stroke(Color.accent, style: StrokeStyle(lineWidth: 16, lineCap: .round)).rotationEffect(.degrees(-90))` over a full `Circle().stroke(Color.ringTrack, lineWidth: 16)`.
- Numerals: a single `roundedNumber(_ size: CGFloat, _ weight: Font.Weight)` helper returning `.system(size:weight:design: .rounded)`, used everywhere a figure is displayed. Scale with `@ScaledMetric` or `.custom(_:relativeTo:)` so Dynamic Type still applies.
- Primary button: `.frame(height: 56).background(Color.ink, in: Capsule()).foregroundStyle(Color.onInk)`. One per screen — worth a lint rule or a debug assertion.
- Card: `.background(Color.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))` plus the two shadows only when `colorScheme == .light`.
- Accent budget: a debug-only check that counts accent usages per screen against section 3 will catch regressions faster than review will.
- Suggested test: snapshot each of the twelve screens in both modes at default and accessibility-XXL type on a 375pt width, and assert no vertical clipping.