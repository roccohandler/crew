# Crew — DESIGN.md

The single place design rules are READ from. It is a **cited digest** of `docs/crew-mvp-spec.md` and its Decision Registry
(Appendix A): every rule below names the section it comes from, and **the spec wins any conflict** (Appendix C). Nothing here is
new. To change a rule, change the spec through a registry entry, then this file. Values live in `shared/design-tokens.json` →
`EmberColors` / `EmberTokens` / `ember.css`; never type one inline (C7).

**The redesign (A28, owner-approved 2026-09-19).** The owner's ratified design system is `design/focus-card-system.md` (the Focus
Card system, from Claude Design). Where it is more precise than a rule here — a size, a weight, a string — it is the reference the
rule points to. **`design/targets/` holds the approved mockups**: twelve screens drawn light and dark at 390×844 (the first-day
Home is supplied in dark only). `ui-reviewer` judges every screenshot against this file AND the mockup that governs it, in the
matching mode — the map from mockup to tour shot is `design/targets/README.md`. A mockup is approved intent: a visible departure
from it is an issue unless this file explains it. Its seeded content (names, numbers, exercises) is illustrative, and where its
copy contradicts the spec the spec wins (e.g. no-plan Home's "Three questions…" — onboarding asks two, A21.1).

A screen not yet redesigned is judged against the rules A28 applies now — the colour table and accent's three places (§1), light
by default (§2), density (§3), touch and the accessibility gate (§4.2–§4.3, §7), states (§6) and copy (§8) — and fails where it
departs from them. Its layout and components stand until its own session (A28 (f): "as each screen's session redesigns it"): where
they differ from the Focus Card rules (§4.1's rhythm, the Component kit, the Placements, the Banned patterns' component items),
that is a NOTE naming its redesign session in `docs/mvp-definition.md` (R1 Home · R2 Logger · R3 Progress · R4 Plan · R5 Crew +
Manage crew · R6 Settings · R7 Nutrition), not an issue.

## 1. Colour — navy ink acts, orange is a point (A28 (a), (b); system §2, §3)

One table, both modes. Nothing in the UI uses a colour that is not on it.

| token | light (Varsity) | dark (Midnight) | job |
|---|---|---|---|
| `canvas` | #F7F1E4 | #0E1A2E | every page background |
| `card` | #FFFCF6 | #1B2A42 | cards and the sheet surface |
| `ink` | #142744 | #F2EEE6 | ALL text, glyphs, text buttons, steppers' ± , done checks and segments, heat-map done-days, day marks, the streak and ring numerals, the selected tab, the primary capsule's fill |
| `inkSecondary` | #4E5E78 | #95A6BE | secondary text, eyebrows, quiet fact rows, the off-season snowflake |
| `inkMuted` | #7E8496 | #687A93 | the unlit flame; **no text below 24 pt** |
| `hairlineOnCard` · `hairlineOnCanvas` | #EFE8D9 · #E6DCC8 | #26364E · #223049 | seams between surfaces — never a control's boundary |
| `controlBorder` | #D3C7AE | #33475F | the stepper's ring (its ink glyph is the control's mark) |
| `segmentEmpty` · `segmentCurrent` | #E0D6C0 · #A89C84 | #27384F · #5A6E88 | the segmented workout bar (done = ink) |
| `chevron` | #A89C84 | #5A6E88 | a row button's chevron |
| `ringTrack` · `heatEmpty` | #E0D6C0 · #E4E3E1 | #27384F · #27384F | the ring's track · an empty heat-map day |
| `tabBar` | #FBF7EE | #12203A | the tab bar |
| `accent` | #DE6400 | #FF8A2B | the three places in 1.1 — nothing else |
| `onInk` | #FFFCF6 | #0E1A2E | the label on an ink fill |
| `destructive` | #BC2A1C | #FF8575 | red, inside a destructive confirm only |
| `sheetScrim` | rgba(20,39,68,0.34) | rgba(4,9,17,0.58) | behind a sheet |

- **1.1 Orange is a point, not a field.** `accent` appears in exactly three places: the **flame glyph** (fill), the **weekly
  ring's progress arc** (stroke), and the **celebration's XP numeral and its unit** (text). The streak numeral, the ring's
  interior numeral, heat-map done-days and day marks are ink. Accent is never a background, never on a control, never behind
  text, never an area larger than a fingertip (A28 (b)). Ember laws ①–⑥ stand as read with A28 — ④ narrowed to these three
  places; ③'s one orange text is the XP numeral and unit at large-text size; ②, ⑤ and ⑥ read with the navy ink (R-083 (3), (4)).
- **1.2 The accent budget per screen** (system §3): zero on first-day Home, no-plan Home, the Logger's start, mid-set, whole-workout
  sheet and mobility checklist, and Progress; two (flame + ring) on training, rest and done Home; one (the ring) on off-season
  Home; three (flame, XP numeral, XP unit) on the celebration. Onboarding is pure ink-on-canvas (Part III, Onboarding).
- **1.3 The flame's states:** accent while the streak is alive · `inkMuted` at zero · off-season a snowflake in `inkSecondary`
  while the ring stays accent, because those workouts happened (A28 (b)). The numeral beside it is ink, except off-season, where
  it is `inkSecondary` as mockup 06 draws it. At zero it has no eyebrow, because nothing captions a streak of zero (A8, A18.1).
  The ring appears once the week holds a completed workout (A18.2, R-084 (1)). A rest or zero week can therefore show the unlit
  flame and its "0" alone, which spends no accent.
- **1.4 Ink is navy, not charcoal** (A28 (a)). The filled capsule inverts with the mode: navy fill + cream label in light, cream
  fill + navy label in dark. The two accents are one hue (27.0° / 26.9°) — the dark one is the light one lifted, never re-picked.
- **1.5 No third hue.** No green for done, no blue for links; **red only inside a destructive confirm sheet**, in both modes
  (A28 (a)). Missed is never red — a miss is a fact, not a verdict. One bounded exception stands until the owner answers GAP 6 in
  A28 (R7; R-084 reads the dark carbs fill as legal where it draws — on the canvas, never a card): A16's three macro identity colours, nutrition surfaces only, and no
  surface renders an accent element and a macro fill together (Part III law ⑥, A16).
- **1.6 A control's mark clears 3:1.** A hairline is a seam between surfaces, never a control's boundary. The stepper's
  `controlBorder` ring is ~1.6:1 by design; the ink glyph inside it is what says "control" (R-083 (2); 6.5, A18.11); a quiet fact
  row's mark is its `inkSecondary` text (5.84:1). A screen not yet redesigned that still draws an outline control draws it with
  `controlOutline` (now `inkMuted`, 3.32:1). Marks under 3:1 — `segmentEmpty`, `segmentCurrent`, `ringTrack`, `heatEmpty`,
  `chevron` — are never a state's only carrier (done is ink, the current segments are taller, counts are text; R-083 (25)).
- **1.7 Elevation** (system §6): light lifts a card with `card` plus the two-layer shadow `0 1 3 rgba(20,39,68,0.05)` and
  `0 14 34 rgba(20,39,68,0.08)`; dark uses tone alone — no shadow, no glow.

Legacy names (`inkText`, `secondaryText`, `ember`, `emberTint`, `controlOutline`, …) still exist as aliases of one table row each
so the app recolors without a screen edit; a redesigned screen uses the table's own names (`shared/design-tokens.json`
`colorAliases`; docs/debt.md).

## 2. Light is the default; dark is supported (A28 (a), amending A21.10)

Crew renders light by default and dark when the phone is dark — Varsity and Midnight are one system, and a screen is not done
until BOTH pass review against their mockups (`NN-…-light.png` / `NN-…-dark.png`). Dark lifts, never inverts (Ember law ⑤).
The Home session (R1) lifted the iOS light lock (A21.10 as amended 2026-09-18 — Info.plist and the root view): the phone follows
the system setting, and no dark pair a shipped screen draws fails its gate (R-084, GAP 6). The tour photographs each Home state in
both modes; a screen not yet redesigned keeps its light-only shots until its session adds the dark one. A dark screenshot is
judged against the dark mockup exactly as light is against light. The web keeps `color-scheme: light` until its parity session.

## 3. Density — screens stay simple (6.9, A25)

> Screens stay simple. No screen overloaded with information; prefer clear, well-sized buttons that navigate to the screen
> holding the information or action. (v1 failure mode.)

- **3.1** A screen has one job and **at most one filled (ink) primary button** — and several screens correctly have none (rest
  day, done — unless a session is open, R-083 (23)) (A28 (f); system §8).
- **3.2** Secondary information lives one tap away behind a labelled control, never stacked on the screen that links to it.
- **3.3** When a screen needs a second scroll-length of content to do its job, the content becomes a destination screen — never
  compressed to fit.
- **3.4** Density is never bought by shrinking targets or type (6.3).
- **3.5 One fact, one rendering** (system §11): the ring IS the week — no second dot row beneath it.

## 4. Layout, touch and rhythm (6.3, 6.7, G5, A14, A28 (d), (f))

- **4.1 Rhythm.** A redesigned screen takes the system's spacing (§5): a 4 pt base, used at 4, 6, 7, 8, 12, 13, 14, 15, 16, 18,
  20, 22, 26 and 30; screen gutter **20 pt** everywhere; card
  padding **22 pt** on Home and Progress; the set card and the checklist card **20 pt** horizontal and **15–16 pt** vertical per
  row; reward block to card **30 pt**; radii: capsule for every button, **28** cards and a sheet's top corners, **26** stepper,
  **14** check, **8** heat-map cell, **4 / 3** progress segments, **3** grabber — nothing else is rounded (R-083 (5): A28 (d)
  "per the mockups" and (f) "the component list" carry these; each enters `design-tokens.json` in the session that first draws
  it). A screen not yet redesigned keeps G5 and the `sizes` tokens: the scale 4 / 8 / 12 / 16 / 24 / 32, nothing off-scale;
  `sectionGap` 24 between groups, `rowGap` 8 within one (A14); corner radius 16; hairline 1 (R-083 (5)).
- **4.2 Touch targets ≥ 44×44 pt** · primaries in the thumb zone, bottom-anchored even at Pro Max — except Home, whose one primary
  sits inside its optically centred card (A28 (d)) · destructive never adjacent to primary · the session screen fully one-handed ·
  every swipe has a visible-button equivalent (6.3, 6.7). Every stated control height is a MINIMUM: the label wraps and the control
  grows at accessibility sizes (R-083 (20)).
- **4.3** Portrait only; every screen a single column. Safe-area-relative, zero hardcoded frames; content that can grow lives in a
  ScrollView; bottom CTAs sit above the home indicator; no truncated CTA label anywhere; nothing scrolls sideways (6.7). No status
  bar or keyboard is ever drawn — the real ones render on top (system §5).
- **4.4 The tab bar is hidden during a workout session** (A21.11). The five-tab bar — Home · Plan · Crew · Progress · Settings —
  is fixed; a sixth tab was considered and rejected (Part VII; Appendix A).
- **4.5 Dynamic Type** (system §10): at accessibility sizes the metric row breaks to numeral over steppers, a card's exercise rows
  break to name over target, checklist rows move the check below the cue, eyebrow-and-value pairs stack; the Progress heat map keeps
  seven columns and lets the cells shrink. Nothing truncates: the card grows and the screen scrolls — legible at accessibility-XXL
  on a 375 pt screen.

## 5. Feedback and motion (Part III Voice, 6.4)

- **5.1 Haptics only — no sound effects, ever.** The fixed language: `tick` set done · `double` exercise done · `thump` workout
  complete · `softTap` reaction received (6.4, G8). (The system's §10 names a different set — light per stepper tap and check,
  medium on Log set, one success on Finish, nothing else; no ruling adopts it yet — GAP 2 in A28, answered before the Logger session.)
- **5.2** One spring curve app-wide: response 0.35, damping 0.8 (G5). Celebrations ≤ 2.5 s, skippable on first tap. Reduce Motion
  gets static equivalents with identical information; no meaning by motion alone (6.4).
- **5.3 No timers of any kind** (A28 (c)): no rest countdown, no hold duration, no session clock, no elapsed minutes in a summary.
  Nothing happens between sets except the next set. A mobility row reads "4 holds", never "6 min". "Durations" are time spent
  training — rest, holds, the session clock, workout minutes, time estimates; a season's "N weeks", a pause's return date and its
  limit are calendar facts and stay (R-083 (6)). A cardio log's entered minutes stand until the owner answers GAP 4 (before R1).

## 6. States (6.1, A28 (f))

- **6.1** Every screen ships Loading → Success → Empty → Error → Offline, designed, not defaulted.
- **6.2 Loading is never a full-screen skeleton:** the real chrome at once, and the one thing still arriving says so in place
  (owner ruling 2026-09-18, "launch: real UI first").
- **6.3 Empty is an invitation, never an apology,** with exactly one CTA. **Error** = what happened + what to do, one sentence,
  always a retry. **Offline:** the core loop is unaffected; social shows last-synced and one thin banner. On a redesigned screen
  the states are built from the Component kit — a quiet line for loading and offline; an error is one sentence and the one filled
  "Try again" (R-083 (13)); a screen not yet redesigned keeps its banner.

## 7. Accessibility gate (6.5, release-blocking)

Text ≥ 4.5:1 (3:1 for large text: ≥ 24 pt, or ≥ 18.66 pt Bold — R-083 (3); the celebration's XP unit
is accent only at such a size) · components ≥ 3:1 · primary CTAs ink-fill (≈15:1) · `inkMuted` carries no text below
24 pt · no type below 10 pt, no target below 44 pt · usable at accessibility-XXL Dynamic Type with no critical action truncated ·
VoiceOver 100% labelled (every icon button carries a label) · Reduce Motion / Transparency honoured. `web/tests/contrast.test.ts`
asserts the table's pairs in both modes.

## 8. Copy (6.6, Part III Voice, A28 (e))

Serious, optimistic, unbothered — a training partner who respects you (A28 (e), the system's tone); zero drill-sergeant, zero
corporate wellness. Sentence case · contractions · verb-first CTAs of 1–3 words · no "please" / "successfully" / "!" in system copy · no
second-person imperatives outside button labels · never guilt framing, never red for missed · every notification names its
subject. An eyebrow renders uppercase by its type role; its string stays sentence case (R-083 (7)). Copy the owner already ratified (A23's
whispers, the protein line, 6.1's "what to do" error pattern, notifications) stands until its session re-cuts it with the
owner (R-083 (9); GAP 7).

**Crew speaks in seasons** (A28 (e); system §1). Fixed vocabulary: **in season · off-season · this season · best season ·
something beats nothing · a miss is a fact, not a verdict.** "Best season" is vocabulary only — no screen computes it until a
ruling defines it. Settled strings, shipped as written (the date in the system's long form):

| where | string |
|---|---|
| the plan reveal (A28 (e)); first-day Home's card sub-line per system §1 and mockup 01 — which, or both, is GAP 5 (before R1) | `Your season starts today` |
| Home, off-season (card sub-line) | `Off-season until Friday 25 September. Reminders are off.` |
| Home, off-season (streak label — an eyebrow, rendered OFF-SEASON by its type role, R-083 (7)) | `Off-season` |
| Home, rest day (card sub-line) | `Rest is part of the season. Nothing to do today.` |
| Progress (fact line) | `This season · 6 weeks · 18 workouts` — a label from the plan's history, no engine rule |
| Home, quiet fact row | `Macros · 2 logged` / `Macros · nothing logged yet` |
| Logger, phone-free path (drawn on Home, under the training-day card — mockup 03) | `Quick complete` |
| Mobility target, anywhere it is listed | `4 holds` — never a duration |

---

The four sections below are the OWNER'S. Direction, Component kit and Banned patterns are the Focus Card system's own words
(`design/focus-card-system.md`, ratified as A28, 2026-09-19); Screen jobs were ratified as A27 (2026-09-18).

## Direction

**Focus Card** (A28 (d)). Light mode is Varsity cream, dark mode is Midnight navy. SwiftUI, iOS 17, iPhone only, portrait.

Serious, optimistic, unbothered. The app never asks you to do anything and never scolds you for not; it states what is true and
what happens if you show up. It speaks in seasons: you are *in season* or *off-season*, you are *this season* or comparing
against your *best season*. A short workout counts, because *something beats nothing*. A missed day is reported and not judged,
because *a miss is a fact, not a verdict* — the streak shows what it shows, the ring fills as far as it filled, and nothing
anywhere says "don't break the chain" or "you've been away". No exclamation marks. No second-person imperatives outside button
labels. No encouragement that would sound strange said aloud by a training partner who respects you.

## Component kit (use X for Y)

**Screen types** (A28 (f); system §7) — every screen in the app is one of them; nothing else gets invented:

- **Home screen** — the reward block over one card, optically centred, with quiet rows beneath.
- **Set screen** — a header, one card of two metric rows, a fact line, one filled button.
- **Checklist screen** — a header with "Mark all done", a count line, one card of name-plus-cue rows each with a check. Mobility
  at the end of every workout; the same screen serves a warm-up at the start. The only screen type with more than one tick target.
- **Sheet** — a bottom surface with a grabber, a title row, list rows, one filled button.
- **Celebration** — a full-bleed centred stack, no nav.
- (The system names a sixth, the **data screen** — a large title, one fact line, one card carrying the figure; Progress is the
  first. A28 (f) lists five: GAP 1 in A28, answered before the Progress session.)

**Components** (system §8):

- **Primary button** — a filled `ink` capsule, `onInk` label at 17 pt Bold, 56 pt tall on Home and 58 pt elsewhere, corner radius
  always half the height. **At most one per screen**, and several screens correctly have none (rest day, done).
- **Text button** — a label alone in `ink`, 15 pt Semibold, 44 pt minimum tap height, no background, border or underline. Quick
  complete, Swap exercise, Skip, Whole workout, Mark all done, Edit today's log, Keep it private.
- **Quiet fact row** — the same 44 pt row, set entirely in `inkSecondary` at 15 pt Medium with its numeral rounded. States a fact
  and opens a screen on tap; carries no chevron and never looks like a control.
- **Stepper** — a 52 pt circle, 1.5 pt `controlBorder`, 22 pt `ink` glyph, no fill.
- **Icon button** — 44×44 transparent, 22 pt `ink` glyph, always an accessibility label.
- **Value button** — the big numeral itself, tappable, opening the numeric keypad. No box, no underline, no field chrome: the
  number is the control.
- **Check** — a 44 pt target holding a 28 pt circle: 2 pt `ink` ring when open, solid `ink` with an `onInk` tick when done.
- **Row button** — a full-width list row: name, value, chevron, 56 pt minimum, with the current row tinted one step off the sheet.
- **Weekly ring** — 140 pt box, radius 60, 16 pt stroke, round cap, rotated −90°, `ringTrack` beneath and `accent` above.
  Interior: the count at 46 pt Rounded Bold in `ink` over an 11 pt eyebrow in `inkSecondary`.
- **Segmented workout bar** — grouped by exercise, 4 pt gaps within a group and 14 pt between groups; the current exercise's
  segments are 8 pt tall and the rest 6 pt. Done is `ink`, current is `segmentCurrent`, pending is `segmentEmpty`. Each group is a
  44 pt-tall button that jumps to that exercise; the count at the right end opens the whole-workout sheet.
- **Heat map** — a 7-column grid, 30 pt cells, 7 pt gaps, radius 8. Done is `ink`, empty is `heatEmpty`.

**Radii.** Capsule for every button. 28 pt for cards and the sheet's top corners. 26 pt for the stepper, 14 pt for a check, 8 pt
for a heat-map cell, 4 pt and 3 pt for progress segments, 3 pt for the grabber. Nothing else is rounded.

**Type** (system §4; `EmberTokens.Typography` / `--ember-type-*`). SF Pro throughout — Display above 28 pt, Text below. **Every
numeral is SF Pro Rounded Bold**: set counts, weights, reps, streak, ring, XP, targets, week and workout counts. Words are never
rounded; numbers always are.

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

**Placements that are settled** (A28 (d); system §9): Home = the reward block (ring + flame) over one card with one filled
primary, then "Quick complete" as a text button and the quiet "Macros · N logged" row (absent under 18 — A28 (d), A22 G4, A16.c;
with no birth year on file it shows and leads to the one-time ask — A21.5); no reward block on the first day or with no plan (a zero is never shown as a verdict); rest and done days carry no
filled button unless a session is open, when "Resume workout" is the card's one primary (R-083 (23)), and the card carries
tomorrow; the `＋` in Home's nav bar offers Log cardio in every state with a plan and a bonus workout on rest and done days
(R-083 (22)); the crew strip stays off Home (A28 (d) — it is drawn only on the Crew tab). The Logger is one set per
screen: the last-time reference below the card on set 1, the running ledger of logged sets after it; Swap exercise and Skip as text;
**Finish lives in the whole-workout sheet** (reached from the bar — the early finish) and on the mobility checklist (the end of
the workout; R-083 (21)); Discard sits under `⋯` behind its destructive confirm; `+ set` and `+ warm-up` live in
the Logger's `⋯` menu; lb/kg lives in Settings.

## Banned patterns

(A28; system §11)

- Accent on anything interactive — buttons, tabs, links, toggles, selected states, checks, focus rings, and the workout progress
  bar, which is ink.
- Accent as a background or a fill of any area larger than a fingertip.
- A third hue. No green for done, no blue for links; red exists only inside a destructive confirm.
- More than one filled button on a screen.
- **Timers of every kind** — no rest countdown between sets, no hold duration, no session clock, no elapsed minutes in a summary.
  Nothing happens between sets except the next set. A row reads "4 holds", never "6 min".
- Field chrome — boxed inputs, underlined fields, uppercase labels stacked above values, sliders, rulers, dials, segmented unit
  pickers. The unit is a word beside the number.
- Per-workout settings.
- Coaching copy as permanent furniture. A tip appears once, or on demand.
- Stacked redundancy: one fact gets one rendering. The ring is the week; there is no second dot row beneath it.
- Fake chrome: no drawn status bar, no painted keyboard.
- Gradients, glass blur, any shadow beyond the light-mode card shadow, emoji as glyphs, icons from outside SF Symbols.
- Type below 10 pt, tap targets below 44 pt, text below 4.5:1 (3:1 at 24 pt and above).

Read with A28's readings: **platform-native controls** (6.8) — a text field, the keyboard, a date or time picker, a toggle, Sign in
with Apple — are admitted where a job cannot be done without one, drawn without field chrome and in the table's colours (R-083 (11));
**user content** — A21.2's five reactions, a crew's emoji, a caption — is not a glyph; the ban governs the app's own chrome
(R-083 (12)); "per-workout settings" are settings like the rest length and a session's unit, not plan content (R-083 (17)).

## Screen jobs

Ratified by the owner 2026-09-18 (Appendix A, A27) as the test `ui-reviewer` applies: the one job each screen exists to do.

**Onboarding**

- Intro: Say what Crew is and let me start, join, or log back in.
- Invite code: Take my friend's code and show me the crew it belongs to.
- Log in: Get me back into my account.
- Days question: Ask which days I train.
- Experience question: Ask how experienced I am.
- Plan reveal: Show me the week you built and let me change exercises I don't want.
- Save / sign up: Keep this plan by making me an account.

**Home**

- First day (bridge): Get me into my first workout.
- No plan: Get me to build a plan.
- Training day: Tell me what I'm training today and start it.
- Rest day: Tell me today is rest and keep my streak safe.
- Done: Confirm today is finished and show what I did.
- Paused: Remind me the plan is paused and let me end it.
- Rebuild sheet: Ask which days I train now.
- Bonus sheet: Let me pick a workout that isn't today's.
- Cardio log: Log the cardio I just did in a few taps.
- Reminder opt-in: Ask whether I want a nudge on workout days, and when.

**Plan**

- Week map: Show my week at a glance and let me change it.
- Change days: Ask which days I train from now on.
- Workout editor: Let me change one day's exercises, sets and order.
- Exercise sheet: Let me adjust, swap, move or remove this one exercise.
- Swap / Add exercise sheet: Let me pick a different exercise for this slot.

**Crew**

- Crew, solo: Explain what a crew does and get me to start or join one.
- Create crew: Name my crew and start it.
- Join by code: Take my friend's code and put me in their crew.
- Crew stream: Show me who showed up today and let me react.
- Invite sheet: Get the invite to my friends.
- Manage crew (new, per ruling b): Let me rename the crew, replace the link, remove a member, or leave.

**Progress**

- Charts: Show me whether I've been showing up, and whether I'm getting stronger.
- Journal: Let me look back at what I actually did, day by day.

**Session**

- Logger: Log each set as I do it, with as few taps as possible.
- Weight alert: Let me type an exact weight.
- Discard dialog: Confirm I'm throwing this workout away.
- Celebration: Show me what I just did and let me choose whether the crew sees it.

**Settings**

- Settings list: Let me find and change anything about my account, plan or privacy.
- Blocked people: Show who I've blocked and let me unblock them.
- Profile: Let me set my name and photo.
- Pause: Pause my plan until a date I pick.

**Nutrition (18+)**

- Today, first run: Turn my bodyweight into daily macro targets.
- Today: Show what's left to eat today and log a meal in one tap.
- Quick add: Log grams for something not in my saved meals.
- Logged today: Show everything I logged today and let me remove a mistake.
- Saved meals: Keep the meals I eat over and over.
- Template: Set the meals I eat on a normal day.
- Meal form: Enter or edit one meal's macros.
- Chain picker: Find a fast-food item and save it as a meal.
- Nutrition targets: Show and adjust my daily targets.
- How targets are estimated / How Crew works: Explain the reasoning and show the sources.

A control that does not serve its screen's job is a candidate for removal. A job with two homes has one too many.
