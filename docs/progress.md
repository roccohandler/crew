# Crew build progress

Updated: 2026-09-19 (**A28 REVIEW ROUNDS — HOME ROUND 3, THE LOGGER ROUND 2** — the review-rounds section. Before it **A28 R7 — NUTRITION**, the build order's last item. Before it **A28 R6 — SETTINGS, GROUPED**. Before it **A28 R5 — CREW AND MANAGE CREW**. Before it **A28 R4 — PLAN REDESIGNED**. Before it **A28 R3 — PROGRESS REDESIGNED**. Before it **A28 R2 — THE LOGGER REDESIGNED** — one set per screen, the whole-workout sheet, the checklist, the celebration; the R2 section. Before it **A28 R1 — HOME**; the owner's queued build order runs R1 → R7, GAPs read conservatively in R-084 / R-085) — earlier: 2026-09-19 10:30Z (**A28 R0 — TESTFLIGHT BUILD 205**: the rulings, the tokens, DESIGN.md, the worklist, from 575d8f3: CI run 35436938755 green, TestFlight run 35438217119 green) — earlier: 2026-09-19 06:14Z (**LATEST TESTFLIGHT BUILD: 204** — A27 (a) BUILT, the training-days history, V85–V90, from ca8f949: CI run 35423561463 green on five jobs, TestFlight run 35424726409 "Upload succeeded" 05:46Z; ui-reviewer 1 PASS · 9 FAIL, every FAIL pre-existing — the A27 (a) section) — earlier: build 202 — A23 EDUCATION COPY RATIFIED, from 3953313: CI run 35415601598 green on five jobs, TestFlight run 35416946917 "Upload succeeded" 02:56Z; ui-reviewer 2 PASS · 3 FAIL, every FAIL pre-existing — the A23 ratification section) — earlier: 2026-09-19 01:50Z (**TESTFLIGHT BUILD 201** — W7 ACTIVATED, from 0420cc9: CI run 35412369342 green on five jobs, TestFlight run 35413652316 "Upload succeeded" 01:48Z — the first build that carries `applinks:trycrew.fit`; its `aps-environment` after the export is UNCONFIRMED, see the W7 section) — earlier: 2026-09-19 00:45Z (**TESTFLIGHT BUILD 199** — A26 THE CANONICAL TEMPLATES, from a6bcfd6: CI run 35407920313 green on five jobs (one transport reset re-run), TestFlight run 35409987054 "Upload succeeded" 00:40Z; ui-reviewer: 12 A26 screens PASS, the long-name session card FAILS on three pre-existing findings only — all under the A26 section) — earlier: 2026-09-18 21:06Z (**TESTFLIGHT BUILD 193**, from e89d9f5 — CI run 35391799095 green on five jobs, TestFlight run 35394604478 "Upload succeeded" 21:05Z; the phone app is the same as build 191's (8c83a74, CI run 35387497620, TestFlight run 35390307268) — 192 is the docs-only design commit a5d2f9e, 193 is Q12, a server fix; the six-item "continue to full completion" order is DONE and on master, END row filled; Q12 repaid; design/INVENTORY.md + design/claude-design-brief/ committed) — earlier: 2026-09-18 (OWNER: A22 RULED G1 (a)–G4, the addendum RATIFIED Q1–Q3, "CONTINUE TO FULL COMPLETION" — the six-item order below; item 0 = the rulings recorded) — earlier: 2026-09-18 (A23 education layer drafted, pending the owner's line-by-line ratification of docs/education-copy-draft.md) — earlier: 2026-09-18 05:48Z (BUILD 150 UPLOADED — light always for real + "launch: real UI first" + W2 → W6; CI GREEN for it, run 35311124097; TestFlight repaired at build 145; W3 → W6 CI green at run 35302729856) — earlier: 2026-09-17 late (A22 plate-journal removal DRAFTED, pending G1–G4; W3 parked on wip/w3-crew-surface) — earlier: 2026-09-17 night (W2 gym-only DONE; the three A21 GAP readings owner-confirmed) — earlier: 2026-09-17 evening (A21 recorded in Appendix A; docs/mvp-definition.md; docs/nutrition-addendum-draft.md) — earlier: 2026-09-17 (audit report, gym-assumption map, the owner's test-account loop; git unblocked — the agent commits and pushes directly) — earlier: 2026-09-11 (A18 complete and tested; A19 RATIFIED and Stages A/B/D landed) — earlier: 2026-09-10 night (A18 — the fourth Home review)
on this Windows machine is green; the beta wiring — Vercel host, Apple keys, TestFlight, the device pass — is the open front)

This file was REWRITTEN FROM SCRATCH on 2026-09-08 after a cold-start audit that trusted no prior checkmark. Every
state below names the command that produced it TODAY. Four states:

- **DONE-VERIFIED** — its verify command was run on this machine today (or read from GitHub with `gh run view`) and passed
- **WRITTEN-UNVERIFIED** — Swift app code (SwiftUI / SwiftData / screens / XCUITests). No Mac here. The GitHub macOS job
  compiled it, ran 49 unit tests and journeys ①② on an iPhone 17 simulator (run 34252964640, green, 2026-09-08 16:45Z),
  but nothing has run on a device: gestures, haptics, camera, push, offline, VoiceOver, Dynamic Type remain unproven
- **PARTIAL** — part verified, part missing; the missing part is named
- **NOT STARTED**

## Audit evidence (2026-09-08, commands run here)

| Command | Result |
|---|---|
| `node shared/scripts/generate.mjs && node shared/scripts/check-drift.mjs` | generate done; all 7 Generated files match shared/; working tree unchanged |
| `node shared/scripts/check-vectors.mjs` | 51 vectors across 7 files — shape and invariants hold |
| `node shared/scripts/check-seeds.mjs` | 15 achievements · 101 exercises · 45 template lists — consistent |
| `node shared/scripts/doctrine-lint.mjs` | clean — 127 Swift files, 1 hand-written CSS file |
| `web: npm run typecheck` · `npm run lint` | exit 0 · exit 0 |
| `web: npm test` | 28 files, 285 tests passed (56 s; real in-memory MongoDB) |
| `web: npm run vectors` | 51 passed |
| `web: npm run build` | green |
| `web: npm audit --audit-level=high` | 0 vulnerabilities |
| `web: npm run e2e` | **22 passed, 1 skipped, 1 FAILED** — journey ① on phone-375 (WebKit): "Post" stayed disabled after the caption was filled. Re-run alone: passed (8.1 s). A hydration/value-tracker flake under three workers, not a product defect — queue Q02 |
| `docker run --rm -v "C:\Users\princ\CREW_2.0:/repo" -w /repo/ios swift:5.10 swift test` | 18 tests, 0 failures (all 51 vectors on the Swift engine) |
| `gh run view 34252964640` (HEAD e9fe41f, master) | contracts ✓ · web ✓ · web e2e ✓ · ios engine (Linux) ✓ · ios (xcodegen · build · unit + vectors · journeys ①②, macOS) ✓ |
| **After the gap closures (same evening)**: `npm test` · `npm run e2e` · docker swift test · doctrine-lint · check-drift | **31 files, 309 tests green** · **23 passed, 1 skipped (by design), 0 failed** on 375/768/1280 · **25 tests, 0 failures** · clean (132 Swift files) · clean |

Server route inventory (spec 5.2 + Part IV + docs/api.md): 32 route files, 45 exported methods. Every spec-required route
EXISTS and has a dedicated integration test plus the four standing checks — with two exceptions: `PATCH crews/[id]/mute`
EXISTS-BUT-UNTESTED beyond the standing checks (Q04), and `POST events` (promised by docs/api.md, R-004) is MISSING with no
client calling it (Q03). Secrets: only `web/.env.example` is tracked; `git log --all --full-history -- "*.env"` shows only
that file; `.env` and `.env.*` are gitignored; `web/.env` and a stray duplicate `ios/.env` exist locally with real values
(the owner is rotating the Resend and Blob keys). `.env.example` lacks `APP_STORE_URL` (read by the join page) — Q01.

## 2026-09-09 — the smoke-test amendments A1–A8 (owner-directed; Appendix A 2026-09-08; contract docs/improvement-plan-2026-09-08.md; ratification R-057)

The owner reviewed build 0.1.0 (2) on the phone and redirected the product: PPL-only rotation balanced over the months at any
days/week (A1), cardio tracked (A2), a rest-day Home that answers "what now / what's next" (A3), a two-level plan editor (A4), a
Crew tab that explains itself (A5), a journal with day labels and summary lines (A6), fuller Settings (A7), the copy law (A8).
State after the build (commands run 2026-09-09 morning):

| Area | State | Evidence |
|---|---|---|
| shared: constants (cardio, journal, planEstimateRoundingMinutes, distanceDecimalScale GAP), 9 cardio seed rows, check-seeds rules, V51 | DONE-VERIFIED | generate + check-drift ok · check-vectors 52/7 files · check-seeds 110 exercises · doctrine-lint clean (165 Swift files) |
| engine twins PlanGenerator (A1), PlanRotation, DayLabel, SessionSummaryLine | DONE-VERIFIED both engines | `npm run vectors` 52 · `npx vitest run tests/engine` green · docker `swift test` **43 tests, 0 failures** |
| server: plan shape + legacy normaliser, sessions workoutKind/distanceMeters/summary, rotation in today-state/cron/notification-facts, progress minutes, notificationPrefs, GET blocks, profilePhotoKey ownership, docs/api.md | DONE-VERIFIED | `npm test` **34 files, 340 tests** · typecheck + lint clean |
| web: Home (A3), /session/new + done, /log-cardio, CardioRow, /plan week map + /plan/[kind] editor + sheet, onboarding projection, Crew (A5), journal + progress (A6), Settings + /privacy + /terms (A7) | DONE-VERIFIED | `npm run build` green · `npm run e2e` **23 passed, 1 skipped (by design)** at 375/768/1280 (journeys ①②③④ + a11y incl. /plan/push, /log-cardio, /privacy, /terms) |
| iOS: Storage/Api/Sync (A1 shapes, A3 sync fixes), Home + CardioLog (A3), Plan editor (A4), Session CardioRow + Journal/Progress (A2/A6), Crew + Settings (A5/A7) — ~95 Swift files changed or added | WRITTEN-UNVERIFIED | no Xcode here; every file self-checked plus one compile-risk read (R-057); doctrine-lint clean; the macOS CI job compiles it on the next push |

Deviations and parking lot: docs/debt.md 2026-09-09 lines. Owner asks: ratify A1–A8 + the two GAP constants; decide ≤ 2-day full-body
vs PPL (built as PPL, evidence favours full-body); replace the placeholder legal pages; connect the Blob store.

## 2026-09-09 (evening) — the second phone review: A9–A16 (owner-directed; contract docs/ux-plan-2026-09-09.md)

The owner reviewed build 0.1.0 (3) on the phone and directed a UI/UX pass on Home and the Session screen, plus a new
nutrition subsystem. Decisions are drafted into Appendix A as **A9–A16, PENDING RATIFICATION**; the full contract with
the evidence, wireframes, palette and a W001–W067 checklist is `docs/ux-plan-2026-09-09.md`.

Evidence: a 13-agent repo review + 6-agent nutrition research (~2.4M tokens) covering Home, Session, the units
subsystem, exercise data, the design system, spec doctrine, web parity, nutrition, and outside research on numeric
entry, unit prompting, whitespace, exercise media licensing, macro tracking, the flex-budget pattern, macro colour and
food data.

**Two defects the review found that the owner had not reported, and which outrank what he did report:**

1. **Units silently corrupt history.** No conversion code exists anywhere. Switching kg/lb relabels every stored weight,
   changes PlateMath's physical prescription, and corrupts PR detection. Logged in debt.md; fixed by A9 (stage 1).
2. **Sets never prefill.** Every strength set opens at "—" while `lastTimeLine` computes the exact numbers needed and
   renders them as grey text — so reaching 225 lb costs 45 taps. Flow 3 already promises the prefill. Fixed by A12.

**Ordering is load-bearing:** units (A9) lands first because the weight tape renders a unit, the exercise sheet shows a
last-time line in a unit, and macro targets are computed from a bodyweight in a unit.

| Stage | Task IDs | State |
|---|---|---|
| 0 · amendments on paper | W001–W004 | **DONE-VERIFIED** — A9–A16 in Appendix A; **RATIFIED 2026-09-10**; 11 debt entries logged |
| 1 · units (A9) | W005–W015 | **DONE-VERIFIED** — vectors 52→54 · web 340→365 tests · Swift 43→53 tests · e2e 23 pass · all lints clean |
| 2 · session correctness sweep | W016–W026 | **DONE** (WRITTEN-UNVERIFIED on device) — 11 defect fixes; swift-xref + doctrine-lint clean, Swift 63 tests green |
| 3 · prefill (A12) | W027–W029 | **DONE-VERIFIED** — SetPrefill twin both engines (10+10 tests), wired into iOS and web session creation; web 375 tests, e2e 23 pass |
| 4 · weight tape (A10) | W030–W034 | **DONE** (WRITTEN-UNVERIFIED on device) — WeightTape on the open row + keypad + ± ; web gets a number field; 6 new constants; all local gates green |
| 5 · remove a set (A11) | W035–W038 | **DONE** (WRITTEN-UNVERIFIED on device) — SetRemoval twin + V54/V55 both engines, swipe-to-reveal + accessibility action + Undo, server floor guard |
| 7 · change today's workout (A15) | W047–W052 | NOT STARTED — unblocked, follows Stage 6 |
| 6 · Home + three vectors (A14) | W039–W046 | **DONE** (WRITTEN-UNVERIFIED on device) — week strip, the day's rows on the card, three-vector row, bridge ring removed, bottom anchor, cardio post type; HomeLines twin both engines; web 377→389 tests, Swift 63→70, no vector changed |
| 8 · exercise media (A13) | W053–W059, W068–W069 | GATED on ⏳ W053 (lawyer). Art ruled: **vendor** bryllim/workout-guide; prep allowed behind a flag, no TestFlight ship |
| 9 · nutrition (A16) | W060–W067, W070–W073 | A16 RATIFIED (W060 ✓). GATED on ⏳ W070 (age questionnaire) |

### 2026-09-10 — OWNER RATIFICATION (Appendix A entry 2026-09-10)

**A9–A15 RATIFIED** as drafted and as implemented through Stage 5. **A16 RATIFIED, MAINTENANCE-ONLY** — no deficit, no
deficit phase, no deficit constants, no sex field, no body stat beyond the single current bodyweight; a deficit would be
a separate amendment with its own phase and compliance checklist, and is **not stubbed for**. The five overturns are
applied in the spec exactly as tabled (spec:240 narrowed + the seven no-grade clauses · spec:1490's plate-journal rule
unchanged · spec:1490's "no goals system" narrowed to training · spec:340 E1's bounded bodyweight exception · spec:396
Ember law ⑥'s macro-token exception · spec:453 restated). Three owner additions: **A16.a** methodology screen (required),
**A16.b** age-questionnaire re-run as a Stage 9 entry gate, **A16.c** 18+ gate on the target surface (the app stays 13+,
`minimumAgeYears` 13 unchanged). **A13 art ruled:** vendor bryllim/workout-guide (CC BY-SA 4.0), never edited on disk, hash
manifest as the machine-checked ShareAlike boundary — Stage 8 still gated on the lawyer answer. Stages 6 and 7 proceed now.

**⏳ THE THREE OPEN OWNER ITEMS (each blocks only what it names):**

*(Status 2026-09-18, the text below is the 2026-09-10 record and is not rewritten: item 1, W070, now gates ONLY the App Store submission — nutrition is built, owner order of 2026-09-18, see Blockers · item 2, W053, is post-MVP under A21.13 · item 3, the A16.c GAP, is CLOSED by A21.5.)*

1. **⏳ W070 — OWNER re-answers the App Store Connect age questionnaire with A16 in mind, and the resulting rating is
   recorded here. Stage 9 does not start until that rating is recorded.** Apple's 2025 questionnaire carries a mandatory
   medical/wellness section; adding calorie targets changes the honest answer, and Apple may raise the rating above 13+.
2. **⏳ W053 — OWNER lawyer confirmation** on bundling unmodified CC BY-SA 4.0 SVGs inside a FairPlay-protected iOS app
   (CC 4.0's Effective Technological Measures clause), tinted at runtime and fully attributed. Vendored assets, the hash
   test and the attribution screen may be PREPARED behind a feature flag; **nothing ships to a TestFlight build until
   this clears.** Fallback order if the answer is no: (1) RepDB free tier, (2) exercisedb.io $199 Starter. Neither is
   pre-built.
3. **⏳ GAP (A16.c, recorded not resolved) — the account stores a birth YEAR, not a birthdate, and it is OPTIONAL on the
   Sign in with Apple path (`LoginScreen` passes `nil`), so an account can carry no age at all.** Conservative reading adopted,
   and the one Stage 9 implements unless the owner rules otherwise: age = `currentYear − birthYear` (the arithmetic
   `requireSignupGates` already uses), and an **absent birth year reads as under 18** — the surface is hidden, nothing is
   asked, and no existing account is re-prompted. Recorded here because it lands inside the same owner task as item 1.

## 2026-09-10 (night) — A18, THE FOURTH HOME REVIEW (owner-directed; Appendix A entry A18.1–A18.13; contract docs/home-plan-a18-2026-09-10.md)

The owner looked at the rest-day Home that the A17 pass produced and asked four questions: **what is the 1/3 · why is
there a big blank space · why does the card saying rest day have a Post a meal CTA · why are there three strange divs
at the bottom**. The lead sentence matters more than any of them: *"the next action isn't clear."* A17 answered "what
are the colours for" and did not answer "what do I do now", and its reordered stack is the void in the screenshot.

Evidence: a 45-agent review (7 repo lenses + 6 outside-research lenses, 124 findings, 10 load-bearing claims through 3
adversarial verifiers each, a synthesis and a completeness critic). The owner then answered **sixteen** questions; every
answer is carried in the registry entry and in §0 of the plan.

**What shipped** — all thirteen clauses, on both engines:

| Clause | Change |
|---|---|
| A18.1 | every numeral is NAMED where it sits: "day streak" under the flame, "workouts this week" under the ring |
| A18.2 | the ring renders only above zero done — it printed "0/3" on every non-bridge **Monday**, the same A8 violation that got it removed from the bridge, on six states nobody checked |
| A18.3 | the what's-next fact is a titled BLOCK above the card on rest/all-done (not on a workout day: that card IS what is next, and it is the tallest state) |
| A18.4 | the rest card states its PREMISE — "Rest days count too — post anything and your N-day streak holds" |
| A18.5 | the three vectors become three FULL-WIDTH VERB rows ("Log workout"), not three equal-width noun cells wearing the silhouette of a segmented control |
| A18.6 | paused: pause-aware week marks, no ring, **"End the pause now"** on the card, and the **web pause guard** iOS had and web never mirrored |
| A18.7 | every planned day gets a mark (A17.4 marked only the next one, so a 4-day plan's ring said "of 4" over a strip that could account for 3) |
| A18.8 | the bridge carries ONE CTA even with a session open — it absorbs the resume instead of a second banner beside it |
| A18.9 | the all-done card reports the day in the journal's own sentence and carries no control |
| A18.10 | the toolbar camera is dropped wherever the card already offers a meal CTA |
| A18.11 | **`controlOutline`** #938C83 / #726A61 — every outline control in the app drew its boundary at 1.26:1 against a 3:1 gate; the debt is repaid at the token, not per-site |
| A18.12 | Home's `.offline` state is REACHABLE (it was declared and assigned nowhere; the banner had never rendered) |
| A18.13 | the streak's daily-vs-weekly cadence is RECORDED as an open owner decision, not changed |

Plus **twelve pure defects** (J021–J032): the web pause guard, a bonus workout marking the week differently on the two
engines, web's Workout row going to /plan on a paused day, the flame's ARIA on a bare `<div>`, next-up ink-vs-grey
parity, ring geometry diverging by a third, and two false source comments that would have been quoted against the next
decision (one said rest carries no filled primary twelve lines above the code that renders one; one said a bonus while
paused earns +25 when V20 says it earns zero).

**Commands run here, 2026-09-10 night:**

| Command | Result |
|---|---|
| `generate.mjs && check-drift.mjs` | all 7 Generated files match shared/ |
| `check-vectors.mjs` · `check-seeds.mjs` | 56 vectors across 9 files · 15 achievements / 110 exercises / 45 lists |
| `doctrine-lint.mjs` · `swift-xref.mjs` | clean — 192 Swift files · 192 files, 377 types, clean |
| web: `npm run typecheck` · `npm run lint` | exit 0 · exit 0 |
| web: `npm test` | **42 files, 446 tests** (436 → 446: J028 adds the first-ever tests for `today-state.ts`) |
| web: `npm run vectors` | 56 passed |
| web: `npm run e2e` | **32 passed, 1 skipped (by design), 0 failed** — the layout gate now runs at 375×667, 393×852 AND 440×956 |
| web: `npm run build` | green |
| `docker swift test` (Linux engine + vectors) | **76 tests, 0 failures** |

**A18 ADDED NO VECTOR, and that is a ruling, not an omission** — the vector suite is the gamification fixture contract
and A18 changes no rule that engine runs; the pause-aware week marks are a reporting function that awards nothing.
V57–V64 stay reserved for A16 (nutrition); the next free id is still V57.

**WRITTEN-UNVERIFIED, stated plainly:** every iOS view file in this pass. The full-width log rows, the two captions,
the next-up block, the paused control, the bridge's absorbed resume and the reachable offline banner have never
rendered on a simulator or a device from this machine. The macOS CI job compiles them and now **photographs all four
non-bridge Home states into the run artifact** (J034, `CrewUITests/HomeStatesTests.swift`) — before this, the only
non-bridge Home CI had ever rendered was a workout day, which is how a rest-day defect and a paused state that
contradicted its own copy both reached TestFlight with every job green.

**The one measurement this pass made that it did NOT fix**, because it is outside A18's ratified scope: Home's bottom
anchor is a `Spacer` inside scrolling content, which collapses to zero the moment content exceeds the viewport. The
new gate measured the rest-day Home at **24 px gap on 375×667 (the spacer is already fully collapsed and the page
overflows), 108 px on 393×852, 212 px on 440×956**. So 6.7's "primary actions stay bottom-anchored regardless of how
much canvas exists above" holds on the smallest phone by accident rather than by mechanism, and every element A18
added moves that collapse onto more devices. Logged in debt.md; it is the first item of the next pass.

## 2026-09-11 — A19 RATIFIED, AND STAGES A / B / D LANDED (Appendix A entry A19.1–A19.6; contract docs/ios-ux-audit-2026-09-10.md; handoff docs/a19-handoff-prompt.md)

The owner ratified the app-wide interaction-ergonomics audit **as drafted** and ruled on the three gate items:
**R4 → shape (b)** (the celebration's inert share toggle becomes two buttons — primary "Share to crew", text "Keep it
private" — which removes a control and, unlike shape (a), keeps post visibility out of the completion inputs so it
needs **no new vector**); **Journal → a segment inside Progress** (Charts / Journal; the five-tab set is unchanged);
and the **ordering**: A18 tail → A19 Stage A → Stages B/D → **A15** → Stages C/E/F.

**THE FINDING THAT MADE STAGE A FIRST.** `safeAreaInset` had ZERO uses in the app. Every "bottom-anchored" primary was
a `Spacer` inside scrolling content (which collapses to zero the moment content exceeds the viewport), a `VStack`
sibling (which just scrolls away), or an `overlay` with hand-computed padding that guessed the home indicator's
height differently in each file. A18's own new layout gate measured it: the rest-day Home's largest gap is 212 px at
440×956 and **24 px at 375×667 — small there precisely BECAUSE the page already overflows and the anchor has already
collapsed.** So 6.7's "primary actions stay bottom-anchored regardless of how much canvas exists above" has never been
mechanically true anywhere; it has been true only while each screen happened to fit.

**Stage A — the mechanism.** New `ios/Crew/Shared/BottomBar.swift`: one `.crewBottomBar { }` modifier over
`safeAreaInset(edge: .bottom)`, `controlOutline` top edge, `@ScaledMetric` metrics, and **conditional** — a screen with
no primary gets no bar, because A17.3 and A18.9 both rule that a day asking nothing carries no filled primary.
Adopted, lowest-risk first: **GeneratedPlanScreen · NutritionPostScreen · CardioLogScreen · SessionScreen ·
LoginScreen · SaveAuthScreen**.

**Stage B — the dead ends.** `ToolbarItemGroup(placement: .keyboard)` Done on every numeric pad — `.numberPad` and
`.decimalPad` ship no return key, so the cardio distance field and the birth-year field could be focused with no way
to dismiss the keyboard and no way to reach the button beneath it; the only escape was the back gesture, which throws
the entry away. (R3 Apple-failure and R6 VoiceOver-react were already in the tree.)

**Stage D — the ergonomic inversions.** R9: the `Spacer` moved ABOVE the options in `SingleSelectQuestion` and above
Save in `EditProfileScreen` — the only action on the onboarding questions sat at the top of the screen with ~400 pt of
dead canvas beneath it, the exact defect A17.2 fixed on Home and never applied anywhere else. R10: `ScrollView`
overflow valves on `IntroScreen` and both question screens (6.7 makes this non-negotiable at accessibility-XXL).
R5: **"Discard workout" is out of the session's scroll tail**, where it sat immediately above the Complete primary —
6.3 forbids a destructive control adjacent to a primary, and that adjacency happened at the exact moment the user
reached for Complete. It is a nav-bar item now, still two-step, at the other end of the screen.

**A18.11's token sweep finished on iOS.** A18 moved SecondaryButton and Home's log rows onto `controlOutline`; A19
found **nine more control boundaries** still drawing at 1.26:1 — the day toggle, the onboarding option cards, the
meal-tag chips, the activity tiles, the set ±, the cardio Done, the bonus-workout rows, the plan week rows (which
switch to the surface colour when the row is NOT interactive) and the signup text fields. `contrast.test.ts` now
sweeps **every** Swift file with an explicit five-entry allowlist of the surfaces still entitled to a hairline (the
Card, the EquipmentChip label, the "Sending ↻" status chip, the unit banner, the Undo snackbar), so a new control that
reaches for the old token fails the suite rather than shipping invisible.

**NOT DONE, and deliberately:**
- **Home has NOT adopted the bar.** A19.1 ratifies "Home last … let A18's tests land first", and A18's iOS half has
  never compiled on a Mac. Home's adoption follows the first green CI run on it.
- **WorkoutEditorScreen has NOT adopted the bar.** Its primary lives in the nav bar, so moving it IS R11 — Stage E,
  which the ratified ordering puts after A15.
- **Stage C (R4)** is ruled but not built: the ordering places it after A15.
- **No web twins are owed for these stages** (6.8): web has no session Discard, its Apple sign-in is a server-side
  callback rather than `ASAuthorization`, and browsers provide their own keyboard dismissal. R4's and R13's twins move
  with Stages C and E.

**Commands run here, 2026-09-11:**

| Command | Result |
|---|---|
| `generate.mjs && check-drift.mjs` · `check-vectors.mjs` · `check-seeds.mjs` | Generated files match · 56 vectors / 9 files · seeds consistent |
| `doctrine-lint.mjs` · `swift-xref.mjs` | clean — 193 Swift files · 193 files, 379 types, clean |
| web: `typecheck` · `lint` | exit 0 · exit 0 |
| web: `npm test` | **42 files, 445 tests** |
| web: `npm run vectors` | 56 passed |
| web: `npm run e2e` | **32 passed, 1 skipped (by design), 0 failed** |
| `docker swift test` | **76 tests, 0 failures** |

Every iOS change in A19 so far is **WRITTEN-UNVERIFIED**: `safeAreaInset`, `ToolbarItemGroup(placement: .keyboard)`
and the re-parented scroll views have never rendered from this machine. swift-xref checks call shapes, doctrine-lint
checks structure; neither compiles SwiftUI. **The macOS CI job is the first real verification**, and the next thing to
do with A19 is read it.

### CI run 34586326598 (push = F40–F42, 2026-09-11 09:51Z) — RED on ONE compile error, and TestFlight correctly refused to ship

`shared contracts` ✓ · `web` ✓ · `ios engine (Linux)` ✓ · **`ios` ✗** · `testflight` **skipped in 1 s** — which is the
new `workflow_run` gate doing exactly its job: `conclusion == success` was false, so nothing was uploaded. That is the
first proof the F39 wiring is safe as well as automatic.

The one diagnostic: `SettingsModel.swift:95: cannot find 'userId' in scope` — A18.6c's line clearing the LocalPause
after the API call referenced `userId` as a property when it is a LOCAL inside `pause(until:)`. **This is the shape
swift-xref cannot catch**: it label-checks call shapes, and this is scope resolution, so the file passed every local
gate and failed on the runner. Twenty-six never-compiled Swift files across A18 and A19 produced exactly one error.

A second defect the run did not see, found re-running the suite locally afterwards: `today-state.test.ts`'s pause
fixture built its window from THREE DAYS AGO, which on a **Friday** leaves Monday outside it — and a planned Monday
*before* a pause began is a genuine miss, so the engine was right and the fixture was wrong. It passed on the Thursday
it was written and went red the next morning. The window now starts at the ISO week key, true on every weekday.

Fix = F43. Local gates re-run after it: swift-xref clean · doctrine-lint clean · check-drift clean · check-vectors 56 ·
`swift test` 76/0 · web typecheck + lint clean · `npm test` 42 files / 445 tests · `npm run vectors` 56 · `npm run e2e`
32 passed, 1 skipped.

**NEXT:** A15 (Stage 7, "change today's workout") per the ratified ordering — after the CI run that compiles A18 + A19
Stages A/B/D, so Home's bar adoption and the editor's R11 can follow on proven ground.

## 2026-09-12 — A20, THE FIFTH HOME REVIEW (owner-directed; contract docs/home-plan-a20-2026-09-11.md)

The owner reviewed the shipped Home and reported **"it looks too complicated and things don't look like they're
syncing"**, with a mockup from another agent that he liked. Evidence: an **87-agent investigation** (7 repo lenses +
6 outside-research lenses, 200 findings, 24 load-bearing claims through 3 adversarial verifiers each — **6 survived,
18 were refuted**). He then answered **28 questions across 7 rounds**; every ruling is §1 of the plan.

**THE FINDING THAT REFRAMED THE BRIEF.** The mockup's dark palette is not a new design — **it is Crew's existing dark
theme**. `shared/design-tokens.json` carries a light AND a dark hex for all 16 colour tokens, `EmberColors.swift`
builds each as a dynamic `UIColor`, `ember.css` has the `prefers-color-scheme` block, and `project.yml` is
`UIUserInterfaceStyle: Automatic`. The owner was comparing a **light-mode screenshot** against a **dark-mode mockup**.
Dark costs zero engineering — but **no test, e2e spec, layout gate or CI screenshot on either engine has ever rendered
a dark screen**, so it is mechanically correct and visually unverified. Ruling: keep system-following; photograph it.

**"Too complicated" is a TREATMENT problem, not a fact problem** — Home renders **13 distinct `.font()` expressions
across 9 sizes**, and `design-tokens.json` has **no typography key at all**, so every size in the app is a per-file
decision and web sets its own inline with no parity test. Four Home passes have walked past this. Plus the state name
renders **twice verbatim** on three of four states, the week is encoded **three ways**, and today's workout is
reachable from **three controls at three weights**.

**"Doesn't look like it's syncing" is LITERALLY TRUE — four bugs, none of which a layout change fixes.** All four are
fixed in Build A below.

### Build A — DONE, QUEUED AS F45, NOT YET PUSHED (owner runs the queue)

| Fix | What it was |
|---|---|
| **S2 / A20.10** | `LocalPause` had ONE writer in the app (`SettingsModel.pause`); `ServerHydrate` pulled every other server truth and not this one. A pause made on web, or predating a reinstall, never reached the phone — Settings said "Plan paused" while Home offered Start workout. **`HomeStatesTests.testPausedFreezes…` has been failing on exactly this since it was written.** |
| **S1** | `loadState` was `@State` assigned in ONE place while **eight** paths call `refresh()` directly — so the offline/error layer was whatever it had been at the last foreground. Now computed over the `@Observable` model (the pattern `CrewScreen.swift:21-26` already used). |
| **S3** | `SyncQueue` is `@Observable`; `offline` stops being a snapshot taken BEFORE the drain that discovers the network is gone, and sticky after. |
| **S4 / A20.10** | Home's cardio row counted only `workoutKind == "cardio"` while Progress sums cardio from every session — a bike block inside a push day read "nothing logged today" on one tab and reported minutes on the next. Fixed on **both** engines. |
| **A20.9** | The offline banner drew `#FFFFFF` on `#FAF8F5` — **1.06:1** — behind a 1.19:1 edge, no glyph, a constant sentence. It now carries 6.1's real "last synced" time and the queued count Home never had. |
| **T-A1** | `testRestDayNames…` demanded the UNPOSTED premise line on a state that must post to leave the bridge (§1D), so only "Today counts." is reachable — the engine was right, the assertion was wrong. |
| **T-A3** | The other three reds are one race at one field: `Birth year` is the only `.numberPad` on S05 and the last of five, and A19.1's `safeAreaInset` + A19.2's Done bar both animate against that edge. Step synchronised (`typeInto`); Done bar scoped to the one field with no return key. **Hypothesis — see debt.md.** |

**A20 ADDS NO VECTOR, and that is a ruling.** The 56 vectors are the gamification fixture contract; the pause is an
existing server fact moving onto the phone and the cardio row is a reporting function that awards nothing — the same
reasoning A18 recorded and A19 followed. V57–V64 stay reserved for A16; next free id is still **V57**.

**Commands run here, 2026-09-12:**

| Command | Result |
|---|---|
| `generate.mjs` · `check-drift.mjs` | all 7 Generated files match shared/ |
| `check-vectors.mjs` · `check-seeds.mjs` | 56 vectors / 9 files · 15 achievements / 110 exercises / 45 lists |
| `doctrine-lint.mjs` · `swift-xref.mjs` | clean — **194** Swift files · 194 files, 379 types, clean |
| web: `typecheck` · `lint` | exit 0 · exit 0 |
| web: `npm test` | **42 files, 446 tests** (445 → 446: the A20.10 cardio-in-a-workout twin) |
| web: `npm run vectors` | 56 passed |
| web: `npm run e2e` | **32 passed, 1 skipped, 0 failed** |
| `docker swift test` | **76 tests, 0 failures** |

`SyncQueue.swift` and `HomeModel.swift` both crossed the C9 200-line cap; the E19 held-op half split into
`SyncQueueHeld.swift`, the way `HomeModel+Edges.swift` already splits HomeModel. **Note for the next session:
`doctrine-lint` splits on `\n`, so a file with 200 real lines reports 201 — the effective cap is 199.**

**STILL WRITTEN-UNVERIFIED:** every Swift change here. No Mac. CI is the first real verification, and the two Home UI
tests are the acceptance gate for the two product fixes.

### Build B — DONE, QUEUED AS F46, **DO NOT PUSH UNTIL F45's CI IS GREEN** (owner ruling #4)

| Clause | Change |
|---|---|
| **A20.12** | **The app gets typography tokens.** Part III specified colour, spacing, motion and haptics and never TYPE — Home alone rendered **13 distinct `.font()` expressions across 9 semantic sizes**, and web set its own inline with no parity test. Five roles now generate to both engines on the spacing scale's own path; iOS names SEMANTIC styles so Dynamic Type still scales them. This is the measured driver of "looks complicated", and four Home passes had walked past it. |
| **A20.1** | The day's card becomes **row one of TODAY'S LOG**. Kills three duplicate routes to one intent (card primary, Quick complete, log row) — four with a session open. |
| **A20.2** | Verb title + status subtitle. Three workout grammars: plan fact → live fraction → done summary. **No branch prints a zero** (A8). |
| **A20.3** | One target per row, chevron, no inner pill. The **one named exception** is the workout row's quick-complete mark. |
| **A20.4** | The ring becomes a named fraction, carrying A18.2's above-zero gate verbatim. `WeeklyRing` stays for Progress. |
| **A20.5** | The open session is the row's subtitle. The Resume banner is gone — and with it a live iOS/web disagreement. |
| **A20.6** | Crew strip leaves Home; the shield **folds into the streak line** rather than being dropped (it is the one fact here with no neighbour). The week leads, the streak demotes. |
| **A20.7** | A date line above the title. **A17.4(c) reaffirmed** — what's deleted is the card headline that repeated the title verbatim. New `todayHeader` twin on both engines, reading the day `refresh()` judged and never the wall clock. |
| **A20.8** | Home adopts `.crewBottomBar`, **per state**. `Bar` is a compile-time type, so a ViewBuilder switching to `EmptyView` yields `_ConditionalContent` and the modifier would still have drawn a rule and an inset on the states A17.3/A18.9 cleared. **A19.1's paragraph claimed the modifier handled this and it did not** — corrected in the source. |
| **A20.11** | Meal count only. No kcal: A16 clause ⑥ and the owner's still-open ⏳ W070. |
| **A20.13** | **The dark appearance is photographed** — the first time any test on either engine renders it. |

**Commands run here after Build B, 2026-09-12:**

| Command | Result |
|---|---|
| `check-drift` · `check-vectors` · `check-seeds` | match · 56 / 9 files · consistent |
| `doctrine-lint` · `swift-xref` | clean — **196** Swift files · 196 files, 383 types, clean |
| web: `typecheck` · `lint` · `build` | exit 0 · exit 0 · green |
| web: `npm test` | **42 files, 448 tests** (446 → 448: the `todayHeader` twin + the type-parity check) |
| web: `npm run vectors` | 56 passed |
| web: `npm run e2e` | **32 passed, 1 skipped, 0 failed** |
| `docker swift test` | **77 tests, 0 failures** (76 → 77: `DayLabel.todayHeader`, compiled and passing on Linux) |

**Two Swift-only traps were caught here rather than by a 13-minute CI round trip:** `enum Type` inside `EmberTokens`
would have been ambiguous with Swift's metatype syntax (`EmberTokens.Type`) — the generator emits `Typography`, and
`token-parity.test.ts` now asserts it; and `dateLine` initially read `Date()` instead of the day `refresh()` judged,
which would have made its test date-dependent and the screen able to state a different day than the state beneath it.

**Also note for the next session:** `doctrine-lint` counts `split("\n").length`, so a file of 200 real lines reports
201 — **the effective C9 cap is 199.** Three files were re-split under it this pass (`SyncQueueHeld.swift`,
`HomeModel+Rows.swift`, `HomeLogRowsTests.swift`).

### 2026-09-15 — F45 PUSHED AND WENT RED IN 9 SECONDS. F47 IS THE FIX.

Run **34918410611** (HEAD 983ff87) failed the FIRST job, `shared contracts`, on `swift-xref`: 2 findings, both
`EmberTokens.Typography — EmberTokens declares no member "Typography"`. The `ios` job never started.

**The cause is this repo's own documented queue rule, and it was read and then violated.** `docs/commit-queue.sh`'s
header says *"a block stages every listed path that has changes, so a later EDIT to a file lands in the FIRST block
that names it."* F45 named `HomeScreen.swift`, `HomeModel.swift` and `HomeStatesTests.swift`; Build B rewrote all
three before the queue was ever run; so F45 committed **Build B's HomeScreen** — referencing `EmberTokens.Typography`,
`LogRowList`, `StateBlock`, `NextUpRow` — while the files defining them stayed in the held F46 block.

**THE LESSON IS NOT THE ORDERING RULE — IT IS THE LOCAL GATE.** Every gate passed here before the push, and they were
right about the tree they measured: the working tree held BOTH builds, so every symbol existed. **A gate run against a
tree containing un-queued work does not test what the commit contains.** Recorded in debt.md with the rule for next
time: no two queue blocks may name the same path, or the later build's content must not be on disk when the earlier
block runs.

**F47** snapshots Build B to the scratchpad (`scratchpad/buildB/` — three full files plus a 76 KB patch of the other
seventeen), reverts the tree to HEAD-plus-Build-A alone, and re-runs every gate **against that tree**:

| Command | Result |
|---|---|
| `doctrine-lint` · `swift-xref` | clean — **194** Swift files · 194 files, **379** types (the Build A counts) |
| `docker swift test` | **76 tests, 0 failures** |
| web: `npm test` · `vectors` · `typecheck` · `lint` | **42 files, 446 tests** · 56 · exit 0 · exit 0 |

Build A is unchanged in substance: the pause hydration, the computed `loadState`, the observable `SyncQueue`, the
cardio-row fix and the legible banner all remain. Only the three contaminated files go back.

### 2026-09-16 — F47 RE-VERIFIED BEFORE THE PUSH, AND HEAD HAD A **THIRD** BREAK NOBODY HAD NAMED

Every gate re-run against the F47 tree on the owner's machine, in a session that wrote no code — the point being that
the tree measured is the tree the commit contains, which is the whole lesson of F45:

| Gate | Result |
|---|---|
| `swift-xref` | **clean** — 194 Swift files, 379 types (run 34918410611 reported 2 findings here) |
| `doctrine-lint` | **clean** — 194 Swift files, 1 hand-written CSS |
| `check-drift` · `check-vectors` · `check-seeds` | Generated files match `shared/` · **56** vectors / 9 files · 15 achievements, 110 exercises, 45 lists |
| web `lint` · `typecheck` | exit 0 · exit 0 |
| web `npm test` · `vectors` · `build` | **42 files, 446 tests** · **56** · Next build exit 0 |
| Linux `swift build` + `swift test` | **NOT RUN — Docker Desktop's daemon is down on this machine.** CI's `engine-swift` job is the only reading. The 76/0 in the table above is the earlier session's, not a re-run. |

**HEAD (983ff87) had three independent compile failures, and the post-mortem above names only two.** The third:
`HomeModel.swift` carried Build B's `todayKey` and *not* `nextUpLine`, while `TodayCard.swift:38` — a Build A file that
F45 committed correctly — declares `let nextUpLine: String?` as a required init parameter. So the caller could not
satisfy its own callee. Like the missing `LogRow.swift` symbols it is invisible to `swift-xref` (which label-checks
call shapes), and it would have surfaced only on the macOS runner — which never started, because `contracts` failed
first and every other job `needs: contracts`. **One red gate hid two further breaks.** That is the argument for the
`contracts` job being cheap and first, and also the argument against reading a single red finding as the whole defect.

Also confirmed for the push: TestFlight currently serves **build 121** from `2b5e904` (Sep 11), uploaded by a MANUAL
`workflow_dispatch` — which bypasses the `conclusion == 'success'` gate, and `2b5e904`'s CI was red. F47 makes the
next build **123**, and the first one that reaches the phone by the automatic path.

### 2026-09-16 — F47 PUSHED: THE APP COMPILES. FIVE TESTS FAILED AND ALL FIVE WERE TEST DEFECTS. F48 IS THE FIX.

Run **35069768536** (HEAD `3786306`) — four of five jobs GREEN, including `web` and `ios engine (Linux)`, neither of
which had run since Sep 10. The `ios` job went red with **0 compile errors and 140 unit tests executed**, which is the
result that matters: **F47's revert worked, and A18 + A19 + A20 Build A compile on Xcode.** TestFlight correctly did
not fire (the gate needs `success`), so build 123 never reached the phone.

**This job had not executed a test since `334ad67` (2026-09-10).** A18, A19 and A20 Build A all landed in between. So
the five failures are not a regression from F47 — they are the first time three passes' worth of test code has ever
been run, and they are **five test defects and zero app defects**:

| # | Failure | Cause |
|---|---|---|
| 1 | `HomeModelFactsTests.testTodaySummaryLines…` — expected `Push day · `, got `Leg day · 15/15 sets · 0 min` | the fixture read `store.plan(…)?.workouts.first` |
| 2–4 | `CameraDenied`, `Journey1`, `OfflineSession` — `Neither element nor any descendant has keyboard focus` at `Password` | `typeInto`'s keyboard guard only ran for all-numeric text |
| 5 | `HomeStatesTests.testAllDone…` — `Failed to get screenshot: Timed out` | simulator, not an assertion — deferred to debt |

**(1) IS NOT A DATE BUG LIKE F04 — IT IS AN ORDER BUG, AND THE SOURCE ALREADY SAID SO.**
`NextUpLine.swift:75` carries the sentence verbatim: *"A1: a SwiftData to-many keeps no order of its own."* Every
production reader obeys it — `HomeModel.swift:71` and `PlanModel.swift:48` select by `kind`, `NextUpLine.swift:30`
sorts by `order` — while five test sites called bare `.first` on `LocalPlan.workouts` and one of them then asserted a
day NAME. It drew Leg day on this runner. It was never reliable; it had simply never been run. All five are pinned
`.first { $0.kind == "push" }` now, the idiom `HomeModelEdgeTests.swift:24` already used.

**(2–4) IS BUILD A FIXING ONE FIELD INSTEAD OF THE CLASS.** A20.9 diagnosed this race correctly — A19.1's
`safeAreaInset` and A19.2's keyboard toolbar animate against the same edge `typeText` synthesises against — and then
guarded it with `if text.allSatisfy(\.isNumber) && !app.keys["1"]…`, which covers `Birth year` and nothing else.
`Password` is a `SecureTextField` that raises no digit to wait for, so it kept the bare `tap(); typeText()` and failed
on all three journeys one field EARLIER than the field that was fixed. The helper's own note is right that
`app.keyboards` proves nothing between two text fields — but `hasKeyboardFocus` **on the field itself** does,
whatever keyboard it raises, so that is the general proof now and the digit wait stays for the numberPad's extra
teardown. All five S05 fields and the nutrition caption route through `typeInto`.

**The caption was included deliberately.** `NutritionPostScreen.swift:35` adopts `.crewBottomBar` (A19.1), so it has
the identical animating edge, and since the last executed run predates A19 it had **never once run with the bar
present** — it would have been the next red.

Gates re-run against the F48 tree: `swift-xref` clean (194 files / 379 types), `doctrine-lint` clean, `check-drift` ·
`check-vectors` (56) · `check-seeds` clean. Web untouched (no web file changed). **NO VECTOR CHANGES** — five fixture
pins and one test-helper wait award nothing.

### 2026-09-16 — F48 WORKED. THE XCRESULT WAS READ INSTEAD OF GUESSED AT, AND IT NAMED ALL THREE REMAINING FAILURES.

Run **35073421853** (HEAD `09e1960`): **140 unit tests, 0 failures** (F48's five `kind` pins did their job),
**zero keyboard-focus errors anywhere** (the general `hasKeyboardFocus` wait did its job), and
`HomeStatesTests.testAllDone…` **passed** — which retires the screenshot-timeout debt as collateral from a wedged
simulator, exactly as the entry was opened to determine. Three UI tests still failed, all FURTHER along than before.

**This time the xcresult was read rather than reasoned about** — T-A3's debt entry demanded it, and the 112 MB
artifact was downloaded and its zstd blobs decompressed on Windows. The trace settles the old question outright: on
`Password` the first tap never took focus (`hasKeyboardFocus` polled t=33.3 → t=37.3 and never went true), the retry
tap at **t=37.59** logged `Scroll element to visible`, and focus arrived at t=40.17. **The race was real and the
field was genuinely obscured.** A20.9's diagnosis had been right; its guard was just numeric-only.

| # | Failure | Verdict |
|---|---|---|
| 1 | `CameraDenied` — Home never showed the bridge | **test race**, and it uncovered a REAL app defect (below) |
| 2 | `Journey1` — no match for Button `Skip` | **test stale**: A19 gave the button a real VoiceOver name |
| 3 | `OfflineSession` — "the open session was lost" | **test stale**: A18.8 designed that banner away, and the session was never lost |

**(3) is the one worth reading twice.** The hierarchy dump shows the screen the test called a lost session:

```
StaticText, label: 'Today'                            <- the test's own line 64 passed here
StaticText, label: 'Your first flame lights today.'   <- the bridge
Button,     label: 'Resume your first workout'        <- the CTA, offering the session back
```

A18.8 says it in the source (`TodayCard.swift:24-26`): *the bridge lasts until the first POST, starting a workout is
not a post, so an abandoned first workout used to put a Resume banner NEXT TO the bridge's CTA — two prompts on the
one screen §1D says carries none. The bridge's single button resumes instead.* `HomeScreen.swift:65` suppresses the
banner with `!isBridge`; `TodayCard.swift:110` renames the CTA. **The assertion was accusing the app of a bug A18 had
deliberately designed away**, and its failure message said so in words a reader would have believed.

**(1) IS A TEST RACE THAT FOUND A REAL DEFECT.** The journeys tapped Save **0.34 s** after `typeText` began on
`Birth year`, and the save read the binding early: the dump shows the field holding `1994` beside the server's
`birthYear: Too small: expected number to be >=1900`, which is what `Int("19")` earns. The app does NOT send a
placeholder — `SaveAuthScreen.swift:88` guards `let year = Int(birthYear) else { return }`. But `:84` validates with
`Int(birthYear) == nil ? "Four digits, like 1994." : nil`, so **`"19"` raises no client error at all**, passes the
guard, and the user reads the server's raw sentence under the field. The message promises four digits and the check
enforces neither four digits, nor the 1900 floor, nor E9's 13+ age floor. **Recorded in debt.md, not fixed here** — a
signup validator is an app behaviour change and this pass exists to green the CI.

The test fix is the flow A19.2 built the Done bar FOR: `saveThePlan(in:)` taps Done (which resigns first responder and
COMMITS the field) before Save. Third occurrence, so it is a plain function (C5) — and it is the only test anywhere
that exercises A19.2's bar.

Gates: `swift-xref` clean (194 / 379), `doctrine-lint` clean, drift · vectors (56) · seeds clean. Four test files,
**zero app files. NO VECTOR CHANGES.**

### 2026-09-16 — BUILD 125 SHIPPED BY ITSELF, AND THE BUG THE RACE UNCOVERED IS PAID OFF

Run **35077453300** (HEAD `6dba336`) green on **all five jobs** — the first fully green master since `334ad67`
(2026-09-10) — and `testflight` run **35078973854** fired on `workflow_run`, not a manual dispatch: **Build 125 from
6dba336**, the first build this repo has ever shipped to a phone without a human starting it. Every earlier upload
(121 included) went out by `workflow_dispatch`, which bypasses the `conclusion == 'success'` gate.

Across the four passes, **every one of the eight test failures was a test defect and none was an app defect.** The app
compiled clean the moment F47 removed Build B's files from Build A's commit. The `ios` job had not executed a test
since 2026-09-10, so A18, A19 and A20 had all landed unverified, and each fix peeled back the next never-run layer.

**F50 repays the one REAL defect the diagnosis turned up**, in its own commit as the owner ruled. `SaveAuthScreen`
asked only whether the birth year PARSED, so `"19"` raised no client error, passed `submit()`'s guard and was POSTed;
the user then read the server's raw `birthYear: Too small: expected number to be >=1900` under a field whose own
message promises four digits. Both clients now mirror the server's two bounds from the generated constants:

| | before | after |
|---|---|---|
| iOS | `Int(birthYear) == nil` | `>= birthYearMin` **and** `utcYear - year >= minimumAgeYears` |
| web | `/^\d{4}$/` only | the same two bounds on top of the shape check |

**Measured, not assumed: each old validator disagreed with the server on 16 years** — 1898-1899 and 2014-2027 — and
iOS additionally accepted `"19"`. `web/tests/onboarding-birth-year.test.ts` pins the **parity, not the wording**: it
sweeps every year from before the floor to past today and asserts the client accepts exactly the set
`requireSignupGates` accepts, so the two can never drift apart again. Web is now **43 files / 453 tests**.

Two judgements worth keeping. **No new copy was invented** — both sentences were already approved and already on that
screen, so this changed a check and not the voice. And **iOS reads the year from `DayKey` in UTC**, not the local
calendar, because `requireSignupGates` counts against `getUTCFullYear()`: a local year running BEHIND UTC would make
the client STRICTER than the server and refuse someone who had just turned 13.

**NO VECTOR CHANGES.** The server's behaviour is untouched; this is a client mirroring a rule that already existed,
the same shape as `validatePassword` mirroring `passwordMinChars`.

**NEXT:** smoke-test build 125 on the phone — Home is deliberately UNCHANGED from 121, so what to check is the sync
layer: the offline banner legible with a real last-synced time and queued count, a pause created on the web reaching
the phone, and cardio inside a workout showing on Home's cardio row and matching Progress. Then restore Build B from
the scratchpad and run F46 with `CREW_BUILD_B=1`. After A20: **A15** (Stage 7), per A20.8's amended ordering.


## 2026-09-17 — read-only audit, the gym-assumption map, the test-account loop, and direct commits

Three owner-directed deliverables, all documents plus one local script; no app code changed:

- `docs/MVP_STATE_REPORT.md` — the read-only audit against spec v2.0 at `7fa7e52` (13 sections, every claim cited to file:line
  or a command). Verified here the same day: typecheck and lint exit 0 · `npm test` 43 files / 453 tests · native `swift test`
  76/0 · drift, vectors (56), seeds, doctrine-lint, swift-xref clean. Owner ruling on §12: the iOS invite path is #1 and
  BLOCKING, push registration #2 — neither is to be built until the owner says go.
- `docs/GYM_ASSUMPTION_MAP.md` — owner decision: every user has full commercial gym access. Every home/dumbbell assumption
  (30 of 45 template lists, the equipment question, the access tiers in both engines, the tier inference in the editors and
  swaps, the spec lines) is listed with delete / rewrite / no-op. Nothing removed yet; no exercise entry needs deleting.
- `docs/TEST_ACCOUNT_BYPASS.md` — plus-addressed Gmail variants already register as distinct accounts (exact lower-cased
  `emailLower`, no normalisation) and in-app deletion is a hard delete that frees the address at once, so no server change.
  `web/scripts/purge-test-accounts.ts` (local only, refuses to run under Vercel) purges base+tag accounts through the app's own
  `deleteAccount` cascade; launch gate: `TEST_EMAIL_ALLOWLIST` unset in production (OWNER-REVIEW §6 step 10; Appendix A entry).
- GIT: the owner approved direct commits and pushes by the agent (2026-09-17). `~/.claude/hooks/block-dangerous-git.mjs` now
  blocks only destructive git — force-push, history rewrite, branch/tag deletion, discarding uncommitted work — on the Bash
  and PowerShell tools alike. `docs/commit-queue.sh` is retired for new work (F51 and F52 were committed directly and its
  guard skips them); its F46 block (Build B) is still held there.
- A20 BUILD B is still only in a session scratchpad (…/AppData/Local/Temp/claude/…/29f6db46-…/scratchpad/buildB: six full
  Swift files dated 2026-09-12 plus a 76 KB patch of 16 other files, cut against the F45-era tree). The owner asked for a
  move / rebuild / discard recommendation before anything moves; ruled the same day — see the next line.
- A20 BUILD B ARCHIVED 2026-09-17 (owner: preserve, do not rebuild yet): branch `archive/a20-build-b`, folder `archive/a20-build-b/` (the scratch folder byte for byte, commit e509314); the rebuild decision waits for the MVP definition.

## 2026-09-17 (evening) — A21 recorded; MVP definition; nutrition addendum draft (docs-only; no source changed)

- Appendix A gains A21.1–A21.13 (the owner's rulings of 2026-09-17 — each dated, owner-approved, naming what it supersedes); every
  overturned section carries a one-line "Superseded … by A21.x" marker at its head and its original text is never rewritten. Appendix B's
  Firebase ⏳ is CLOSED (A21.7). A15 is removed (A21.1); A16's model is replaced by A21.5 (the clauses, palette and A16.a/b/c stand).
- `docs/mvp-definition.md` — positioning, the five device-flawless flows, the A21 table, Not Building, the W1–W9 worklist (W1 = this session).
- `docs/nutrition-addendum-draft.md` — A21.5's proposal, NOT ratified; ends with the three owner questions (goal / deficit, calories on Today, entry point).
- Three agent readings recorded as GAP inside A21: the invited decision count stays 5 on the code path (A21.1); the invite code is the
  existing inviteToken (A21.3); goal has no effect on the targets until question 1 is answered (A21.5).
- Domain state for W7: the web app is at https://crew-eta-one.vercel.app (200 / 401 today); no custom domain anywhere in the repo or
  its GitHub variables; no AASA served (404); `applinks:crew.example` still in project.yml.
- This push touches docs/ only, so ci.yml skips it (paths-ignore) and no TestFlight build follows — expected.
- NEXT: nothing is built until the owner says go; on go, W2 (gym-only, docs/GYM_ASSUMPTION_MAP.md) is the next session.
## 2026-09-17 (night) — W2 GYM-ONLY DONE (A21.1; the owner's GO of 2026-09-17; contract: the W2 row of docs/mvp-definition.md; work order: docs/GYM_ASSUMPTION_MAP.md)

Every row of the map applied on both engines and both clients in ONE code commit (`feat(gym): A21.1 …`), preceded by the registry
commit that closes the three A21 GAP readings (owner-confirmed as written) and adds W4's "Copy code" button on the web landing page:

- shared: `enums.equipmentAccess` deleted (its absence asserted); `plan-templates.json` nests kind → experience — the 30 home-tier lists
  are gone, the 15 gym lists stay; `onboardingQuestionCount` 3→2, `decisionsBeforeHomeOrganic` 5→4 (invited stays 5, owner-confirmed);
  `render-seed` / `check-seeds` rewritten; Generated/ regenerated (drift clean). Gym-only catalog: couch-stretch → "Wall Hip Flexor
  Stretch", doorway-pec-stretch → "Rack Pec Stretch", doorframe-row → "Suspension Trainer Row", five cues lose their home objects; ids
  unchanged so saved plans and sessions keep resolving; check-seeds asserts no home OBJECT in a name or cue (the rowing cue's "on the way
  home" stays — its first version flagged it, and "home" left the word list).
- engines: `generatePlan(days, experience, seed)` and `swapCandidates(incumbent, experience, …)` on both twins; the swap pool is every
  exercise of the same type.
- iOS: `EquipmentQuestionScreen` deleted; `OnboardingQuestion` has two cases; `OnboardingModel` / `Flow` / `Draft` lose the equipment
  answer (an old on-disk draft still decodes — unknown keys are ignored); `WorkoutDraft.access` and `SessionSwap.access(for:)` deleted.
- web: `OnboardingFlow` (experience is the last question and builds the plan; `QUESTION.experience = onboardingQuestionCount`, so the
  whisper reads "2 of 2"), `plan-draft.accessFor` deleted, `SessionSwap` / `SessionLogger` / `ExerciseSheet` without the access prop;
  the "with your gear" copy is gone.
- tests: the property tests run over days × experience (127 × 3 = 381 plans) on both engines; `OnboardingModelTests` asserts the
  experience answer lands on the reveal and that the last question's number equals `onboardingQuestionCount`; the three XCUITest
  journeys lose the "Full gym" tap and journey ① asserts "2 of 2"; e2e helpers assert "1 of 2" and "2 of 2"; journey ③'s "Dumbbells" tap is gone.

| Gate (run here, 2026-09-17 night) | Result |
|---|---|
| `check-drift` · `check-vectors` · `check-seeds` | match · **56** vectors / 9 files · 110 exercises, **15 lists**, gym-only |
| `doctrine-lint` · `swift-xref` | clean — 194 Swift files · 194 files, 378 types |
| web `typecheck` · `lint` · `build` | exit 0 · exit 0 (one 41-line function caught by max-lines-per-function and trimmed) · green |
| web `npm test` · `vectors` · `e2e` | **43 files, 445 tests** (453 → 445: the equipment axis leaves the two property suites) · 56 · **32 passed, 1 skipped** |
| native `swift test` (engine package) | **76 tests, 0 failures** |

NO VECTOR CHANGED (56 stay 56). WRITTEN-UNVERIFIED on a device: the two-question onboarding and the swap sheets on iOS — the macOS CI
job compiles them and runs the three rewritten journeys.

**CI run 35290103306 (push 6ff0cd0, 2026-09-18 00:28Z): contracts ✓ · web ✓ · web e2e ✓ · ios engine ✓ · ios ✗ — 0 compile errors,
140 unit tests green (PlanGenerator, SwapFinder and OnboardingModel under Xcode), journeys ① ②, CameraDenied and OfflineSession green
without the "Full gym" tap, and 2 failures, both `HomeStatesTests` (workout day, all-done): "expected Home's title to name the state
(Push day); the screen says: Rest day".** Not W2's doing and not Home's: `SeedClient.putPlan(oneTrainingDayOffsetFromToday:)` took
today's weekday from the wall-clock calendar while Home judges today by the 3 AM boundary (E8), so between midnight and 3 AM the seed
names tomorrow's weekday — the run began at 00:28 UTC, the first run ever inside that window (neither test file had changed since the
last green run). **F53**: the seed client gains `appToday()` (now minus `dayBoundaryHour`, mirrored by name because a UI-test bundle
cannot import SpecConstants) and both the plan and the pause helpers count that day. Test-only; no app file changed. TestFlight
correctly skipped (run 35291354103).

**CI run 35291594989 (F53, b918332) — attempt 1:** the two #39 failures PASS (the 3 AM diagnosis held; all-done 32 s, workout day
13 s, paused 12 s) and ONE new failure, `HomeStatesTests.testRestDayNamesItsNumbersAndStatesThePremise`, 112.5 s, "the screen says:"
EMPTY. The xcodebuild log dates it: `Launch` at t = 0.45 s, the first `Requesting snapshot of accessibility hierarchy for app with pid
28918` at t = 46.7 s, never answered, then `Restarting after unexpected exit, crash, or test timeout` — an UNRESPONSIVE APP at launch,
not a wrong seed and not a wrong assertion. Across #39 and #40 the same signature hit 2 of 8 seeded-Home launches (#39 all-done
110.7 s, #40 rest day 112.5 s); both had the member's single training day on the app's TOMORROW, but a third launch with that seed
(#39 workout day) rendered normally, and every "tomorrow" path is bounded (`nextTrainingDayKey` ≤ 7 steps, `kindOn` ≤ 7,
`pullIfEmptyBounded` capped) — so INTERMITTENT, recorded in debt.md, NOT fixed and NOT papered over. **Attempt 2** (`gh run rerun
--failed`, the four green jobs carried over): macOS job GREEN — 140 unit tests, journeys ① ②, CameraDenied, OfflineSession and all
four Home states. **CI GREEN on b918332.**

**TestFlight run 35294010935 FAILED at Archive** (exit 65): "Choose a certificate to revoke. Your account has reached the maximum
number of certificates" and "No profiles for 'com.maxwellcuenca.crew' were found … iOS App Development provisioning profiles". Cause:
the archive step signs with automatic signing on a FRESH runner every time, and a runner that holds no private key mints a NEW Apple
Development certificate per build; the builds since 2026-09-08 exhausted Apple's per-team cap. Not the code, not W2: the same
workflow shipped build 126 on 2026-09-16. Recorded in debt.md. **OWNER ACTION (one step): at developer.apple.com → Certificates,
Identifiers & Profiles → Certificates, revoke every "Apple Development" certificate (all runner-minted — the owner has no Mac, so none
is in use; keep the "Apple Distribution" ones), then Actions → testflight → Run workflow with the build number blank → build 136 (the
commit count).** The workflow-side repair (an archive that does not mint a development certificate) is a debt entry, owner-approved
before it is touched.
## 2026-09-18 — CONTINUE TO FULL COMPLETION: THE SPLIT (CLAUDE.md rule 12) AND THE STATE OF EACH ITEM

The owner's order (Appendix A, 2026-09-18): commit per batch, push per numbered item, read each CI verdict before the next; owner tasks
are never waited on. Rulings recorded first (item 0, this commit). The builder's G1 readings are Appendix A's list (1)–(5) and R-068.

| Item | Scope | Batches (one commit each) | State |
|---|---|---|---|
| 0 | Rulings in Appendix A; A22 head marked RULED; addendum renamed `docs/nutrition-addendum.md` and edited to Q1–Q3; mvp-definition; this split; R-068 | docs | DONE (this commit) |
| 1 | Storyboard tooling | `Screenshots.swift` numbers every shot per test ("NN-<screen> — <action>"); `ios/scripts/storyboard.mjs` turns `xcresulttool export attachments` into `storyboard/<Test>/NN-<slug>.png` + `index.md` (test · step · screen · action); ci.yml exports after the verdict and uploads `ios-storyboard`; Playwright `trace: "on"`, `screenshot: "on"`, html reporter, traces uploaded always | pushed as 9dfdd92 + 7aad23e (one commit by a broken chain guard; the ci/playwright half followed) → CI run 35317449697 GREEN (five jobs); `ios-storyboard` holds index.md + 30 PNGs |
| 2 | W3b — A22 execution (docs/MEAL_POST_REMOVAL_MAP.md, every row) | (a) engines: G1 (a) on both twins — `plannedWeekdays` on postCreated, the streak counts planned completed workouts, perfect week from the plan, `hadRequirement` derived by the callers (iOS `judgeElapsedDays` from the Store's plan; server `recomputeAndStore` loads the plan and threads `trainingWeekdays` into the recompute twins) · the `retired` marker (check-vectors, README, both runners incl. the iOS count assertion) · 23 retired (21 meal carriers + V04 + V30) · new vectors V66+ (rest-day silence · planned day completed · planned day missed with and without a shield · bonus day XP only · two posts one day · all-rest plan · perfect week without daily posts · shield cap · imperfect week by rollover · first partial week · a workout-only recompute · a caption-only post) · API tests re-seeded with workout posts. (b) server: posts route narrowed (no meal/text creation; caption ≤ 280 on workout posts via PATCH sessions; photoKey gone from posts), validators, photos `purpose` = profile only, readablePhoto = owner only, `VectorSlots.macros` placeholder, progress-facts meals/week gone, cron copy per G1, notification-facts planned-day gating, documents. (c) iOS: Post/ folder deleted except CameraCapture (profile), Home toolbar camera gone, TodayCard rest copy ("Rest day. Nothing to do here — see you <next day>."), VectorRow third slot absent until W8 (G4), ProgressModel plates/meals gone, JournalFacts meal branch gone, MealTag deleted, ModelsSocial legacy fields kept unused, SyncTransport/SyncDelivery/PostPayloadPhotoStripper/FailedUploadSheet narrowed (E19 → profile uploads have no queue; the held-op sheet loses its photo branch), ApiSessions mealTag gone. (d) web: PostComposer + /post deleted, TodayCard/VectorRow/StreamList/CrewView/Journal/Progress/HeatMap re-copied, api-client post calls gone. (e) constants (four G10 minutes, textOnlyPostMaxTaps, nutritionPostTargetSeconds, photoPostOptimisticMaxMs, captionComposerMaxLines, failedUploadChoiceAfterHours deleted; xpMealPost/mealXpDailyCap stay vector-bound), seeds (first-flame copy), journeys (CameraDenied → ProfilePhotoDeniedTests; SeedClient.postMeal → completeWorkout; HomeStates/Journey2 landmarks), spec markers, docs | (a) engines DONE a70a401 · (b)+(d) the web platform (server + client + tests + Playwright) DONE in one commit — the web is one TypeScript project, so its server and client halves cannot be green apart · (c) iOS DONE 3eb3042 (compiles only in CI's ios job — verdict pending) · (e) constants (five deleted; the four G10 minutes with the MealTag twins), seeds re-copied, spec markers at every passage the map names, docs — DONE, this commit · push after this commit; read the CI verdict before item 3 |
| 3 | W7 code half | `web/src/app/.well-known/apple-app-site-association/route.ts` (appIDs from `APPLE_TEAM_ID` ?? `APNS_TEAM_ID` + `APPLE_BUNDLE_ID`; 404 until set — owner adds `APPLE_TEAM_ID` to Vercel) · testflight.yml: `applinks:${{ vars.CREW_APPLINKS_HOST }}` when set, the entitlement line deleted when empty; the variable set to `crew-eta-one.vercel.app` by `gh variable set` · `onOpenURL` in CrewApp → `InviteCode.token(from:)` → signed out: `OnboardingModel.inviteCode` + `lookUpInvite()` (a `PendingInvite` one-shot, the third flag — C5 extracts the three into one `OneShotFlag` function) · signed in: `CrewModel.inviteCode` + `lookUpInvite()` → `JoinByCodeSheet` · Copy code already on the landing page (W4) · tests: route test (content-type, shape, 404 when unset), an onOpenURL unit test on the parser | DONE locally 2026-09-18 (AASA route + test · InviteInbox + onOpenURL → the pasted-code path on both the hero and the Crew tab · the entitlement is a commented placeholder in project.yml that testflight.yml turns into `applinks:<host>` only when the repository variable CREW_APPLINKS_HOST is set, and the unsigned archive is ad-hoc signed with its entitlements before the export so they survive it · the two usage strings re-copied for the profile picture). pushed with the merge of origin/master (the pull request merged 2026-09-18 11:15 UTC); CREW_APPLINKS_HOST stays UNSET until the last build is out — setting it is the experiment that follows, because a cloud-signed export needs Associated Domains on the App ID (an owner task). |
| 4 | W8 — three sessions under `docs/nutrition-addendum.md` | 8a constants (incl. `nutritionAdultAgeYears`), three macro tokens (+ contrast pairs, `macro-palette.test.ts`), `shared/seed/fast-food.json` from published nutrition facts fetched at build time (each chain: sourceUrl + retrievedOn; a chain whose source cannot be read is OMITTED and `fastFoodChainCount` says what shipped) + generate/render-seed/check-seeds; 8b `UserDoc.birthYear` (written at signup, asked once when Nutrition opens), documents-nutrition, db getters + indexes, validate-nutrition, four libs, routes under /api/v1/nutrition + registry, export + cascade, 6 sync op kinds, engine twins `NutritionTargets` ⇄ `nutrition-targets.ts` and `MacroDay` ⇄ `macro-day.ts` (Foundation only), V57–V65 (kind `nutrition`) on both runners, the 18+ gate `isNutritionAdult`; 8c web Today + Saved meals & template + methodology pages, iOS `Features/Nutrition/` (Today, SavedMeals, Template, Methodology, the birth-year ask), Home "Log macros" row (G4; absent when gated), Settings rows (targets, methodology, delete), journey ⑤ both platforms, the W067 audit script `shared/scripts/launch-audit.mjs` (the seven clauses + A21.13's list) | 8a DONE locally (constants · six macro tokens + contrast pairs · the three engine twins · V57–V65, 84 vectors green on both engines · the fast-food seed: six chains shipped, four held with reasons) · 8b server DONE locally (four collections · the 18+ gate · twelve route methods · export + both cascades · six sync ops · nutrition.test.ts + the standing registry; web suite 491 green) · 8c DONE locally: the shared copy pipeline (`shared/copy/nutrition-method.json` → `Generated/CopyData.swift` + `generated/copy.ts`, `check-copy.mjs`) with the A16.a methodology page and its four verified sources · the twins grew the words a screen prints (amountText · restText · horizonText (clause ② names tomorrow) · spokenLine · gramsText · barPercent · slotTicks · bodyweightTenthsFrom / bodyweightInBounds), tests on both engines · WEB: /nutrition (first-run → Today) · /nutrition/meals · /nutrition/template · /nutrition/targets · /nutrition/method, the Home row "Log macros" (a count; absent under 18), the Settings section with the two-step delete, the one-time birth-year ask; journey ⑤ ×3 viewports + the a11y sweep over the five pages (41 e2e green) · iOS: four @Model classes + NutritionLocal / NutritionActions / NutritionHydrate, six OpKinds, ApiNutrition, `Features/Nutrition` (Today · parts · macro lines · gram field · saved meals + template · meal form · chain picker · targets · methodology), the Home row, the Settings rows, `NutritionLocalTests` + `Journey5_NutritionTests` (compiles on CI only) · `shared/scripts/launch-audit.mjs` (W067: the seven clauses + A21.13, 18 checks, in CI) · R-075 · the three nutrition whispers ride item 5 · 6.9 (A25, merged from pull request #1) applied to the NEW screens: Today keeps one job, Quick add and Logged today are destinations one tap away (R-077) · pushed with the merge of origin/master |
| 5 | Education layer mechanism | `shared/copy/education.json` (ONE file: every whisper + every page string; the note from Max marked DRAFT) → generate.mjs renders `Generated/EducationCopy.swift` + `generated/education-copy.ts`; `UserDoc.whispersSeen` + PATCH users/me union; iOS `WhisperState` + `Whisper` view + `HowCrewWorksScreen` (S19) + the Settings row; web twin + /how-crew-works; the existing reveal swap whisper joins as `how.revealSwap`; eleven wired (the three nutrition ones on the W8 screens); a seen-state round-trip test | DONE locally: `shared/copy/education.json` (the ONE file: twelve whispers + the page; the note from Max marked draft and shown as "Draft") → `Generated/CopyData.swift` (+ a generated `WhisperId` enum) and `generated/copy.ts` (+ a `WhisperId` union), `check-copy.mjs` (≤ 12 words, ids, gates, sources) · server: `User.whispersSeen`, PATCH users/me unions it (`$addToSet`), account.test.ts round trip · web: `Whisper` + the `WhispersSeen` shell provider (server ∪ localStorage, re-sent whole; a pre-account set joins the account), twelve placements, /how-crew-works + the Settings → About link, whispers.spec.ts ×3 viewports (once · first tap clears · survives another browser · S19 adult 12 / minor 9) · iOS: `WhisperState` + `Whisper` + the one root tap gesture, twelve placements (rule 3 moves `how.invite` out of the Invite sheet, R-076), `HowCrewWorksScreen` + the About row, `WhisperStateTests`, Journey ④ asserts the pause whisper once and opens S19 · R-076 · pushed with the merge of origin/master |
| 6 | W9 | `StoreSchema.swift` (CrewSchemaV1 + CrewMigrationPlan, F31 kept) · privacy and terms bodies drafted from the actual data practices (the placeholder note removed; owner reviews) · `docs/app-store-listing.md` · `.github/workflows/store-screenshots.yml` (workflow_dispatch: Journey4 on a 6.9" and a 6.5"-class simulator with `simctl status_bar` override, artifact) · `launch-audit.mjs` run, findings fixed · TEST_EMAIL_ALLOWLIST: read by no server code (the purge script only) — confirmed by grep; the Vercel env cannot be read from this machine (no vercel CLI) → an owner check in OWNER-REVIEW · `docs/OWNER-REVIEW.md` rewritten with the exact remaining owner steps | DONE locally 2026-09-18: `StoreSchema.swift` (CrewSchemaV1 = every build since 2026-09-10, build 150 included, with the plate-journal-era LocalPost nested; CrewSchemaV2 = today; one lightweight stage; the version a constant) · `Store` opens under the plan, F31 kept · `StoreMigrationTests` (a build-150 store file written without a versioned schema keeps its plan, its journal and a queued op) · LocalPost's four legacy properties gone, five call sites updated · `shared/copy/legal.json` → /privacy and /terms (contact from `SUPPORT_EMAIL`; three blanks are the owner's), check-copy covers it · `docs/app-store-listing.md` · `.github/workflows/store-screenshots.yml` (the A24 tour per display class, 9:41, native pixels, `SIZES.md`) · `Tour_NutritionTests` joins the tour (A24 (5)) · launch-audit clean in CI · TEST_EMAIL_ALLOWLIST read by no server code · `docs/OWNER-REVIEW.md` rewritten · R-078 · four debt entries opened, two repaid · the CI verdict and the TestFlight build number are recorded under END |
| END | the final TestFlight build number · a ten-line phone checklist for items 2–6 · the OWNER-REVIEW.md path | — | DONE 2026-09-18: **build 191** (8c83a74; CI run 35387497620 green, TestFlight run 35390307268) carries items 1–6 in full — builds 188 (5b42e69) and 190 (9d309d1) were the two before it · the ten-line phone checklist is `docs/OWNER-REVIEW.md` §4 · the owner's tasks are `docs/OWNER-REVIEW.md` §2 · the run-by-run record is the section "0aaaa51 → 8c83a74" below |

Standing rules for every batch: the local gate set green before a push (drift · vectors · seeds · doctrine · xref · web typecheck/lint/test/
vectors/build · e2e when web changed · native swift test); `// SPEC:` on every rule; every number from spec-constants via Generated;
debt.md in the same commit as a compromise; GAP readings tagged `// GAP:` and logged in ratification.md; plan-templates.json untouched.

### CI run 35340692297 (da29d17, items 3–5 + the merge) — THE FIRST COMPILE OF W7 / W8 / A23 ON THE PHONE: it compiled; three UI tests red, two of them real bugs

Read 2026-09-18 12:03Z. contracts ✓ · web ✓ · web e2e ✓ · ios engine ✓ · ios ✗. Every new Swift file compiled first time (44 added since a34e4a1, the A24 tour's among them); **180 unit tests, 0
failures** (CelebrationPostTests, SyncQueueTests and SessionModelTests included — the owner's three named failures were fixture defects
repaired in a34e4a1 and da29d17); 23 of 26 UI tests green, `HomeStatesTests.testRestDayAsksNothing` among them. The three red ones:

| Test | What it said | Cause | Fix (this push) |
|---|---|---|---|
| `ProfilePhotoDeniedTests` | "the Profile screen did not open" | **A real bug, mine (A23).** `RootView`'s `.simultaneousGesture(TapGesture())` — the whisper listener — stopped EVERY NavigationLink row of a List from opening: the Settings tour shows "Blocked people", the profile row and "Pause my plan" all staying shut. The debt entry had named it the first suspect | `Shared/AnyTapWatcher.swift`: a passive UIKit tap recogniser on the window (cancels nothing, delays nothing, simultaneous with everything); the whisper leaves one main-queue turn after the tap |
| `Journey5_NutritionTests` | two taps on "Increase Protein" → 50 g, expected 40 | **A real bug, since 2026-09-09.** `StepButton` stepped TWICE per tap (touch-down and lift) — review finding F07, marked fixed by W019 and never fixed; journey ⑤ is the first test to tap a ± and read the number. Reps, weight, the rest timer and grams were all affected | `Shared/StepButton.swift`: the tap is the only single step; a hold starts after `autoAdvanceDelayMs` and repeats until the lift |
| `Journey4_ScreensTests` | "Settings → About has no How Crew works row" | A test defect: Settings is three pages long since W8 and the test swiped once | scroll until the row exists |

The tour (which never fails a run) had lost eleven baselines in the same run, and each loss is now explained and repaired: the Settings
steps by the List bug above; "Log cardio" because Home's two first-visit whispers push the log rows under the tab bar (the tour now
scrolls to the row); the Crew react step because **the tour seed sent whole-second instants** — a post stamped in the same second as the
crew's creation sorts before it and the join-forward stream drops it (reproduced on the local harness: both crew-mates' posts missing;
with milliseconds both arrive; Sam's card was already missing from the approved baseline); and the session tour's ending MOST LIKELY because its
dialog-dismiss tap lands on the weight tape (unproven — the tour keeps no shot of a step it lost); the tap now lands in the canvas gutter,
where a tap that passes through touches nothing. The blank "Blocked people" baseline was a shot taken
before the list had loaded; the tour now waits for "No one blocked.".

### 0aaaa51 → 8c83a74 (2026-09-18 12:36Z – 20:17Z) — W9 ON MASTER, MASTER GREEN, BUILDS 188 · 190 · 191, THE OWNER'S QUEUED ORDER (A24 verified from the main checkout · the W8 screens in the tour · the inventory and the brief)

Recorded 2026-09-18 ~20:30Z by the housekeeping session that followed (the session that did the work ended without updating this file — rule 11; every line below was re-read from `git log`, `gh run view` and the tour folder, not from memory).

| Commit | What | CI run | TestFlight |
|---|---|---|---|
| 356ac29 | the three fixes for run 35340692297 (table above): `AnyTapWatcher`, the single-step `StepButton`, the tour's lost screens | read with 0aaaa51's run | — |
| 0aaaa51 | **W9** (item 6): `StoreSchema.swift` + `StoreMigrationTests`, `shared/copy/legal.json` → /privacy and /terms, `docs/app-store-listing.md`, `store-screenshots.yml`, `Tour_NutritionTests`, OWNER-REVIEW rewritten, R-078 | **35345590260 RED** — four jobs green; `ios`: 2 UI tests. `Journey4_ScreensTests`: "A23: the pause whisper never showed under Pause my plan" — a REAL bug: the Settings tab's own tap cleared the whisper before it was seen. `Journey3_InviteCodeTests`: "no crew preview for the pasted code" — seen once, not diagnosed (debt.md) | skipped (35347544323) — the gate held |
| 5b42e69 | the whisper listener snapshots what is showing AT the tap and removes it a turn later, so the tap that OPENS a screen never clears that screen's whisper (A23 rule 4); journey ③'s failure message names the typed code | **35347725730 GREEN**, five jobs, 27 min | run 35350332237 → **build 188** |
| e7e7ee0 | "Approve baselines: home_home_macrosrow" — `/approve-screens` exercised on ONE screen (the owner's queued order, Part 2); baselines 51 → 52 | pushed with 9d309d1 | — |
| 9d309d1 | ui-reviewer on run 35347725730's tour: Add, Save meal and Save targets sat mid-screen → the three nutrition primaries adopt `.crewBottomBar` (6.3, 6.7, DESIGN.md 4.2); the tour reaches Profile, the Template half and the first-run Today | **35351054305 GREEN**, five jobs, 30 min | run 35354023937 → **build 190** |
| 8c83a74 | ui-reviewer on run 35351054305's tour: the first-run Today and the birth-year ask anchor their one primary at the bottom; Today itself keeps no bar (A19.1: a screen with no primary gets no bar) | **35387497620 GREEN**, five jobs, 31 min | run 35390307268 → **build 191**, "Upload succeeded" 20:17Z |
| a5d2f9e | `design/INVENTORY.md` + `design/claude-design-brief/` (docs-only, `[skip ci]`) | none, by design | — |

- **A24 IS ON MASTER AND VERIFIED FROM THE MAIN CHECKOUT.** PR #1 (`a24-visual-loop`) and PR #2 (`scratch/ui-tour-verify`) are merged; both branches are gone from origin and the worktree `C:\tmp\crew-a24` no longer exists (`git worktree list` shows the main checkout alone). The SessionStart hook prints the tour summary; the scheduled task keeps `OneDrive\Desktop\CREW_2.0-SCREENS\master` current (`_last-sync.txt` 19:58Z); `/ui-check` → ui-reviewer produced the two findings that became 9d309d1 and 8c83a74; `/approve-screens` committed one baseline (e7e7ee0).
- **THE TOUR AS OF RUN 35351054305 (9d309d1):** 65 shots against **52 baselines** — CHANGES.md: **6 changed** (plan built · the onboarding swap sheet · the logger at start · Settings top / bottom · Blocked people) · 11 expected drift · **13 new** (every `tour_nutritiontests` screen but the approved Home row — no baseline yet) · 0 removed · 35 unchanged. The baselines are the OWNER's to move: `/approve-screens` for the 13 new and the 6 changed once they look right.
- **`design/INVENTORY.md`** (312 lines; every toured screen: actions, patterns, density, the DESIGN.md rule each violation cites, data oddities; every "Screen job (one sentence):" line left BLANK for the owner) and **`design/claude-design-brief/`** (README — what Crew is, the hard constraints, the top ten inconsistencies, NO visual direction — plus 13 screenshots: Home in seven states, the logger in six). Commit a5d2f9e.
- **OWED, NOT DONE:** (1) rule 13 for 8c83a74 itself — its own tour (run 35387497620) had not reached the folder when this was written, and no ui-reviewer verdict on the two screens it moved is recorded; the next UI session reads that tour first. (2) Three tour shots do not show the state their name promises — two mid-animation, and `03_session_logger_midset` without the rest timer (debt.md). (3) The journey ③ one-off (debt.md). (4) `design/DESIGN.md`'s four owner sections are still empty, so ui-reviewer judges against the cited rules only.

### 2026-09-18 (housekeeping) — Q12 REPAID: a finished deletion answers 200 even when the confirmation email cannot be sent

`web/src/lib/account-delete.ts`: the "account deleted" email is best-effort AFTER the cascade — `try` / `catch`, one `console.error` line that carries the transport's error and never the address; the route keeps answering 200 because the account is gone (E9 promises a confirmation that states the cascade is done, not a deletion that waits on a mail provider). Seen on production 2026-09-08 22:10Z as a 500 over a completed cascade. Test (`tests/api/account.test.ts`, no mock — C4): the REAL Resend transport pointed at a closed local port (`RESEND_BASE_URL=http://127.0.0.1:9`; the SDK reads it per client), so `deliver` throws without touching the network → 200 · `users/me` 404 · the user document gone · no outbox row. The verbose run shows the path taken: `[Resend API Error] … Unable to fetch data` then the one log line. No vector, constant or route shape changed; `docs/api.md`'s row gains "best-effort".

| Command (run here, 2026-09-18) | Result |
|---|---|
| `npm test tests/api/account` | **1 file, 7 tests passed** (6 → 7) |
| web `typecheck` · `lint` | exit 0 · exit 0 |
| web `npm test` | **50 files, 522 tests passed** (23 skipped = the retired vectors) |
| web `npm run vectors` · `build` | 61 passed, 23 retired-skipped (84) · green |
| e2e · the Swift gates | NOT RUN: no page, component, route shape, Swift file, constant or seed changed — CI runs them on the push |

## 2026-09-18 (evening) — A26, THE CANONICAL TEMPLATES (owner-approved; Appendix A A26; readings R-079) — BUILT ON BOTH ENGINES AND BOTH CLIENTS

Plan, as stated before the code (rule 5): **files** spec-constants + the two seeds + render-seed / check-seeds → the PlanGenerator, SeedCatalog and
PersonalRecords twins → the reveal, the session swap and the editor on both clients → the phone's equipment chip → the tour seed · **tests** the
property tests over days × experience on both engines, the named-swap and repeated-row tests, `EquipmentSymbolTests` · **vectors** none (84 stay 84).

| What | State |
|---|---|
| Registry | A26 in Appendix A with markers at Flow 1, the G-entries and Appendix B; the dynamic warm-up block recorded as a PARKED owner idea, not built |
| Templates | `plan-templates.json` → **3 lists** (push 5 · pull 6 · legs 5), kind → exercise ids; `targets` 3×8 · 4×8 · 5×8; `namedSwaps` (8 rows); Full-Body A/B's six lists and two closing blocks gone; the mobility blocks for Push, Pull and Legs unchanged |
| Constants | six leave, five arrive, `someExperienceTargetSets` 3 → 4 (the A26 entry lists them) |
| Catalog | 110 → **131** exercises, ids stable: six rows renamed to the owner's words, lat pulldown tagged machine, six new template rows / named swaps, fifteen catalog-only machine / cable movements (shoulder work on Push included); four swap groups re-cut so every named swap is always offered |
| check-seeds | list length per kind, no level gate, repeats allowed, no barbell row on Pull, every named swap in a 3–5 group, targets = the constants with no rep range, one SF Symbol per equipment tag |
| Engines | `generatePlan` / `workoutFor` select the list by KIND and the sets by EXPERIENCE (both twins); `newRecords` treats the rows of a repeated exercise as ONE record candidate (both twins) — three heavy curl rows would otherwise have awarded and counted three PRs |
| A row may repeat | rows are named by ORDER wherever a tap names one: the reveal's swap (iOS + web), "Update my plan" from a session swap (`planRowToSwap` twins), the web editor's move; the phone editor's swap no longer hides a candidate already in the workout |
| Equipment icons | `Shared/EquipmentChip.swift` — `EquipmentLabel` (symbol + word, secondary ink) and the outlined `EquipmentChip`; on the reveal, the editor's rows and exercise sheet, the session's active card and every swap list; ONE mapping (`exercises.json` enums.equipmentSymbol → `SeedCatalog.equipmentSymbol`). The WEB chip stays words (R-079 (5), debt) |
| Fixtures | the tour member trains the canonical templates (`TourSeed`); unit fixtures follow the new constants; the journeys name no exercise and needed nothing |
| Docs | R-079 · three debt lines (the owner's stale-Keychain flash · one history for a repeated exercise · the web chip) · OWNER-REVIEW §2.7 marked done · mvp-definition's A26 section |

| Gate (run here, 2026-09-18 evening) | Result |
|---|---|
| `generate` · `check-drift` · `check-vectors` · `check-seeds` · `check-copy` | match · **84** vectors / 11 files (23 retired) · 131 exercises, **3 lists**, 8 named-swap rows · clean |
| `doctrine-lint` · `swift-xref` · `launch-audit` | clean — **253** Swift files · 253 files, 502 types · 18 checks clean |
| web `typecheck` · `lint` · `build` | exit 0 · exit 0 · green |
| web `npm test` · `vectors` | **51 files, 528 tests passed** (522 → 528) · 61 passed, 23 retired-skipped |
| web `npm run e2e` | **50 passed, 1 skipped (by design), 0 failed** — 375 / 768 / 1280 |
| native `swift test` (engine package) | **97 tests, 0 failures** (94 → 97) |
| native `swiftc -typecheck` of the new non-engine Swift shapes (scratch copy) | clean — the tuple-literal tour rows, the memberwise init with a defaulted `symbol`, `planRowToSwap` |

**WRITTEN-UNVERIFIED until the macOS job:** `EquipmentChip.swift`, the reveal keyed by order, `SessionSwap.planRowToSwap`, `ExerciseListRow`'s symbol,
`EquipmentSymbolTests` (asks the system for each of the five symbol names — a wrong name draws nothing and fails no build), the new `OnboardingModelTests`
and `SessionModelTests` cases, the rewritten tour seed. The CI verdict, the build number and ui-reviewer's verdicts are recorded below once read.

### CI run 35400020876 (3736213, A26) — THE FIRST COMPILE: 0 compile errors, every unit test green, ONE UI test red (a test defect); ui-reviewer: ten A26 screens, ten PASS

contracts ✓ · web ✓ · web e2e ✓ · ios engine ✓ · **ios ✗** on `Journey4_ScreensTests`: "S19 did not open". Every new Swift file compiled first time and
`EquipmentSymbolTests` passed — the five SF Symbol names are real. TestFlight did not fire (the gate needs `success`).

**The red was read, not re-run.** The step waited only for the "How Crew works" row to EXIST; a List builds rows just past the screen's edge, so after
one swipe the row existed UNDER the tab bar, the tap landed on the Settings TAB (the hierarchy dump shows the list scrolled back to its top — the tab's
scroll-to-top) and S19 never opened. Nothing in A26 touches Settings; swipe distance decides which run meets it. c89ab00: the step scrolls until the
whole row sits above the tab bar and says so if it never does. No app file changed for it.

**/ui-check on that run's tour (9 changed · 14 expected drift · 15 new · 3 removed · 26 unchanged).** The three "removed" are one lost step and two
renumbered shots: the onboarding tour's "second button whose label says Press" sat under the reveal's bottom bar, was not hittable, and the two Save shots
moved up a number. ui-reviewer's verdicts:

| Group | Screens | Verdict |
|---|---|---|
| A — touched by A26 | reveal · plan editor · exercise sheet · plan swap sheet · add-exercise sheet · logger start · logger mid-set · session swap sheet · Home filled · Home macros row | **10 PASS · 0 FAIL** — the symbol is visible, ink-only, aligned and crowds nothing wherever it was in shot |
| B — Changed / New against the baselines, NOT touched by A26 | 3 Settings · 13 nutrition · 2 Save | **11 PASS · 7 FAIL**, all pre-existing (below) |

Three Group A notes, none a rule breach, all acted on in c89ab00: (1) in the plan editor the symbol LED the detail line ("[glyph] 3 × 8 · Barbell"),
away from its word, and the differing glyph widths made the column ragged → the row reads "3 × 8 · [glyph] Barbell"; (2) the reveal's chips were in no
shot → the onboarding tour scrolls to the flat bench, shoots the rows (`onboarding_plan_rows`), then taps; (3) the session card was only ever shot with
the shortest name → the session tour opens "Cable Rope Triceps Extension" and shoots it (`session_logger_longname`). Two reviewer remarks left for the
owner's design session, recorded not acted on: `gearshape.2` (machine) is also the app's Settings metaphor and `cable.connector` is a sliver at caption
size — each symbol is a one-word change in `exercises.json` (R-079 (6)); and in the session header the tag is now the only one of "Barbell · Swap · Skip"
wearing an icon, which makes the LABEL look the most tappable (INVENTORY's inconsistency #1, a Component-kit question).

Group B's seven FAILs, verbatim in kind, none from this change and none fixed here (they are the design session's input, with `design/INVENTORY.md`):
Settings top — the OFF switch track and the "Off" value under 3:1 / 4.5:1 (1.6, §7) · Settings bottom and Settings (nutrition) — "Delete account" in
`danger` as body text is 4.35:1 on the card, a token-level question like the one 1.3 settled for ember (§7) · Blocked people — the empty state is one gray
sentence with no CTA (6.3) · Quick add — the disabled "Add" label is unreadable on its fill (§7) · Save your plan ×2 — two filled buttons (Apple's and
ours, 3.1), Apple's squarer radius (4.1), placeholder-only labels (§7), `danger` caption text at 4.10:1 (§7).

### CI run 35403203894 (c89ab00) — GREEN on five jobs · TestFlight run 35405188618 → **BUILD 197** · the tour-only dispatch 35405384572 (61063a2)

The journey ④ fix held; every job green; **build 197 uploaded 23:22Z** (`Upload succeeded`). ui-reviewer re-passed the plan editor ("3 × 8 · [glyph]
Barbell", one left edge, nothing truncated). The two new tour shots came back WRONG in that run — the reveal unscrolled, "Open …" tapped into the
session's bar — because a row under A19.1's bottom bar reports existing AND hittable; `tourScrollClearOfBottomBar` (a slow drag in the gutter until the
element clears the screen's bottom quarter) went up as 61063a2 with `[skip ci]` and was toured by a DISPATCH (A24 (3): tour-only, 21 min, can never
ship). It also explains an old oddity: the approved baseline named `07_onboarding_swap_sheet` is a picture of the SAVE screen — that tap has been
landing on "Looks good" since the tour was written.

ui-reviewer on the dispatch's three shots: **reveal rows PASS** (the chip on all five Push rows — ink, aligned, a label, two wrapped names handled
cleanly) · **onboarding swap sheet FAIL** · **session long-name card FAIL**. What failed, and what was done:

| Finding | A26's? | Done |
|---|---|---|
| The swap sheet has no Cancel — it can only be pulled down (DESIGN.md 4.2), on all three entry points | no, but the sheet is an A26 surface | `SwapSheet` gains a Cancel toolbar button |
| "Dumbbell Bench Press", the owner's named swap for row one of every plan, ranked FIFTH for a brand-new lifter — under the fold of the half-height sheet (level "some" sorts behind the level gate) | **yes** | its level is `brandNew`; both engines assert a row's FIRST named swap is within the first `swapCandidatesMin` offered, at every experience (R-079 (8)) |
| The not-yet-reached set rows are dimmed to 0.5 while live: labels ≈ 2.1:1, values ≈ 3.3:1, rings ≈ 1.7:1 (§7, 1.6) | no — every session shot since A10 | debt; a design ruling ("ghost" is Flow 3's word), not a token nudge |
| Opening a lower exercise leaves its header under the navigation bar, so the long-name header was STILL not in shot | no, likelier with five and six rows | debt; the session tour now pulls the page down before it shoots |
| The weight ruler's needle and the readout disagree | no | debt, undiagnosed |

### CI run 35407920313 (a6bcfd6) — GREEN on five jobs (attempt 2 for one transport reset) · TestFlight run 35409987054 → **BUILD 199, the A26 build**

contracts ✓ · web ✓ · ios engine ✓ · **ios ✓** (the app, every unit test and every UI journey — journey ④ included) · web e2e ✗ on attempt 1: journey ⑤ at
phone-375 died with `apiRequestContext.get: read ECONNRESET` on `GET /api/v1/users/me` — a connection reset by the runner's dev server, not an assertion, in a
journey this commit does not touch (it passed at 768 and 1280 in the same run and 50/50 here). Recorded in debt.md, then `gh run rerun --failed`: web e2e ✓.
**Build 199 uploaded 2026-09-19 00:40Z** — canonical templates, equipment symbols, the named swap leading its list, the swap sheet's Cancel.

**ui-reviewer, final pass (this run's tour):**

| Screen | Verdict | Verbatim in kind |
|---|---|---|
| onboarding swap sheet | **PASS** | "both earlier findings are fixed: Cancel is present as monochrome chrome and 'Dumbbell Bench Press' leads the list"; symbols monochrome, on the word's centre line, read as labels |
| session card, longest name | **FAIL — on pre-existing issues only** | "nothing A26 changed on it breaks a rule": the name wraps to two lines with no truncation; tag, Swap and Skip sit on one row, uncrowded, 44 pt frames at 8 pt gaps; the symbol is ink and aligned. The three FAIL items all pre-date A26: Set 2 / Set 3 dimmed to ≈ 2:1 and ≈ 3.3:1 text (§7) and ≈ 1.7:1 rings (1.6, §7); and Swap · Skip wearing the label's secondary gray beside the tag — "the tag reads as a third button, and the two real buttons read as labels" (§1's Ink row) |

**A26's screens, all passes together:** reveal (first viewport) · reveal rows · onboarding swap sheet · plan editor (re-passed after the row change) · exercise sheet ·
plan swap sheet · add-exercise sheet · logger start · logger mid-set · session swap sheet · Home filled · Home macros row — **12 PASS**; the long-name session card
FAILS on three pre-existing findings (debt.md; INVENTORY #1) that are the owner's design session's to rule on. Group B (not touched by A26): 11 PASS · 7 FAIL, listed above.

**Baselines were not touched.** The tour now has three more shots (`onboarding_plan_rows`, a real `onboarding_swap_sheet`, `session_logger_longname`), so CHANGES.md
reads "22 new · 7 removed" against the baselines — renumbering, not regressions; `/approve-screens` is the owner's.

NEXT (owner): install **199**; on a fresh account the plan is your Push / Pull / Legs — check the names (R-079 (3)), the five symbols (R-079 (6)) and that the dumbbell
bench press is the first swap offered for the flat bench; an existing account sees the templates after Rebuild my plan. NEXT (builder): nothing queued — the three
session findings above wait for the design direction.

## 2026-09-19 — W7 ACTIVATED: trycrew.fit, THE ASSOCIATION FILE, THE APPLINKS ENTITLEMENT (owner's account work done; readings R-080)

The owner attached `trycrew.fit` (with `www`) to the Vercel project, set `APP_BASE_URL=https://trycrew.fit`, `SUPPORT_EMAIL`,
`APPLE_TEAM_ID=PZ56UL99NM` and `RESEND_FROM=Crew <hello@trycrew.fit>`, and ticked Associated Domains on
`com.maxwellcuenca.crew`. The order: set the applinks variable, verify the association file, confirm the `onOpenURL` path and the
landing page, repoint stale hosts, build.

**W7's code half needed almost nothing — it was built in the 2026-09-18 pass and it was right.** What this session actually did:

| Item | State |
|---|---|
| `CREW_APPLINKS_HOST` | **set to `trycrew.fit`** (repository variable, 00:51Z). `testflight.yml:83/120` read it; `:85` rewrites the placeholder at `ios/project.yml:64` into `com.apple.developer.associated-domains: ["applinks:trycrew.fit"]` before `xcodegen`, and `:124` ad-hoc signs the archive with it. No file changed to enable it |
| The AASA route | reads `APPLE_TEAM_ID` (falling back to `APNS_TEAM_ID`) and `APPLE_BUNDLE_ID` only — it **never reads `APP_BASE_URL`**, so the document is host-agnostic and every host that reaches the app serves it. `force-dynamic`, explicit `application/json`, `max-age=3600`, modern `components` form, `/join/*` |
| Live check | `https://www.trycrew.fit/.well-known/apple-app-site-association` → **200**, `application/json`, `PZ56UL99NM.com.maxwellcuenca.crew`, `components [{"/":"/join/*"}]`. The apex answers **308 → www** (a Vercel primary-domain setting; nothing in the repo). **Apple's own cache proves the apex is still claimable:** `app-site-association.cdn-apple.com/a/v1/trycrew.fit` → 200, `Apple-From: https://trycrew.fit/…, https://www.trycrew.fit/…`; a nonsense host on that CDN → 404 — R-080 (1) |
| `onOpenURL` → A21.3 | confirmed in code: `RootView.swift:22` on the SCENE ROOT, above both branches, so a cold launch and a foreground both land; `InviteInbox` holds the token (path-only, host-agnostic); `OnboardingFlow.swift:45` (signed out) and `CrewScreen.swift:38` (signed in) each `consume()` it, fill `model.inviteCode` and call `lookUpInvite()` — literally the pasted-code path. `RootView.swift:68/70` opens the Crew tab |
| `/join/[token]` | confirmed: `page.tsx:39` renders `<CopyCodeButton token={token} />` under the printed `<code>{token}</code>` at `:38`, in the signed-out, not-full branch; it copies the raw CODE, not the URL. Dead and full links keep their explicit states (S13) |
| Hardcoded hosts | **no production code anywhere hardcodes the old host** — every runtime host is an environment or build variable. The 23 hits are docs and two parser fixtures |

**The one code defect the confirmation turned up — fixed here.** `route.ts` read
`process.env.APPLE_TEAM_ID ?? process.env.APNS_TEAM_ID`, and `??` only catches `undefined`. A host holding `APPLE_TEAM_ID` as an
EMPTY string — what a provider's console produces when a name is created and left blank — took the empty value, skipped the APNs
fallback the file's own header promises, and answered 404 with nothing to read. That is the 404 §2.2 of OWNER-REVIEW was written
around. Both ids are now taken trimmed, empty falling through; the trim matters just as much, because an id pasted with a trailing
newline builds a syntactically valid appID that Apple silently never matches. Two new cases in
`web/tests/api/app-site-association.test.ts` pin both. The production host was ADDED beside the old one in both invite-code twins
(`web/tests/engine/invite-code.test.ts`, `ios/CrewTests/InviteCodeTests.swift`) — not swapped for it: the old-host cases are the
evidence the parser ignores the host, and deleting them would delete the proof (R-080 (5)).

**Left deliberately undone, each with a reason (R-080):** only the apex is claimed, not `www` (2) · `CREW_API_HOST` stays on
`crew-eta-one.vercel.app`, because a POST to the apex takes a redirect hop and the old host is the same deployment and database
(3) · the Vercel primary domain is the owner's to flip (1) · `ios/project.yml`'s `aps-environment: development` was NOT
pre-emptively changed (6) — build 201 is the FIRST archive ever signed with the project's own entitlements, so the answer is read
off the run's "What the export signed" step rather than guessed at.

### CI run 35412369342 (0420cc9) — GREEN on five jobs, first attempt · TestFlight run 35413652316 → **BUILD 201, the W7 build**

contracts ✓ · web ✓ · web e2e ✓ · ios engine ✓ · **ios ✓**. Vercel deployed 0420cc9 to Production (GitHub deployment record: success) and the
association file answered 200 on every poll through the deploy. **Build 201 uploaded 2026-09-19 01:48Z.** Both W7 steps ran for the first
time and both are proven by the log: "Wire universal links" wrote `ios/project.yml:64 com.apple.developer.associated-domains:
["applinks:trycrew.fit"]`, and "Declare the entitlements on the archived app" ad-hoc signed the archive with
`aps-environment=development · applesignin=[Default] · associated-domains=[applinks:trycrew.fit]`. EXPORT SUCCEEDED, "Upload succeeded".

**R-080 (6) is NOT settled, and the step meant to settle it is blind.** "What the export signed" printed nothing: it found the
distribution log (otherwise it would print "no distribution log on this runner") and `grep -i entitlements` matched no line in it.
The run keeps no artifact and the export uploads straight to Apple, so the IPA the re-sign produced cannot be read from here. Every
Xcode App Store export re-signs `aps-environment` to the profile's `production` — it is how any project whose `.entitlements` file
says `development` ships push — and `testflight.yml:117` asserts it; but on THIS pipeline it has not been observed. `docs/debt.md`
carries the repair (print the exported IPA's own entitlements). The phone is the check: a push that arrived on 199 must still arrive
on 201.

NEXT (owner): install **201**, then OWNER-REVIEW §4.5 (the link) and one push; then §2.1, the Vercel primary domain. NEXT (builder):
nothing queued. The progress and debt lines for this run were held uncommitted (the owner's rule of 2026-09-18: no docs-only
commit) and rode the next real change — the A23 ratification below.

## 2026-09-19 — A23 EDUCATION COPY RATIFIED (owner, eight amendments; Appendix A, the line under A23; R-081)

The owner ratified `docs/education-copy-draft.md` with eight amendments. `shared/copy/education.json` is now the ratified source of
truth and `page.note.draft` is false. What moved, all in the one file and regenerated into both apps' copy:

| # | Where | Now |
|---|---|---|
| 1 | `why.crews` | "Your crew sees you show up. That's the whole system." (10 words) |
| 2 | `why.freeDinner` | "Same breakfast and lunch every day. Dinner's yours." (8 words; 18+ gate unchanged) |
| 3 | streak section | + "Rest days are free: the flame counts your training days, and a rest day never breaks it." — checked against A22 G1 (a) first |
| 4 | PPL section | "…and efficient — three sessions a week fits around a job." Recovery sentence unchanged |
| 5 | crews section | "Two to ten people"; first sentence → "Being seen is the whole system." (the builder's wording, R-081 (2)) |
| 6 | note from Max | "everything in here is what I do myself"; `draft: false` — the page's "Draft" label is gone on both platforms |
| 7 | "What the whispers said" | regenerated — both apps build it from the whisper list, still in trigger order |
| 8 | WHY 1 · no-merge · About placement | ratified as written |

**Verified locally:** `check-copy` passes with every line at 6–11 words (cap 12); `launch-audit`'s draft NOTE is gone (it prints only
while `page.note.draft` is true); the three `adult` gates are unchanged, so under 18 the page still lists nine lines and drops the
protein numbers and source. **Tests moved with the copy:** web journey `whispers.spec.ts` now asserts no "Draft", the ratified note,
the rest-day sentence and the two new list lines (and, under 18, the crews line present and the dinner line absent); iOS journey ④
asserts the ratified note from the generated copy and no "Draft". **The tour gains S19:** it had no shot of the page, so
`Tour_SettingsTests.testHowCrewWorks` photographs the note and PPL section, the streak and crews sections, and the whisper list, in a
method of its own so the eight existing settings shots keep their numbers. The two amended whispers already appear in the tour:
`01_crew_stream_filled` (why.crews; on the tour-diff's drift list, so reviewed by name) and `10_nutrition_template_filled`
(why.freeDinner). Docs: the draft document is marked RATIFIED with the amendments applied and its open section closed;
OWNER-REVIEW §2.6 and the §5 submission gate are done; `docs/mvp-definition.md` names the file as the source of truth.

Left alone, and why: the Crew tab's empty state still says "Two to ten friends" (`CrewSoloView.swift`, `CrewView.tsx`); amendment 5
names the page's crews section only (R-081).

### CI run 35415601598 (3953313) — GREEN on five jobs, first attempt · TestFlight run 35416946917 → **BUILD 202, the A23 ratification**

contracts ✓ · web ✓ · web e2e ✓ (the ratified-page assertions) · ios engine ✓ · **ios ✓** (journey ④ asserts the ratified note and no "Draft").
Build 202 uploaded 2026-09-19 02:56Z. Tour: 25 new (the three S19 shots among them) · 9 changed · 12 drift · 3 removed — every entry
except the S19 shots is baseline drift from earlier commits (A26 and before); baselines untouched, `/approve-screens` is the owner's.

**ui-reviewer, the five screens this change touches — 2 PASS · 3 FAIL, every FAIL pre-existing:**

| Screen | Verdict | What it said |
|---|---|---|
| S19 top (`01_settings_howcrewworks_top`) | **PASS** | the note in full, no "Draft"; card hairline correct; no ember |
| S19 middle (`02_…_middle`) | **PASS** | the streak and crews amendments in full, nothing cut |
| S19 whispers (`03_…_whispers`) | FAIL — pre-existing | the moment captions are lowercase fragments on their own line (§8 sentence case); both amended lines render and fit in two lines |
| Crew tab (`01_crew_stream_filled`) | FAIL — pre-existing | ~175 pt dead band above the bottom-pinned stream (§4.1); React a bare grey word (§1, 1.6); why.crews sits correctly and causes neither |
| Template (`10_nutrition_template_filled`) | FAIL — pre-existing | the whisper floats between row and card instead of `rowGap` under the list (§4.1); "Up" / "Down" are not verbs (§8) |

All three are in `docs/debt.md`. Reviewer notes on the OWNER's wording, no rule broken: amendment 4 puts three em dashes in one
sentence ("balanced — every major muscle gets its day — and efficient — three sessions…"), so the pairs can be misread; the page now
says "the whole point / game / system" (and the whisper "the whole system" again), and the streak paragraph says "The flame counts
days" and "the flame counts your training days" in consecutive sentences.

NEXT (owner): install **202** — Settings → About → How Crew works; the design direction for the pre-existing findings. NEXT (builder):
nothing queued. This run's record and the three debt lines are held UNCOMMITTED (no docs-only commits) for the next real change.

## 2026-09-19 — A27, THE SCREEN JOBS (owner-approved 2026-09-18): RECORDED, NOT BUILT (owner: "write them in; change no UI … docs only … report the file paths changed and stop")

- Recorded as Appendix A **A27**: the 48 screen jobs ratified as the test ui-reviewer applies, with the rule "A control that does not
  serve its screen's job is a candidate for removal. A job with two homes has one too many."; (a) training days are a standing
  setting; (b) Invite does only invite, the rest moves to a new Manage crew screen; (c) a dating or discovery layer joins A21.13.
  Markers on S13, S14, A21.13, the W3 record's item (4) and R-068 reading (1).
- Files: `design/INVENTORY.md` (46 Screen job lines — Saved meals / Template share one line, two sentences; new §12, the three
  inconsistencies for the design session) · `design/DESIGN.md` (Screen jobs + the rule) · `design/claude-design-brief/README.md` (Home
  and logger jobs; three more inconsistencies) · `docs/crew-mvp-spec.md` · `docs/debt.md` · `.claude/agents/ui-reviewer.md` ("Screen jobs" left the list of empty sections it must not judge by).
- Found while recording, NOT built (`docs/debt.md`): (a) contradicts both engines today — the recompute judges unposted past days by
  the CURRENT weekdays (R-068 reading 1, now overturned); honouring it needs plan-weekday history and new vectors, and how the days
  between a change and the next workout are judged is a SPECIFICATION GAP for that build. Change days has no forward-only line on
  iOS, and web says "apply from today". Both Invite surfaces still hold all five jobs.
- Left alone (recorded in `docs/debt.md`): `docs/OWNER-REVIEW.md`'s open plan-history row is answered by A27 (a) but not edited;
  `docs/mvp-definition.md`'s W3 row and Not Building mirror carry no A27 marker.

NEXT (owner): order A27's builds — Manage crew, the Change days line, and (a)'s engine half once its gap is ruled. NEXT (builder):
nothing queued. The build-202 record and its three debt lines are still held UNCOMMITTED, as before.

## 2026-09-19 — A27 (a) BUILT: THE TRAINING-DAYS HISTORY (owner ruling of the gap, 2026-09-18: "record as an amendment to A27, then build the engine half only")

- **The rule** (Appendix A, the line under A27): a day is judged by the training days in effect on that day; a change takes effect
  from the dayKey it is saved, forward, never backward; a completed session is never re-judged. Skip, "just today" swap, bonus and
  pause confirmed as not per-week overrides. The builder's readings where it was silent: **R-082** (chiefly: a day before the first
  entry is judged by the first entry, so every one-entry history judges exactly as before).
- **Built** (engine + server + storage; no UI): `training-days.ts` / `TrainingDays.swift` (the twins: weekdaysOn · isPlannedOn ·
  appendTrainingDays); postCreated carries `trainingDays` on both engines (all-rest, comeback and perfect week read the day they
  judge; a day the post has not reached reads the post's own day, so a later change never takes a reward back); the recompute
  folds take the history; `projectWeek` takes it. Server: `plans.ts` keeps an append-only `trainingDaysHistory` ($push, never an
  edit), migrates a pre-A27 plan to one entry from its creation dayKey on its first read, and takes a queued edit's `savedAt` inside
  E15's window. Readers: the fold (`gamification-store.ts`), the week marks and ring (`home-facts.ts`, `today-state.ts`), Progress
  rings, the journal Rest-day tag, `notification-facts.ts` (the cron). iOS: `LocalTrainingDays` in SwiftData **CrewSchemaV3**
  (lightweight from V2; `trainingDaysStoreSchemaVersion` = 3), `PlanLocal` its one writer (a local change of days appends; the
  server's history replaces), `GamificationLocal.judgeElapsedDays`, SessionActions, Home marks, NextUp, Plan week map, Progress rings,
  the journal tag. Web: the save status now reads "Saved · Changes apply from your next workout on." — the page's sentence.
- **Vectors V85–V90** (`shared/vectors/training-days.vectors.json`): mid-week change keeps the earlier days · a day after the change
  is judged by the new days · a perfect week spanning a change · a past miss and a consumed shield survive · a completed session on
  a no-longer-planned day still counts and still advances the rotation · an earned perfect week stands when a later change plans a
  remaining day. Each FAILS under the old reading (checked); none existing was edited.
- **Local gates, all green:** generate + drift · check-vectors (90 vectors, 12 files) · check-seeds · check-copy · launch-audit ·
  doctrine-lint · swift-xref · web lint · typecheck · `npm test` 53 files, 550 passed · `npm run vectors` 67 passed · build · e2e 50
  passed, 1 skipped · `swift test` 105 tests, 0 failures. Tests added: web `tests/engine/training-days.test.ts`,
  `tests/api/training-days.test.ts`; iOS `TrainingDaysTests` (Linux) and `TrainingDaysLocalTests` + a V2 → V3 store test (Mac only).
- **Owed, sequenced after the redesign** (`docs/debt.md`): the Manage crew screen (A27 (b)), the iOS Change days sheet's rule line,
  the `docs/mvp-definition.md` and `docs/OWNER-REVIEW.md` updates for A27 (b) and (c). OWNER-REVIEW's plan-history row is closed.
- Also committed here: the build-202 record and its three debt lines, held uncommitted until a real change.

NEXT (owner): the redesign. NEXT (builder): read this commit's CI verdict; nothing else queued.

### CI run 35423561463 (ca8f949) — GREEN on five jobs, first attempt · TestFlight run 35424726409 → **BUILD 204, the A27 (a) build**

contracts ✓ · web ✓ · web e2e ✓ · ios engine (Linux) ✓ · **ios ✓** — the macOS job compiled SwiftData CrewSchemaV3 and ran
`StoreMigrationTests.testABuild202StoreOpensAtV3AndKeepsItsRows` (the V2 → V3 stage is lightweight: plan and queued op survive),
`TrainingDaysLocalTests` (5/5), `TrainingDaysTests`, `VectorRunnerTests` (V85–V90 on the Swift engine). Build 204 uploaded
2026-09-19 05:46Z ("Upload succeeded"). Tour: the same 9 changed · 25 new · 7 removed against the baselines as run 35415601598 —
baseline drift from earlier commits; compared screen by screen with that run, every difference is the calendar (it ran on a
Friday, this one on a Saturday). Baselines untouched; `/approve-screens` is the owner's.

**ui-reviewer, the ten screens this change can reach (week strip, ring, Plan week map, Progress rings, Journal tag, onboarding
projection) — 1 PASS · 9 FAIL, every FAIL pre-existing and matching its baseline; no visual change was intended or made (the owner
ordered "no UI"):** Home ×4 — the card ~48 pt under the week sentence (§4.1), "PUSH DAY" / "TOMORROW" in caps (§8); Plan week map —
one uniform interval, Change days reads as an eighth row (§4.1); Charts — ten rows of empty cells before the answer, ember cells
tinting the tab bar (§1.1), a second scroll-length (§3.3); Charts lower — the sideways ring strip (§4.3), the chart stack (§3.3);
Journal — off-scale gaps and a rounder radius (§4.1); the plan reveal on a Saturday names no workout (Screen jobs; calendar-caused,
INVENTORY already records the blank rows). PASS: `07_onboarding_plan_rows`. All of it is redesign material. One reviewer note for the
owner: the Progress ring history shows 0/7 rings for weeks before the plan existed — unchanged by this build, because R-082 (1)
judges a day before the first entry by the first entry; a "no" to that reading would blank those weeks instead.

NEXT (owner): install **204**; the redesign. NEXT (builder): nothing queued. This record is held UNCOMMITTED (no docs-only commits).

## 2026-09-19 — A28 REVIEW ROUNDS: HOME ROUND 3, THE LOGGER ROUND 2, PROGRESS AND PLAN ROUND 2 (the build order's /ui-check loop)

- **CI so far.** R1 0cbe1cb: run 35440565004 green, TestFlight **207** (run 35441901646). R2 5297246: run 35442943275 red (ShellStatesTests named the deleted StreakFlame), fixed in b13fa51. R3 b1dd3dd: run 35443822338 red (key paths lost), fixed in 3051feb. 3051feb: run 35444308817 compiled and ran the tour; one journey red (Journey4:48, the classic uppercase header, rewritten in R6). R4 and R6 runs were cancelled by the queue. R7 91b4c7e: run 35445082374 in progress. TestFlight skipped every red run, so 207 is the newest build.
- **Reviewer verdicts (run 35444308817).** Home round 2: 13 PASS · 5 FAIL (done shots of the refusal, Log cardio, bonus sheet, rebuild sheet). Logger round 1: 0 PASS · 12 FAIL. Progress and Plan round 1: 2 PASS · 13 FAIL (the Plan week map passed, light and dark).
- **Shipped (this commit).** Every Home and Logger FAIL fixed forward (R-091): the chevron, the centred set, ⋯ as an ink action sheet, rounded digits, the large-detent sheet, the in-content Swap title, the full-screen celebration, the ink caret, Log cardio on the metric card, the bonus sheet on the system, Cancel on the rebuild sheet;; and Progress and Plan round 2 (R-091 (5)–(8)): the heat map as the season (pre-season days empty) with 30 pt cells, bottom-anchored empty primaries, the chart axis in ink, the Journal and the editor as cards (a visible Delete on each Journal row), the exercise sheet at its large detent with the equipment in words; the tour logs a set before Finish; Journey4 finds the Version line. Plan: Session, Home, Onboarding, Progress and Plan views → CardioLogModelTests (2) → vectors none (90).
- **def9a75 (the commit above).** Run 35447382627 was red on one compile error: a non-escaping row builder was captured by FocusCard's escaping closure (`WorkoutEditorScreen.swift:108`). The next commit builds the rows first. The R5–R7 run 35445082374 compiled; it failed two journeys, both fixed forward: Journey4 (the Version line, fixed in def9a75) and Journey2 ("Workout ✓" left the post card in R5; the journey now finds the card's summary line). Its tour went to ui-reviewer: Crew, Settings and Nutrition, round 1.
- **Next commit.** The compile fix. Also, from the R5–R7 shots: the Settings destinations, the chain picker and the held-sends sheet leave the platform's List (R-091 (9)). Then Home round 3, the Logger round 2 and Progress and Plan round 2 on its run, and the R5–R7 reviewers' FAILs fixed forward.
- **Owed** (`docs/debt.md`): the destructive confirm's platform red · the sheet scrim · the rebuild sheet's canvas (R-091 (4)) · Change days' ink discs (R-091 (8), the owner's).

## 2026-09-19 — A28 R7: NUTRITION (the owner's queued build order, item 7 — the last)

- **Shipped (iOS).** Nutrition is on the system's type and colours: Rounded Bold numerals, headings as card sub-headings, ink and `inkSecondary`. Today's three ways out are row buttons in one card; the template sits in a card; the fields have no chrome and the steppers are the 52 pt kind; the outline buttons are text buttons. The macro bars stay on the canvas (GAP 6 · R-084 (4)). Plan: Nutrition files → journey ⑤ and the Nutrition tour → vectors none (90).
- **Gates (local).** Recorded in the commit.
- **Build.** Expected **215**. CI, TestFlight and the ui-reviewer verdict on the Nutrition shots are recorded in the next commit.
- **Readings.** R-090: A16's colours stand, and the bars stay on the canvas · Today keeps no filled button · the copy is untouched.
- **Owed** (`docs/debt.md`): the macro bars' canvas constraint (GAP 6) · the web's nutrition pages (parity).

## 2026-09-19 — A28 R6: SETTINGS, GROUPED (the owner's queued build order, item 6)

- **Shipped (iOS).** Settings is one short page of cards, each row opening its screen: Profile, Pause (A23's whisper under it), Units (check rows: lb/kg lives here only), Notifications (the system's checks), Nutrition (absent under 18), Privacy & safety, Account (Delete: an ink row, then a red confirm), and How Crew works, with the version as a quiet line. Pause reads off-season; Profile and Blocked people are on the system's type. Plan: Settings files and `CheckToggleStyle` → Journey ④ ⑤, the photo-denied probe and the Settings and Nutrition tours → vectors none (90).
- **Gates (local).** Recorded in the commit.
- **Build.** Expected **214**. CI, TestFlight and the ui-reviewer verdict on the Settings shots are recorded in the next commit.
- **Readings.** R-089: the grouping follows the old section names · a check, not a switch · units as check rows · Delete account's red in its confirm · GAP 7 leaves How Crew works untouched.
- **Owed** (`docs/debt.md`): How Crew works (GAP 7).

## 2026-09-19 — A28 R5: CREW AND MANAGE CREW (the owner's queued build order, item 5)

- **Shipped (iOS).** Solo is one centred card with a single CTA. With a crew, the nav bar carries Manage and Invite. The strip, pulse, post cards and lines are ink on the system's cards; the comeback and the reaction counts are words. The Invite sheet does only invite. Manage crew is new: the Captain renames, replaces the link and removes members, and anyone leaves, each destructive action behind a red confirm. Create and join are system sheets, and the offline banner is a quiet line everywhere. Plan: Crew files → ManageCrewTests and the Crew tour (+ Manage, + dark) → vectors none (90).
- **Gates (local).** Recorded in the commit.
- **Build.** Expected **213**. CI, TestFlight and the ui-reviewer verdict on the Crew shots are recorded in the next commit.
- **Readings.** R-088: Manage crew is pushed from a nav-bar text button · every destructive crew action asks · reactions are words · the solo tab has no heading.
- **Owed** (`docs/debt.md`): the web's crew page (A27 (b) there too).

## 2026-09-19 — A28 R4: PLAN — THE WEEK MAP, CHANGE DAYS, THE EDITOR (the owner's queued build order, item 4)

- **Shipped (iOS).** The Plan tab draws its own title and the rotation line, then one card of the week (workout days as row buttons, rest days quiet) and a card with Change days and Rebuild my week. The saved line is quiet text; the Days sheet carries A27 (a)'s line and a Cancel. The editor has row buttons, the Undo at the top, and no Reorder mode: Move up / Move down in the exercise sheet is the one idiom. The exercise sheet uses the 52 pt steppers and text buttons; the swap sheet sits on the sheet surface. Both clients lose the time estimates and hold durations, and three constants are retired. Plan: Plan files → Journey ④ and the Plan tour (+ dark) → vectors none (90).
- **Gates (local).** Recorded in the commit.
- **Build.** Expected **211**. CI, TestFlight and the ui-reviewer verdict on the Plan shots are recorded in the next commit.
- **Readings.** R-087: the title in the page · row buttons for the outline buttons · A27 (a)'s one line · one reorder idiom (Move up / down) · no toast.
- **Owed** (`docs/debt.md`): onboarding's week rows and day toggles · the web Plan (parity).

## 2026-09-19 — A28 R3: PROGRESS — THE DATA SCREEN, THE SEASON, THE HEAT MAP (the owner's queued build order, item 3)

- **Shipped (iOS).** Progress is the data screen: its title, "This season · N weeks · N workouts", and one card with the heat map (ink on `heatEmpty`, the season's weeks, weekday letters). A tapped day's card sits below, then Charts and Journal as row buttons. Charts holds the totals, the work and the strength charts in ink; the ring history and the mobility minutes are gone. The Journal is pushed with its title: eyebrow day labels, an ink swipe before a red confirm, and a stored line's old minutes dropped at render. Web: the season line and the journal's strip. Plan: Progress files → SeasonFactsTests and progress-season.test.ts (identical cases), the SessionSummaryLine twins (+1 each), Journey ④ and the Progress tour → vectors none (90).
- **Gates (local).** Recorded in the commit.
- **Build.** Expected **210** (commit count: b13fa51 is 209). CI, TestFlight and the ui-reviewer verdict on the Progress shots (against `design/targets/12`, light and dark) are recorded in the next commit.
- **Readings.** R-086: GAP 1 admits the data screen for Progress alone · A19.4's segment becomes two row buttons · GAP 10: the season starts at the build or the end of the last finished pause · "done" is a workout.
- **Owed** (`docs/debt.md`): the season inputs (a rebuild, an early end) · cardio-only days draw empty · the web Progress layout (parity).

## 2026-09-19 — A28 R2: THE LOGGER — ONE SET PER SCREEN, THE SHEET, THE CHECKLIST, THE CELEBRATION (the owner's queued build order, item 2)

- **Shipped (iOS).** The Logger is one set per screen:
  - the workout bar;
  - one card of two metric rows (value buttons that open the keypad, with the system's 52 pt steppers);
  - last time on set 1, and the ledger after it;
  - Swap exercise and Skip as text, and one "Log set N".
  The whole-workout sheet and the holds' checklist carry Finish. ⋯ holds + set, + warm-up, remove / undo, plates and Discard. The celebration is ink and accent: "Counted.", no minutes, no emoji. No timers anywhere: the rest timer, the hold countdown, the weight tape and the in-session unit line are deleted with their constants. On the web, the rest timer and the countdown are gone and the done page has no minutes. Plan: Session files → SessionModelTests (+2) and journeys ①, the offline probe and the tour → vectors none (90).
- **Gates (local).** generate + check-drift ok · swift-xref · doctrine-lint · check-vectors 90 · check-seeds · check-copy · launch-audit (all clean) · web typecheck 0 · lint 0 · test 583 + 1 expected fail + 23 skipped · vectors 67 + 23 skipped · build ok · e2e: see the commit · native swift test 105, 0 failures.
- **CI (5297246).** Run 35442943275 went red twice on the iOS job. The first attempt found no iPhone 17 simulator (a runner-image miss). The re-run found one compile error, in a TEST: ShellStatesTests constructed the deleted StreakFlame. The app target compiled clean. b13fa51 fixes the test, and the Logger's tour and review ride the next push, together with R3.
- **Build.** Expected **208** (commit count). The commit also carries R1's review round-1 fixes (R-084's addendum), so its tour is R1's round 2 as well as R2's round 1. CI, TestFlight and both verdicts (Home against `01`–`06`, the Logger against `07`–`11`) are recorded in the next commit.
- **Readings.** R-085: GAP 2 keeps 6.4's tick / double / thump · GAP 9 keeps S10's "Counted.", with the badges as ink words · the count is the engine's facts · the equipment tag leaves the Logger · Discard is an ink menu item before its red confirm.
- **Owed** (`docs/debt.md`): the web Logger (parity) · bar groups under 44 pt on long workouts · the sheet's scrim is UIKit's · a dark shot of set 1 · the stale `unitsConfirmed` flag.

## 2026-09-19 — A28 R1: HOME, SIX STATES, LIGHT AND DARK (the owner's queued build order, item 1)

- **Shipped (iOS).** Home is the Focus Card: the reward block (ring + flame), one card with at most one filled primary, and the quiet rows (Quick complete, "Edit today's log" → the Journal, the Macros fact row). The "+" holds cardio and the bonus workout. The week strip, the vector rows and the crew strip are gone. There is a new shared kit (`TypeRoleStyle`, `FocusCard`, `FocusRing`, `QuietFactRow`, `Chrome`), and the tokens gained `focus`, `elevation` and `relativeTo`. The light lock is lifted, and the summary line lost its minutes on both engines. The tour shoots every state in both modes. Plan: Home and Shared files → HomeStatesTests, the tour, the twin's tests on both engines → vectors none (90).
- **Gates (local).** generate + check-drift ok · swift-xref · doctrine-lint · check-vectors 90 · check-seeds · check-copy · launch-audit (all clean) · web typecheck 0 · lint 0 · test 582 + 1 expected fail + 23 skipped · vectors 67 + 23 skipped · build ok · e2e 50 passed + 1 skipped · native swift test 105, 0 failures.
- **Verdict (build 207).** 0cbe1cb: CI run 35440565004 was green on five jobs, and TestFlight run 35441901646 was green: **build 207**. ui-reviewer round 1 gave 1 PASS · 21 FAIL. Every Home shot failed on three things: the iOS 26 glass tab bar and the glass '+' (fixed with `UIDesignRequiresCompatibility`, R-084 (10)); a missing holds row (the tour plan had no holds; fixed); and text-face numerals inside sentences (fixed with `Text(numerals:)`). The residue is in R-084's addendum and debt.md. Round 2 rides the R2 commit's CI.
- **Build (first push).** 47d773d: CI run 35440017680 went RED on one compile error (`HomeScreen.swift:133`: GeometryReader's escaping closure captured the non-escaping `centred` builder). Four jobs were green (contracts, web, web e2e, iOS engine). The fix-forward commit builds the column before the reader. Its build number (**207** expected), CI, TestFlight and the ui-reviewer verdict on the Home shots (light and dark, against `design/targets/01`–`06`) are recorded in the commit after it.
- **Readings.** R-084: GAP 3 keeps A18.1's count and A18.2's gate · GAP 4 keeps entered cardio minutes · GAP 5 puts the season line on the first-day card only · GAP 6 lifts the lock, because dark carbs fails only on a card no screen draws.
- **Owed** (`docs/debt.md`): the web Home (parity) · four dark defects on un-redesigned screens (lists, toggles, ghost row, sheets) · two card and two ring components in transit · WeekSummary with no iOS reader · the legacy OfflineBanner · sheet scrims (R2).

## 2026-09-19 — A28, THE FOCUS CARD REDESIGN — R0: TOKENS, RULES AND THE REGISTRY (owner: "session 1 of many … No screen code in this session")

The owner ratified a design system in Claude Design (`design/focus-card-system.md`) with twelve approved mockups, light and dark
(`design/targets/`; `01` dark only), and ordered R0: record the rulings, fill DESIGN.md, move the tokens, order the worklist.

**Plan as run (rule 5).** Files → the A28 entry + 35 marker lines + 9 screen-head markers in `docs/crew-mvp-spec.md`; `design/DESIGN.md`
(Direction / Component kit / Banned patterns from the system; §1–§8 re-cut to A28; Screen jobs unchanged); `shared/design-tokens.json`,
`shared/scripts/render-ember.mjs`, `shared/scripts/generate.mjs` → `EmberColors.swift`, `EmberTokens.swift`, `ember.css`;
`design/targets/README.md` (the mockup → tour-shot map) and `.claude/agents/ui-reviewer.md` (the matching mode);
`shared/scripts/launch-audit.mjs` (clause ② bans the successors `accent` / `destructive` on nutrition surfaces); `docs/mvp-definition.md`
(R0–R9); `docs/debt.md`; `docs/ratification.md` R-083; header notes on `design/INVENTORY.md`, `design/claude-design-brief/README.md`
and the system file. Tests → `web/tests/contrast.test.ts` (the table asserted row for row against the system document; every table
pair gated in both modes; the XP numeral as large text; the accent one hue in both modes; A16's dark carbs as KNOWN FAILING via
`it.fails`), `web/tests/token-parity.test.ts` (aliases, rgba, the type scale). Vectors → none (90 stay 90). No screen file touched.

| Area | State | Evidence |
|---|---|---|
| A28 (a)–(f), each on its own line naming what it supersedes; readings R-083 (1)–(25); GAPs 1–10 | DONE | Appendix A after A27; the sweep (9 agents, every Part and the registry line by line) placed the markers; an adversarial verify (5 reviewers, each finding re-checked) read the diff before commit |
| Tokens | DONE-VERIFIED | `colors` = the system's 18 rows (incl. `sheetScrim` rgba); `macroColors` = A16's 6, unchanged; `colorAliases` = 12 legacy names → one row each (`secondaryButtonOutline`, `success` retired: no reader); `typography` = 21 roles (§4 + §8's primary label and text button) · generate + check-drift ok |
| DESIGN.md, targets map, ui-reviewer | DONE | owner sections from the system; `design/targets/` stated as the approved mockups; reviewer reads the map and the matching mode |
| Worklist | DONE | `docs/mvp-definition.md` R0–R9 in the owner's order, each with its GAP preconditions |
| Local gates | DONE-VERIFIED | swift-xref clean (256 Swift files) · generate + check-drift ok · check-vectors 90 · check-seeds ok · check-copy ok · doctrine-lint clean · launch-audit clean (18 checks) · web typecheck 0 · lint 0 · test 53 files: 582 passed + 1 expected fail (dark carbs) + 23 skipped (retired vectors) · vectors 67 + 23 skipped · build ok · e2e 48 passed + 1 skipped by design, 2 transport resets (ECONNRESET under parallel workers) green re-run alone (6/6 across three viewports) · native swift test 105 tests, 0 failures |

**Token diff summary.** Light: canvas #FAF8F5 → #F7F1E4 · card #FFFFFF → #FFFCF6 · ink #211D19 → navy #142744 · secondary #6F6860 →
#4E5E78 · ember #DF5908 → accent #DE6400 · control outline #938C83 → inkMuted #7E8496 · danger #D64550 → destructive #BC2A1C. Dark
(Midnight, generated, unreachable until R1 lifts the lock): canvas #171412 → #0E1A2E · card #211D19 → #1B2A42 · ink #F5F1EB → #F2EEE6 ·
accent #FF7A1F → #FF8A2B. New rows: inkMuted, hairlineOnCard / OnCanvas, controlBorder, segmentEmpty / Current, chevron, ringTrack,
heatEmpty, tabBar, onInk, sheetScrim. Retired: emberText's orange (→ ink), emberTint's orange tint (→ ringTrack), success's green.

**Found on the way** (`docs/debt.md` 2026-09-19): the crew strip IS on Home on both clients (A20.6 was Build B's and never landed —
A28 (d) removes it in R1); the iOS rest timer's notification plays the default sound (haptics-only law; gone in R2); the web's Quick
complete shares without A21.9's choice; the web heat map's cardio outline never drew; five dark defects the light lock hides (grouped
lists, the ink-tinted Toggle, Sign in with Apple's black, the ghost row, sheets on canvas) — R1 fixes them as it lifts the lock.

**SPECIFICATION GAPS for the owner** (the A28 entry's end; each blocks the session named): 1 five or six screen types (R3) · 2 haptics
(R2) · 3 the ring's "4 OF 7" / zero week / shields line (R1) · 4 cardio minutes (R1) · 5 "Your season starts today" — reveal or Home
(R1) · 6 A16's macro colours; dark carbs 2.79:1 (before the lock lifts) · 7 How Crew works' tone section and duration line (R6) ·
8 illustrations (R9) · 9 the celebration's phrase and badges (R2) · 10 the season label's stored inputs (R3).

The adversarial review (5 reviewers, 42 findings, each re-checked by a skeptic: 32 confirmed and fixed before commit, 10 refuted) found, among others: two unmarked supersessions (1A bone, 1C black), law ③ listed as untouched, the XP unit needing a large-text size, restTimerDefaultSeconds read by the plan estimate (it now leaves in R4), the done card's minutes owed by R1, and the Macros row wrongly gated on a birth year.

**Verdict.** 575d8f3 pushed. CI run 35436938755 was green on five jobs, and TestFlight run 35438217119 was green: **build 205**. ui-reviewer on the recolored tour gave 2 PASS · 68 FAIL. The FAILs are the un-redesigned layouts the R-sessions own, plus five platform defaults the recolor exposed: black bars, black scrims, white List rows, grey placeholders and headers, and EmptyState on white (`docs/debt.md` "A28 R0 / tour verdict"). No baseline was approved.

NEXT: the owner's queued order (2026-09-19) replaced the wait. GAPs take the most conservative in-spec reading, tagged `// GAP:`, logged in `docs/ratification.md` (R-084 for R1), and the build order runs R1 → R7.

## 2026-09-18 — A23 EDUCATION LAYER: RECORDED AND DRAFTED, NOT BUILT (owner ruling: "record and draft, do not build … report the whisper list with triggers, and stop")

- The ruling arrived while W3b was being read (no W3b source had been touched) and it carries an explicit stop, so the "continue
  all remaining work" instruction is paused here. Docs only: `docs/education-copy-draft.md` (the whisper contract with the proposed
  server-side `whispersSeen` seen-state, the eleven whispers with lines · triggers · screens · gates, the merge decision — the reveal's
  1C swap whisper is kept, so the nine non-nutrition whispers are eight new plus it —, the "How Crew works" page S19 with the note
  from Max as a draft, seven sections in the owner's order with Schoenfeld 2016 and Morton 2018 linked, the whispers verbatim, the
  A16.a line, and the copy checks incl. the under-18 handling); Appendix A A23 (OWNER-DIRECTED, PENDING RATIFICATION of the copy doc,
  naming what it touches: 1C → a whisper system, S17 gains the row, S19 is new on both platforms, 5.6.2 / Part IX / api.md proposals);
  `docs/mvp-definition.md` W6 gains the page + nine whispers as a second session, W8 the two nutrition whispers + the shake line.
- NEXT (owner): ratify the copy document line by line (rewrite the note from Max); rule on A22's G1–G4; Build B. NEXT (builder, on the
  owner's word): W3b (the removal), then the A23 whispers and page, W7's builder half, W9's technical items, W8 as far as honest data allows.
## 2026-09-18 05:48Z — BUILD 150 (016721f) UPLOADED AND CI-GREEN: the one to smoke-test

- **CI run 35311124097 green on every job** for 016721f (light always via the Info.plist key + "launch: real UI first" + the C9 trim +
  the job-level concurrency): contracts · web · web e2e (32) · ios engine · ios (unit and all UI journeys, including HomeStates and
  journey ② landing on the new syncing chrome before the account arrives). **TestFlight run 35311167431 uploaded build 150.**
- Two lessons on the way, both repaid in the same hour: (1) a gate piped into `tail` hides its exit code — cadce76 went up with a
  doctrine C9 finding (HomeScreen at 201 lines) and CI failed in 13 s; chains now call `doctrine-lint.mjs` bare so a finding stops them.
  (2) `testflight.yml`'s concurrency group sat at WORKFLOW level, so the `workflow_run` event for that cancelled/failed ci run claimed
  the slot — even though its job was skipped by the `if` — and cancelled the live dispatched upload (run 35310448236) eight seconds in;
  the group now sits on the job, which a skipped job never enters.
- Observed, not chased: the ios job log carries two `CoreData … addPersistentStoreWithType … NSCocoaErrorDomain (512)` lines in the
  `xcodebuild test` step — identical count in the previous green run 35302729856, so pre-existing, tests green (debt.md).
- NEXT (owner): install 150, the ONE smoke test (invite by code · two celebration buttons + the reminder question · chat-free Crew ·
  Charts | Journal, Units, Version 0.1.0 (150) · light on a dark phone · a reinstall shows Home at once with "Syncing your week…").
  Still owed: Build B (A21.12), A22's G1–G4. NEXT (builder): nothing until those arrive.
## 2026-09-18 — OWNER-DIRECTED "LAUNCH: REAL UI FIRST" — SHIPPED (and the light ruling corrected: build 147 was still dark)

- **Light, corrected.** `INFOPLIST_KEY_UIUserInterfaceStyle` only applies to a GENERATED Info.plist; Crew's is written by xcodegen from
  `info.properties`, so build 147 still followed the phone. `UIUserInterfaceStyle: Light` now sits in `info.properties` and the root
  view carries `.preferredColorScheme(.light)` — build 148 (run 35309613003).
- **The skeleton, removed.** The owner: "this loading skeleton is awful, it looks nothing like the actual layout" + the HIG hierarchy
  (local first → background sync → progressive fill → small indicators). Recorded in Appendix A ("LAUNCH: REAL UI FIRST", with
  markers at 1A and 6.1) and executed: RootView shows the tabs the moment a session exists (`HomeSkeleton`, `pullIfEmptyBounded`
  and `hydrationMaxWaitSeconds` deleted); `ServerHydrate` pulls plan / journal / sessions / account IN PARALLEL and publishes
  `HydrationState` (isPulling · failedOffline · revision) — Home re-reads the Store on every bump (progressive fill); Home's `.loading`
  is its own header plus one card "Syncing your week from your account…" (`LoadingLine`), an unreachable plan is a retryable line
  never "Build your week"; a fresh-phone login no longer waits for the pull; `ListSkeleton` on Crew / Progress / the editor became a
  `LoadingLine` sentence; `Skeleton.swift` deleted; `skeletonPlaceholderRows` left spec-constants. ShellStatesTests covers the new
  `.loading` and the unreachable line.
- NEXT: the build after this commit is the one to smoke-test (light, no skeleton). Still owed by the owner: Build B, A22's G1–G4.
## 2026-09-18 — OWNER RULING: LIGHT ALWAYS (amends A21.10) — SHIPPED

- Build 145 on the owner's phone rendered dark because the phone is set to dark and the app followed it (UIUserInterfaceStyle
  Automatic). The owner said three times it should not be dark → recorded in Appendix A as "LIGHT ALWAYS", amending A21.10.
- **Correction (build 147 was still dark):** `INFOPLIST_KEY_UIUserInterfaceStyle` is honoured only when Xcode GENERATES the
  Info.plist, and the Crew target's plist is written explicitly by xcodegen from `info.properties` — so that build setting (Automatic
  before, Light in 19644c7) never reached the app; the app had simply followed the phone by default all along. The real switch is
  `UIUserInterfaceStyle: Light` inside `info.properties`, shipped in the follow-up commit together with `.preferredColorScheme(.light)`
  on the root view (the SwiftUI half; the plist key is the UIKit half — alerts, keyboards, share sheets).
- iOS (as corrected above): `UIUserInterfaceStyle: Light` in the Info.plist properties. Web: `render-ember.mjs` emits `color-scheme: light` and no
  `prefers-color-scheme: dark` block; `app.css` says `color-scheme: light`; Generated regenerated. Dark hex values stay in
  `shared/design-tokens.json`, unused (law ⑤ untouched). `Journey4_ScreensTests` keeps the light walk (launched with the phone
  claiming dark, to prove Crew stays light) and drops the dark test. mvp-definition's A21.10 row and the debt entry updated.
- NEXT: the build after this commit (CI → automatic TestFlight, or a dispatch) is the one to smoke-test; still owed by the owner:
  the launch-wait fix approval, Build B, A22's G1–G4.
## 2026-09-18 04:02Z — TESTFLIGHT REPAIRED: BUILD 145 UPLOADED (W2 → W6 reach the phone at last)

- The owner's dispatch (run 35304691405, build 143) died on the same certificate line, so the workflow-side repair was built
  in two runs: 4bd9aa5 tried a distribution-signed archive (refused: "conflicting provisioning settings" under automatic signing;
  its unsigned fallback archived, then the export said "No Team Found in Archive" — run 35304967694); 6abd914 archives UNSIGNED
  and hands the export `teamID` from the secret — **run 35305232232: ARCHIVE SUCCEEDED · EXPORT SUCCEEDED · Upload succeeded,
  build 145.** No development certificate is minted anywhere any more (debt.md entry repaid). App Store Connect processes for a
  few minutes; the owner deletes the old Crew (126) and installs 145 from TestFlight. Two automatic runs follow the two CI runs
  and may list higher numbers with the same code.
- Also this evening, on the owner's screenshots of build 126: the "freeze" on reinstall is RootView's launch skeleton waiting on
  the bounded hydrate (`hydrationMaxWaitSeconds` = 10; six sequential round trips, cold Vercel functions) — a proposed fix
  (parallel pulls, a shorter bound, a moving skeleton) awaits the owner's word; dark mode follows the PHONE (UIUserInterfaceStyle
  Automatic on 126 and master) — whether A21.10 means "light always" is an owner ruling to take.
- NEXT (owner): install 145, the ONE smoke test (five checks in the chat report), then one message with the rulings — appearance
  (follow the phone or light always), the launch-wait fix, Build B, A22's G1–G4. NEXT (builder, on that message): the small batch
  (appearance ruling, launch fix, smoke-test findings) and W3b if the GAPs are ruled — one push, one more build.
## 2026-09-18 — THE W3 → W6 PUSH: CI GREEN FIRST TIME (run 35302729856); TESTFLIGHT 142 BLOCKED ON THE CERTIFICATE CAP

- Pushed d3a501d..487710a (four commits: 3a2d744 W3 · f4ca012 W4 · 366bd10 W5 · 487710a W6) at 03:18Z. **CI run 35302729856: every job
  green on attempt 1** — shared contracts (generate · drift · vectors · seeds · doctrine) · ios engine (Linux) · web (lint · typecheck ·
  test · vectors) · web e2e (32 passed, 1 skipped) · **ios: the whole app target compiled with W3–W6 in it on the first try; 148 unit
  tests, 0 failures** (89 → 148: CelebrationPostTests, InviteCodeTests, ReminderOptInTests and the rest) · **12 UI tests, 0 failures**
  in 473 s — journey ① (with the reminder opt-in), ② (two buttons), ③ (the pasted code lands in the crew, the photo prompt), ④ light and
  ④ dark (every tab photographed), HomeStates ×4, Launch, CameraDenied, OfflineSession. The ios job took 13 min (was ~6): the two
  screenshot journeys and journey ③ are the difference — recorded for the CI-speed ledger, not repaid.
- **TestFlight run 35303576028 fired on the green and FAILED at Archive, build 142** — the same wall as build 136: "Choose a certificate
  to revoke. Your account has reached the maximum number of certificates" (then "No profiles for com.maxwellcuenca.crew", which follows
  from it). Nothing in the code can fix this; the owner revokes the runner-minted Apple Development certificates at
  developer.apple.com → Certificates, then `gh workflow run testflight.yml` (the dispatch numbers the build by commit count: 142).
- NEXT (owner): revoke the certificates and dispatch; install build 142; the ONE smoke test (Appendix A "GO FOR W3 → W6"). NEXT (builder,
  on the owner's word): W3b once G1–G4 are ruled · W7 once the accounts are in hand · W8 once the addendum is ratified and the A16.b
  rating recorded · W9 once the privacy/terms text exists. Nothing else is built before those inputs.
## 2026-09-17 (late) — W6 WALKTHROUGH FIXES (A19.4 · A21.10 · A21.11; A21.12 PENDING THE OWNER) — DONE LOCALLY, NOT YET PUSHED

- Every local gate green: drift · 56 vectors · seeds · doctrine-lint · swift-xref (207 Swift files) · web typecheck / lint / 448 tests /
  vectors / build · 32 e2e journeys (1 skipped) · 76 native Swift engine tests. The iOS app target compiles on CI only.
- Item by item (the builder's reading of each; Appendix A "W6 EXECUTED" has the detail): keyboard-aware Save (return-key chain +
  scroll-to-focused) · "Log in instead" with the typed email prefilled (both platforms) · an open past day in the Plan is the day alone,
  no dash (both; tests updated) · Progress background token: AUDITED, nothing hard-coded found, nothing changed · Progress empty CTA →
  today (Home) on both · A19.4 Journal segment at the top of Progress on both (iOS inline Picker; web `ProgressSegments`) · iOS "Units"
  section; web "Weight unit" / "Distance unit" · version: Info.plist reads `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` (the About row
  will show the TestFlight build number), web reads package.json + the commit · mobility names: done in W2 · A21.11: tab bar hidden in a
  session, non-active exercises as compact rows · A21.10: `Journey4_ScreensTests` photographs every tab in light AND dark for the
  owner's review · A21.12 Build B: the owner's call after the walkthrough — not taken.
- NEXT: the ONE push of W3 → W6 (`git push origin master`), read the CI verdict (the iOS app target's first compile of W3–W6), then the
  owner's smoke test. W3b waits on G1–G4; W7 on the owner's accounts; W8 on the addendum; W9 on the privacy/terms text.
## 2026-09-17 (late) — W5 SECURITY: PRIVATE PHOTOS · BOUND APPLE CALLBACK · SECURE COOKIES · REPORT RESOLUTION · DELETION LEFTOVERS — DONE LOCALLY, NOT YET PUSHED

- Web-only (no iOS source changed). Every local gate green: web typecheck / lint / 448 tests / vectors / build · 32 e2e journeys
  (1 skipped) · drift · 56 vectors · seeds · doctrine-lint · swift-xref.
- **Photos (8.7).** `lib/blob.ts` writes blobs PRIVATE and reads them server-side (`get`, the store token); `GET photos/[key]` STREAMS
  from either storage behind auth — the public-blob 302 is gone. Stranger 403 · unknown key 404 · no session 401 (`photos.test.ts`).
  The private-blob read path runs only once the Blob store is connected (W7); the local substitute streams the same way.
- **Apple web callback.** New `GET auth/apple/start` mints a nonce → signed short-lived `state` (HS256, `CryptoParams.appleStateTtlMinutes`)
  → `crew_apple_nonce` cookie (HttpOnly, SameSite=None, Secure) → 303 to Apple with `state` + `nonce`. The callback accepts only the
  matching triple (signed state · cookie · id_token nonce); every failure → `/login?apple=failed` with one line in the form. Every
  Apple href is the start route; the save form is a GET form that adds the browser's timezone on submit. `auth-apple.test.ts`: the
  start shape, the happy path, three refusals.
- **Cookies.** `cookieSecureFlag()`: `COOKIE_SECURE` when set, else `NODE_ENV === "production"` (`cookies.test.ts`; `.env.example`).
- **Reports.** `lib/reports.ts` (`openReports`, `resolveReports`) + laptop-only `scripts/resolve-reports.ts` (`--list` / ids; prints
  resolved and skipped; refuses on Vercel). No route resolves (`reports-resolve.test.ts`). `ReportDoc.resolvedAt` added.
- **Deletion leftovers.** The cascade also removes others' reactions on the user's posts, reports filed by / naming the user or their
  posts, the user's `emailOutbox` rows (by address) and `pushOutbox` rows; the "account deleted" email is the one row left
  (`account.test.ts` crawls). `docs/api.md` updated (photos, auth/apple/start + callback, cookies, reports).
- Found, not fixed (debt): a web Apple signup started from an invite lands on /crew without joining. NEXT: W6.
## 2026-09-17 (late) — W4 INVITE CODE · PUSH · TWO-BUTTON SHARE · PHOTO PROMPT (A21.3 · A21.4 · A21.9 · 1C) DONE LOCALLY, NOT YET PUSHED

- Every local gate green: drift · 56 vectors · seeds · doctrine-lint · swift-xref (206 Swift files) · web typecheck / lint / 443 tests /
  vectors / build · 32 e2e journeys (1 skipped) · 76 native Swift engine tests. The iOS app target compiles on CI only (read with the push).
- **Invite code (A21.3).** `InviteCode.token(from:)` ⇄ `inviteToken()` read the code out of a bare code or any link (tests on both).
  iOS: hero "I have an invite" → `InviteCodeScreen` (paste · "Find my crew" · the public preview line · S13 dead/full states) → the two
  questions → auth → join → the tab bar opens on **Crew** once (`LandingFlags`, set before the session exists; cleared if the join fails).
  Same entry on the empty Crew tab (`CrewSoloView` → `JoinByCodeSheet`, `CrewModel+Invite.swift`). The Invite screen shows the code +
  "Copy code". Web: hero → `/join` (paste → `/join/[token]`) or straight to the crew's page when the URL has a token; the landing page
  shows the code and the owner's **Copy code** button (`CopyCodeButton.tsx`).
- **Push (A21.4).** `ReminderOptInSheet` after the FIRST completed workout's celebration, once per account on the phone: 7:30 pre-filled
  (G12), "Remind me" → system prompt → `registerForRemoteNotifications` → the token through `OpKind.pushToken` (`PushRegistrar`, the
  `UIApplicationDelegateAdaptor`) → `reminderTime` saved; "Not now" → never again (E5). An authorized phone re-registers at every
  signed-in launch. The simulator has no APNs; the journeys answer "Not now" — the accept path is the device smoke test's.
- **Two-button share (A21.9).** `SessionActions.complete` records the workout and creates NO post; the celebration shows
  `GamificationLocal.preview` (what the tap will count); "Share to crew" / "Keep it private" (Done when solo) are the only exits
  (`interactiveDismissDisabled`); the tap runs `SessionActions.post` (the LocalPost, the engine for real, a second `patchSession` with
  `post`). Server: completion creates the post only when `post` is sent; a late `post` on a completed session creates it once
  (`postLateIfMissing`) — `tests/api/sessions-late-post.test.ts`. A celebration the app died under posts PRIVATELY at the next cold start
  (`postUnanswered`, remembered in UserDefaults — no schema change). `shareToCrewDefault` is gone from the celebration and the cardio log.
- **Photo prompt (1C).** `ProfilePhotoPrompt` once per account after the first join or create (after any invite sheet is down), web twin
  `PhotoPrompt.tsx`. C9: `CrewModel+Invite.swift` and `HomeModel+Celebration.swift` keep both models under the 200-line cap.
- Tests: `Journey3_InviteCodeTests` (new iOS journey ③), journeys ①/② + HomeStates updated (two buttons, "Not now"), `CelebrationPostTests`,
  `InviteCodeTests`, `ReminderOptInTests`; web e2e journey ③ extended; `invite-code.test.ts`. `docs/api.md` PATCH sessions updated.
- NEXT: W5 (photos auth-checked end to end, the Apple web callback, `COOKIE_SECURE`, the report-resolution script, deletion leftovers).
## 2026-09-17 (late, after A22) — OWNER GO ON ALL REMAINING WORK · W3 CREW SURFACE (A21.2) DONE LOCALLY, NOT YET PUSHED

- The owner: "Go continue working on all remaining work until full completion", read with the same night's clarification (every W
  pushed together at the end) and A22's reservation (G1–G4 are the owner's; W3b waits). Order: W3 → W4 → W5 → W6, one commit per W,
  ONE push, the CI verdict read once, one smoke test. W7/W8/W9 are carried to the edge of the owner's inputs.
- **W3 resumed from `wip/w3-crew-surface` (f8dbf22) by a squash merge onto master's tree** and verified on this machine: generate /
  check-drift / check-vectors (56) / check-seeds / doctrine-lint / swift-xref clean · web typecheck, lint, 438 tests, vectors, build ·
  32 e2e journeys (1 skipped) · 76 native Swift engine tests. The iOS app target's compile is CI's (macOS) — read with the push.
- What W3 is (Appendix A, "W3 EXECUTED"): message routes DELETED (`POST/DELETE crews/[id]/messages*`, `lib/crew-messages.ts`, the
  message report target); the `messages` collection stays for system lines; a legacy `message` row is never served; an older phone's
  queued `sendMessage` is rejected per op as `chatRetired` (400, non-retryable). `chatMessageMaxChars` / `chatComposerMaxLines` gone;
  `chatPollInterval*` → `streamPollInterval*` (values unchanged). Blocked members leave the pulse and the member strip on every route
  that builds them (`blockedIdsFor` threaded into `memberDots` / `pulseFor` / `streamFor`), with a test in `crew-stream.test.ts`.
  Captain rename / emoji from both Invite panels (`PATCH crews/[id]`, `renameCrew`). S12 solo copy "They react 🔥💪👏😂❤️." on both
  clients. iOS: composer, `MessageRow`, `draft`, `send()`, `OpKind.sendMessage` gone; web: `Composer`, `sendMessage`, `deleteMessage`
  gone; `StreamItem.kind` is `post | system` on both. `docs/api.md` updated. No vector changed.
- The wip branch is left in place (never pushed); master's W3 commit is the record. NEXT: W4.
## 2026-09-17 (late) — A22 DRAFTED (plate journal removed; PENDING G1–G4), W3 PARKED, W3→W6 GO PAUSED (docs-only; no source, vector or constant changed)

- The owner's evening go for W3 → W6 was executed as far as W3's code (composer and message routes gone, blocked members out of the
  pulse and strip, Captain rename on both Invite panels) and then PAUSED by the owner's later ruling: "W3 waits for the owner's go",
  and W3 → W6 are to be pushed together when all are done, not W by W. The W3 state is committed on the local branch
  **`wip/w3-crew-surface` (f8dbf22)** — UNVERIFIED (no gate has run on it), never pushed; master is back at the W2 state.
- **A22 drafted in Appendix A as OWNER-DIRECTED, PENDING** — nutrition is macro logging only (MyMacros+ shape); meal photo/text posts,
  the plate journal, are removed; four GAPs recorded verbatim and NOT resolved (G1 streak on rest days · G2 photos on workout posts ·
  G3 under-18 users · G4 Home's log rows). `docs/MEAL_POST_REMOVAL_MAP.md` lists every row with delete / rewrite / no-op and its GAP;
  21 vectors carry a meal or text post (V01, V03, V09–V12, V13–V15, V17, V18, V18b, V20, V21, V24, V26, V28, V29, V35, V36, V43) — listed,
  never edited — so the engine's meal branch and `xpMealPost` / `mealXpDailyCap` stay vector-bound.
- `docs/mvp-definition.md`: A21.5's row gains "the plate journal is removed"; a **W3b** session (the removal, deletion before polish,
  its GAP dependencies named) follows W3; flow 5 is marked pending G1. `docs/nutrition-addendum-draft.md` §8: "photos stay in the
  plate journal" struck.
- W2 delivery is still blocked on Apple's certificate cap (the owner revokes the runner-minted Apple Development certificates, then
  build 136 ships); nothing in A22 touches W2.
- NEXT: the owner rules G1–G4 and ratifies A22, then says go — W3 resumes from the wip branch (gates first), then W3b, W4, W5, W6, one push.
## Ledger

Phase 0 — contracts
- [x] T001 spec-constants ⚙ — DONE-VERIFIED (generate + check-drift, 2026-09-08)
- [x] T002 generate pipeline + check-drift ⚙ — DONE-VERIFIED (generate + check-drift, 2026-09-08)
- [x] T003 vectors V01–V40 (+V18b, V41–V50 = 51) — DONE-VERIFIED (check-vectors + `npm run vectors` 51/51, 2026-09-08); owner-ratified R-001
- [x] T004 seed exercises.json — DONE-VERIFIED (check-seeds, 2026-09-08)
- [x] T005 seed plan-templates.json — DONE-VERIFIED (check-seeds, 2026-09-08)
- [x] T006 achievements.json + docs/api.md — DONE-VERIFIED (check-seeds; achievements.test.ts + V45–V50 in `npm test`); the api.md `POST events` route that was missing now exists and is tested (Q03, events.test.ts 4 green)

Phase 1 — foundation
- [x] T007 monorepo scaffold ⚙ — DONE-VERIFIED (web: typecheck + lint + build 2026-09-08; ios: `project.yml` generated and built by the CI ios job, run 34252964640). No `Crew.xcodeproj` is committed — XcodeGen makes it on the runner (logged R-005)
- [x] T008 CI + doctrine lint ⚙ — DONE-VERIFIED (`gh run view 34252964640`: five jobs green; doctrine-lint clean here). `codemagic.yaml` is a never-run duplicate CI → Q07 deletes it (debt repaid)
- [x] T009 lib/db.ts + indexes — DONE-VERIFIED (`npm test` → db.test.ts, 2026-09-08)
- [x] T010 server auth — DONE-VERIFIED (auth.test.ts in `npm test`)
- [x] T011 email + password reset — DONE-VERIFIED (auth-reset.test.ts in `npm test`; Resend behind the outbox substitute)
- [~] T012 Sign in with Apple — PARTIAL: server verification + web callback DONE-VERIFIED (auth-apple.test.ts via a local JWKS); iOS AuthStore compiles on CI; the real Apple round-trip and the "manual device check" are BLOCKED-CREDENTIALS (Services ID, bundle id, a device)
- [~] T013 iOS shells + five-state scaffolds ⚙ — WRITTEN-UNVERIFIED (CI: compiles; ShellStatesTests 3 green on the simulator)
- [~] T014 SyncQueue + in-memory SwiftData tests — WRITTEN-UNVERIFIED (CI: SyncQueueTests 9 green on the simulator)
- [x] T015 standing-checks.gen.test.ts — DONE-VERIFIED (in `npm test`; every route under app/api/v1 is discovered)

Phase 2 — core loop
- [x] T016 DayKey twin — DONE-VERIFIED (V05–V10 in `npm run vectors`; Swift: docker swift test 25/25). The 8.3 DayKey UNIT tests both engines lacked were added (Q06): `tests/engine/day-key.test.ts` 9 green, `CrewTests/DayKeyTests.swift` 7 green on Linux
- [x] T017 engine streak + XP — DONE-VERIFIED (vectors 51/51 TS; Swift docker 18/18)
- [x] T018 shields + pause — DONE-VERIFIED (same)
- [x] T019 completion/undo/edit — DONE-VERIFIED (same; the "both engines" gate holds: TS 51/51, Swift 51/51 on Linux and under Xcode on CI)
- [x] T020 PlanGenerator + SwapFinder + property test — DONE-VERIFIED (plan-generator.test.ts + swap-finder.test.ts in `npm test`; Swift PlanGeneratorTests + SwapFinderTests in docker swift test)
- [~] T021 Onboarding S02–S04 — WRITTEN-UNVERIFIED (CI: journey ① walks S02→S04 on the simulator; screenshots reviewed R-052/R-053)
- [~] T022 SaveAuthScreen + Login (S05; S06 removed v1.9) — WRITTEN-UNVERIFIED (CI: journey ① saves with email)
- [x] T023 plans/sessions/sync API — DONE-VERIFIED (plans.test.ts, sessions.test.ts, sync.test.ts in `npm test`, incl. the iPhone batch replay)
- [~] T024 Home S07 — **A18 (2026-09-10 night): thirteen clauses + twelve defects on both engines; every numeral named, the ring off a zero week, the next-up block, the rest-day premise, full-width verb log rows, the paused state freed of its contradiction, the bridge back to one CTA, the all-done card reporting the day, the controlOutline token, a reachable offline state. Tests J028–J035 green HERE (web 446, e2e 32, Swift 76); every iOS VIEW is WRITTEN-UNVERIFIED — contract docs/home-plan-a18-2026-09-10.md**. Earlier: A17 (2026-09-10), and REBUILT for A3 on 2026-09-09 (rest-day and all-done CTAs, next-up line, bonus workout sheet, cardio log, camera toolbar button; HomeModelTests rewritten, 6 tests) — WRITTEN-UNVERIFIED (CI: HomeModelTests + HomeModelEdgeTests green; bridge and post-state screenshots reviewed R-053)
- [~] T025 Session S09 — CardioRow + live summary line + "Counted." added for A2 on 2026-09-09 (SessionModelTests +3) — WRITTEN-UNVERIFIED (CI: SessionModelTests green; journey ② logs 3/3 sets)
- [~] T026 Celebration + workout post + Posts API (S10) — PARTIAL: Posts API DONE-VERIFIED (posts.test.ts); web celebration DONE-VERIFIED (e2e journey ④); iOS half WRITTEN-UNVERIFIED (CI: journey ② reaches the celebration)
- [~] T027 Nutrition posting S11 + lib/blob.ts — PARTIAL: photos API DONE-VERIFIED (photos.test.ts: EXIF/GPS fixture stripped, ≤ budget, owner-only read); web posting DONE-VERIFIED (e2e journey ①, when it does not flake — Q02); iOS half WRITTEN-UNVERIFIED
- [~] T028 🛑 Journey ① (Phase 2 gate) — PARTIAL: green on a CI SIMULATOR (run 34252964640) and on web (three viewports); NOT run on a device; the gate is the owner's ratification of R-022/R-053

Phase 3 — crews & social
- [x] T029 Crews API — DONE-VERIFIED (crews.test.ts, incl. the mute test added by Q04: per member, visible on users/me, outsider 404)
- [x] T030 Messages + Reactions (+ blocks) API — DONE-VERIFIED (messages.test.ts)
- [~] T031 Crew feature S12–S13 (iOS) — A5 on 2026-09-09: strip pinned on top, solo explainer, crew-of-one invite card, composer from two members, auto-invite after create, report/block from the card, summary lines — WRITTEN-UNVERIFIED (CI: journey ② sees the crew-mate's reaction; Crew screenshot reviewed R-053)
- [x] T032 engine crew rules + comeback — DONE-VERIFIED (V37–V40 both engines; crew-rules.ts stream banners in crews.test.ts)
- [~] T033 Notifications — PARTIAL: push-token route + apns2 lib + eligibility unit tests + cron sender DONE-VERIFIED (cron-notifications.test.ts, notification-eligibility.test.ts); a push to a device is BLOCKED-CREDENTIALS (APNs key + a phone); the beta cron is daily (Hobby, debt)
- [x] T034 Moderation — DONE-VERIFIED (moderation.test.ts: report → email queue, blocks both ways, EULA gate)
- [~] T035 🛑 Journey ② + security matrix (Phase 3 gate) — PARTIAL: web journey ② DONE-VERIFIED (e2e, three viewports); iOS journey ② green on the CI simulator only; 8.7 items runnable here green (standing 403s, Keychain static check, HttpOnly, EXIF, cascade crawl, rate limits, `npm audit` 0); device-side items open

Phase 4 — web parity
- [x] T036 Web onboarding + plan builder — DONE-VERIFIED (build; e2e journey ① on 768 and 1280 today; 375 flaked once, passed alone)
- [x] T037 Web session logging + posting — DONE-VERIFIED (e2e journey ④ on all three viewports)
- [x] T038 Web crew/chat/progress + invite landing W1 — DONE-VERIFIED (e2e journey ③ on all three viewports)
- [~] T039 🛑 Playwright ①②③④ + Lighthouse + token parity (Phase 4 gate) — PARTIAL: token-parity.test.ts green; `npm run e2e` = 23 passed · 1 skipped (keyboard check on the phone descriptor, by design) · 0 failed after the Q02 helper fix (the first run of the evening had journey ① phone-375 flaking on a pre-hydration fill); Lighthouse budgets not enforced (`@lhci/cli` not on the allowlist — debt, BLOCKED on the owner approving the dependency)

Phase 5 — hardening
- [~] T040 Progress + Journal (S15–S16) — A6 on 2026-09-09 (day labels, summary lines, Sending ↻, empty state, cardio/mobility minutes) on both platforms — PARTIAL: web DONE-VERIFIED (build + e2e a11y sweep incl. /journal); iOS WRITTEN-UNVERIFIED
- [~] T041 Settings (S17): pause, export, delete cascade — A7 on 2026-09-09 (profile name + photo, notification toggles on server prefs, mute from the server, blocked people, legal pages, version, real log out) on both platforms — PARTIAL: routes DONE-VERIFIED (account.test.ts: export completeness, cascade crawl, pause) + web settings page (e2e sweep); iOS WRITTEN-UNVERIFIED
- [~] T042 Edge screens — PARTIAL: web DONE-VERIFIED (welcome-back.test.ts + lapsed-user.test.ts; stale-session and failed-upload components in the build); iOS WRITTEN-UNVERIFIED (CI: LapsedUserTests, ServerHydrateTests green)
- [~] T043 A11y + offline matrix + perf — PARTIAL: the web substitute audit DONE-VERIFIED (a11y.spec.ts: landmarks, names, labels, overflow at 375/768/1280); two 8.4 simulator probes WRITTEN-UNVERIFIED (Q09: CameraDeniedTests, OfflineSessionTests — first CI run pending); NOT done: Xcode a11y audit, VoiceOver, Dynamic Type XXL, Reduce Motion, the 8.6 offline matrix, launch signposts on device (all need a phone or a Mac), axe-core and Lighthouse (dependencies not on the allowlist)
- [~] T044 🛑 Security sweep + zero P0/P1 (Phase 5 gate) — PARTIAL: everything runnable here green today (standing checks, `npm audit` 0, EXIF, cascade, rate limits); one hygiene finding fixed by Q01 (a local `.env` with real vendor keys could reach the e2e harness); device items and the owner's ratification open

Phases 6–7 — beta & release
- [~] T045 TestFlight + web beta + metrics — PARTIAL: `npm run metrics` DONE-VERIFIED (metrics.test.ts); `.github/workflows/testflight.yml` RAN for the first time 2026-09-08 21:36Z (run 34281494452, workflow_dispatch build 1) with real credentials — App ID `com.maxwellcuenca.crew` on a NEW App Store Connect record "Crew: Train. Track. Show up." (SKU crew-2; the old rejected record is not reused), Team PZ56UL99NM, Admin API key AXVB98H4DM; the secrets/variables were set from this machine with `gh secret set` / `gh variable set` (the key from the downloaded .p8, never printed): xcodegen + ARCHIVE SUCCEEDED — cloud signing issued the certificate and profile, so the Admin-role finding held — then App Store Connect refused the upload: ITMS 90022/90713/90023, no app icon. FIXED the same hour: `ios/Crew/Assets.xcassets/AppIcon.appiconset` (first the owner's sloth icon from the earlier product — REJECTED by the owner once it showed in TestFlight; since F17 the Ember flame on the bone canvas, source `shared/brand/app-icon.svg`, rendered with sharp to an opaque 1024 px PNG; single-size catalog, Xcode derives every size and writes CFBundleIconName) + `ASSETCATALOG_COMPILER_APPICON_NAME` in project.yml (F15). UPLOADED 2026-09-08 ~21:58Z: run 34282978517 (build 2, commit 344791a, `gh workflow run testflight.yml -f build_number=2`) — every step green including "Export and upload"; the first build of the native app reached App Store Connect from a Windows machine (App Store Connect numbered it 0.1.0 (1) — `manageAppVersionAndBuildNumber` picks the next free number regardless of the input). The owner rejected the sloth icon on sight; run 34285838041 (commit 3854845, F17, 2026-09-08 22:29Z) uploaded the build with the Ember flame icon — every step green, "Upload succeeded" — PROCESSED by 2026-09-08 22:39Z: TestFlight lists 0.1.0 (1) sloth and 0.1.0 (2) flame, both "Ready to Test" (no export-compliance hold), Invites/Installs still "–" because NO internal group exists yet; the iPhone's TestFlight app therefore shows only the OLD record ("Crew — Train. Track. Show up.", em dash, sloth, "Build Removed") under Previously Tested — TestFlight has no catalog, an app appears only after an invite. DONE 22:55Z: the owner created the Internal Testing group `beta-test` (group id 76ab034e-0273-4d57-b99b-1587e678d227) with both builds attached and themselves as the single tester — status "Invited", i.e. Apple's invitation email is out and not yet accepted, which is why the phone still shows nothing (internal testers must accept from the email's "View in TestFlight" button or the Accept row in the TestFlight app, signed in with the same Apple ID as the App Store Connect user). NEXT: the owner accepts the invite on the phone and installs build 2; then the APNs key → Vercel (APNS_KEY_ID/TEAM_ID/PRIVATE_KEY/BUNDLE_ID, APNS_ENVIRONMENT=production, APPLE_BUNDLE_ID)
- [~] T046 Production env, monitoring, backups, rotation — PARTIAL / BLOCKED-CREDENTIALS: Atlas M0, Resend, Blob values exist in the owner's local `web/.env` (never printed, never committed); Vercel project `crew` (team `maxs-projects-4a767c36`) is DEPLOYED from master `e9fe41f` at **https://crew-eta-one.vercel.app** — `/` → 200 "Crew", `/api/v1/users/me` → 401 (2026-09-08 ~18:50Z); the first two builds failed because Root Directory was `.` (log: "No Next.js version detected"), now `web`; variables on the project: APP_BASE_URL, COOKIE_SECURE, RESEND_FROM, MONGODB_DB, RESEND_API_KEY; the secret ones went in through `vercel env add` typed by the owner (the browser form never landed them); the first MONGODB_URI failed with `MongoServerError: bad auth`, the regenerated one still 500'd because `MONGODB_DB` no longer held `crew` (`MongoInvalidArgumentError: Database names cannot contain the character '.'` — the value had been edited in the dashboard); reset through the CLI, redeployed, and `POST auth/register` → 201 against Atlas at 2026-09-08 22:03Z (the smoke account was deleted through `DELETE users/me` right after); STILL MISSING: BLOB_READ_WRITE_TOKEN (Blob store `crew-photos` not connected to the project — photo posts fail until the owner clicks Connect to Project); the Vercel CLI is logged in on this machine (`npx --yes vercel@59.11.7 <cmd> --scope maxs-projects-4a767c36`; a scratch-folder link OUTSIDE the repo gives `env ls` / `redeploy` / `inspect --logs`); the agent may not read secret values or the CLI token (auto-mode classifier blocks it) — the owner enters secrets in the UI, the agent adds only public values; monitoring/backups/rotation deferred to launch (debt)
- [ ] T047 🛑 App Store submission — NOT STARTED beyond the registry audit (R-040) and the launch checklist (OWNER-REVIEW §8); needs a TestFlight build first

## Gap-closure queue (strict dependency order — work top to bottom, one at a time, verify by command, commit per item)

- [x] Q01 (done 2026-09-08: `grep RESEND_API_KEY dev-server.mjs` → pinned ""; `ios/.env` absent; journey ③ 3/3 green on the isolated harness) Harness isolation + env hygiene — `web/tests/e2e/dev-server.mjs` blanks `RESEND_API_KEY`, `BLOB_READ_WRITE_TOKEN`, `APNS_*`, `MODERATION_INBOX` so a local `web/.env` with real keys can never reach the Playwright harness (rule 3b; today it reaches `next dev`); delete the stray `ios/.env` (a byte-for-byte duplicate of `web/.env` that nothing under ios/ reads); add `APP_STORE_URL` to `.env.example`. Verify: `grep -n "RESEND_API_KEY" web/tests/e2e/dev-server.mjs`; `ls ios/.env` → absent; `npm run e2e -- journey3` green. [SPEC: rule 3b; Part IV; 8.7]
- [x] Q02 (done: full `npm run e2e` 23 passed · 1 skipped · 0 failed) Journey ① phone-375 flake — `fillWhenHydrated` clears the field before each fill (a fill that lands before hydration seeds React's value tracker, so a later identical fill never fires onChange). Verify: `npx playwright test journey1 --project=phone-375 --repeat-each=3` green, then the full `npm run e2e` green. [SPEC: 8.4; 8.9; XI T039]
- [x] Q03 (done: events.test.ts 4 green; standing checks 139 green incl. `events:POST`; typecheck + lint clean) SERVER: `POST /api/v1/events` (docs/api.md, R-004; 1C/1D funnel instrumentation "measured, funnel-instrumented") — canonical 5.6.4 shape, `clientEventsSchema` (already in validate.ts), source "web"/"ios"; integration test (`tests/api/events.test.ts`: inserts with the caller's userId, rejects a malformed body, standing checks discover it); the web client posts the funnel steps (hero shown · plan built · plan saved · bridge → first post). Verify: `npm test tests/api/events tests/api/standing-checks`. [SPEC: 1C; 1D; Part IV analytics; docs/api.md]
- [x] Q04 (done: crews.test.ts 7 green) SERVER: `PATCH crews/[id]/mute` dedicated test — mute round-trips through `GET users/me` (`crew.muted`), unmute clears it, a non-member is 404. Verify: `npm test tests/api/crews`. [SPEC: E2; S17; 8.2]
- [x] Q05 (done: validators.test.ts 7 green) 8.3 validators unit test — `tests/engine/validators.test.ts`: every input limit constant at the limit and one over (caption 280, crew name 30, exercise name 60, chat 1000, display name, password min, plan ceilings, reps/weight/hold, emoji, report reason, timezone rule). Verify: `npm test tests/engine/validators`. [SPEC: 8.3; E20; Flow 8; C7]
- [x] Q06 (done: day-key.test.ts 9 green; docker swift test 25/25) 8.3 DayKey unit tests on both engines — `tests/engine/day-key.test.ts` (3 AM boundary, Monday weeks incl. Sunday, DST both ways, daysBetween across a DST change, east/west travel) and `ios/CrewTests/DayKeyTests.swift` added to `Package.swift` test sources so the Linux job runs it. Verify: `npm test tests/engine/day-key`; docker swift test. [SPEC: 8.3; 5.2; E8; E20]
- [x] Q07 (done: `git status` shows `D codemagic.yaml`; check-drift + doctrine-lint clean; R-055 written) Tree hygiene + ratification R-055 — delete `codemagic.yaml` (never run; Actions unlocked and green; a second CI that must not drift; carries the owner's email in a public repo) and its Stage-1 section in docs/testing-without-a-mac.md; move its debt line to Repaid; R-055 logs the full 5.2 tree diff (every extra kept with its justification, every spec path absent and why). Verify: `git status` shows the deletion; check-drift + doctrine-lint green. [SPEC: 5.2; XI T008; debt 2026-09-08]
- [~] Q08 (WRITTEN — doctrine-lint clean on 132 files; compiles on the next CI ios job) iOS C10 file split — `MessageRow` out of StreamList.swift and `CreateCrewScreen` out of InviteScreen.swift into their own files per the 5.6 map ("one screen per file"). WRITTEN-UNVERIFIED; CI compiles it. Verify: doctrine-lint; the next CI ios job. [SPEC: C9; C10; 5.2]
- [~] Q09 (FIRST CI RUN 34282955601, push 344791a, 2026-09-08 22:07Z: the unit scheme green; in the UI scheme everything else passed but `OfflineSessionTests.testACheckedSetSurvivesAKillAndHomeOffersResume` FAILED at OfflineSessionTests.swift:52 — after "Start your first workout" no button whose label contains "set 1 of" appeared within 5 s; the xcresult with screenshots is in that run's `ios-test-results` artifact; the `ios` CI job is RED until this is fixed or the probe is adjusted) 8.4 state probes (XCUITest) — `CrewUITests/CameraDeniedTests.swift` (no camera → text-first posting completes) and `OfflineSessionTests.swift` (Resume-after-kill: start a session, terminate, relaunch, the Resume banner and the checked set survive; airplane mode is device-only and stays a manual 8.6 item). WRITTEN-UNVERIFIED; the CI ios job runs the scheme. Verify: next CI run. [SPEC: 8.4; S07; S09; E6]
- [x] Q10 (done: docs/OWNER-REVIEW.md rewritten 2026-09-08 evening) docs/OWNER-REVIEW.md regenerated — the four-state matrix (✅ DONE-VERIFIED / 📝 WRITTEN-UNVERIFIED / 🔌 BLOCKED-CREDENTIALS / ❌ NOT DONE) for T001–T047 and the ordered ship path. [SPEC: Appendix A continuous build (5)]
- [x] Q11 Deploy check — host = `crew-eta-one.vercel.app`; DONE 2026-09-08: `/api/v1/users/me` → 401 and `/` → 200 (18:50Z, after the Root Directory fix); `POST auth/register` → 201 against Atlas (22:03Z, after MONGODB_DB was reset to `crew`); **journey ① PASSED against production** at 22:08Z (`BASE_URL=https://crew-eta-one.vercel.app npx playwright test journey1 --project=desktop-1280`, 19.6 s: fresh visitor → questions → plan → save → first post → flame lit). Left in the beta database: that run's `j1-…@example.com` user, plan and post — drop the `crew` database from Atlas Data Explorer before real testers. The smoke account was deleted through `DELETE users/me` (see Q12). Never run the whole matrix against production: Vercel overwrites x-forwarded-for, so the G11 auth limit (10/min) counts every test from one address.
- [x] Q12 (done 2026-09-18: `npm test tests/api/account` → 7 passed; the email is best-effort after the cascade, one log line, the response stays 200; the test points the real Resend transport at a closed local port) SERVER: `DELETE users/me` reports a completed cascade as a failure when the "account deleted" email cannot be sent — seen on production 2026-09-08 22:10Z: the smoke account was gone (`users/me` → 404) but the response was 500, because `lib/account-delete.ts` awaits `sendAccountDeletedEmail` after the irreversible cascade and Resend's sandbox sender refuses any address but the account owner's. Fix: the email is best-effort after the cascade (try/catch + one log line; the response stays 200 with the cascade done — E9 promises the confirmation "states the cascade is done", not that the deletion waits on it); test: `account.test.ts` with a throwing transport (`RESEND_API_KEY` set to a junk key makes `deliver` throw) expects 200 and the cascade. Verify: `npm test tests/api/account`. [SPEC: E9; 8.2 Account; Part IV email touchpoints] [SPEC: XI T046; OWNER-REVIEW §5 step 6]
- [ ] Q13 OWNER-VISIBLE — the App Store Connect Apps list draws a grey placeholder for "Crew: Train. Track. Show up." while "Crew — Train. Track. Show up." draws the sloth, so the two records cannot be told apart at a glance. **This is not a repo defect.** `ios/Crew/Assets.xcassets/AppIcon.appiconset/AppIcon.png` is a valid 1024×1024, 8-bit, colour-type-2 PNG — RGB with **no alpha channel**, which is the thing Apple rejects an icon for — it is wired as the single universal 1024 entry in `Contents.json`, and `actool` compiles it into the bundle on every build (`--app-icon AppIcon`, visible in the run log). App Store Connect draws that list icon from each record's most recently PROCESSED build, so a record that has never received one shows the placeholder. The icon therefore appears on whichever record `vars.CREW_BUNDLE_ID` names, once the first green-CI TestFlight upload finishes processing. Verify after that upload: the Apps list shows the sloth on the record being shipped. If the placeholder is still on the record the owner wants to ship, repoint the `CREW_BUNDLE_ID` repository variable (Settings → Secrets and variables → Actions → Variables) at that record's bundle id — nothing in the repo names the account. [SPEC: XI T045; Part X Phase 6]
- [ ] Q14 swift-xref learns the one type rule it can actually prove — two consecutive runner-only reds (34586326598 `cannot find 'userId' in scope`; 34589239435 `cannot convert '[Int]' to 'Set<Int>'`) were both invisible to it because it label-checks call SHAPES, and neither error was a shape. It already parses each parameter's declared type at `shared/scripts/swift-xref.mjs:163` and then throws it away, keeping only `closure`/`variadic`. Narrow, high-precision addition: keep the type string; inside a function body build a map of the ENCLOSING function's own parameter names to their declared types; at each already-checked call site, when an argument is a BARE IDENTIFIER in that map and both declared types are concrete, flag a mismatch. That is exactly the 34589239435 shape. Precision over recall stays the rule (the file's own stated philosophy): skip generics, protocol-typed parameters, optional widening, subclassing and every literal, because a literal legitimately coerces where a typed variable does not — which is the whole reason this bug existed. Verify: a scratch copy with `days: [Int]` re-introduced reports it, the real tree is clean, `node shared/scripts/swift-xref.mjs` green. [SPEC: 5.3; 8.4; XI T008]

## Blockers

- OPERATING MODE (Appendix A, 2026-09-04): CONTINUOUS BUILD — no 🛑 stops the line; former checkpoints are self-reviews in docs/ratification.md; gaps get the most conservative in-spec call tagged `// GAP:`; iOS is WRITTEN-UNVERIFIED (no Xcode here; GitHub's macOS job is the compiler); no real credentials in the repo or the chat.
- BLOCKED-CREDENTIALS (owner steps, docs/testing-without-a-mac.md Stage 2): the Atlas password (production `MONGODB_URI` fails with "bad auth" — the owner is regenerating the `crew` user's password and replacing the variable; the Blob store `crew-photos` is still not connected) (T046) · the APNs key → Vercel (T033; the Team ID and bundle id are known) · a Services ID for web Sign in with Apple (T012) · an iPhone for the device pass (T028/T035/T043).
- ⏳ W070 — THE AGE QUESTIONNAIRE GATES THE APP STORE SUBMISSION ONLY (A16.b, owner task; reworded 2026-09-18 per the owner's order of that day: "proceed, gate only the App Store submission on it"). It was written as W8's entry gate; W8 is BUILT and on TestFlight (build 191), the addendum is RATIFIED (`docs/nutrition-addendum.md`), and nothing in the code waits on it. What stays open: the owner re-answers App Store Connect → App Information → Age Rating with nutrition targets, the one bodyweight and invite-only user-generated posts in mind, and the rating Apple returns is recorded HERE before T047 (`docs/OWNER-REVIEW.md` §2.5, §5). Rating recorded: — (not yet). The A16.c birth-year GAP is CLOSED by A21.5 — birth year is asked at the moment Nutrition is opened.
- OUT OF MVP (A21.13, 2026-09-17) · ⏳ STAGE 8 SHIP GATE (A13, owner task, post-MVP): lawyer confirmation on CC BY-SA 4.0 assets inside a FairPlay-protected binary. Vendoring, the hash test and the attribution screen may be prepared behind a feature flag; nothing reaches TestFlight until it clears.
- CLOSED 2026-09-17 by A21.7: Firebase Auth rejected; custom auth is the standing decision (Appendix B carries the marker).
- A24 THE VISUAL FEEDBACK LOOP (owner-approved 2026-09-18 with three amendments; Appendix A) — **ON MASTER** since 2026-09-18 (PR #2 merged 10:43Z as 794f231, PR #1 merged 11:15Z as 37a86e0, joined to the completion work by merge 0764323; both branches are gone from origin, the worktree is removed; verified from the main checkout — see "0aaaa51 → 8c83a74" above; no longer a blocker, kept here as the record). Built on branch `a24-visual-loop`; DONE-VERIFIED by CI run: the tour (7 `Tour_*` flows, 51 screens, seeded through the real API; run 35329440316 green, 18 min) · `ci.yml` extended, no second workflow (dispatch + any-branch UI pushes; tour-only off master; testflight.yml ships push runs only) · `tour-diff.mjs` + the `ui-tour` artifact · `design/baselines/` seeded (51 PNGs, 12 MB) · the SessionStart fetch hook · ui-reviewer · /ui-check · /approve-screens · launch arguments Debug-only. OWNER 2026-09-18 (later): A25 THE DENSITY PRINCIPLE RATIFIED → spec 6.9 + Appendix A A25 · design/DESIGN.md written (cited digest, four empty owner sections) · CLAUDE.md + 5.4 rule 13 with the @design/DESIGN.md import. The tour now lands OUTSIDE the repo on the owner's machine: user env CREW_TOUR_DIR = OneDriveDesktopCREW_2.0-SCREENS, one folder per branch, refreshed every 10 min by the Windows scheduled task "Crew UI tour sync" (`fetch-tour.mjs --sync`; the owner registered it — the agent's classifier refuses scheduled-task commands). [2026-09-18 later: the OWNER changed the trigger to DAILY (04:08 local, StartWhenAvailable) — the 10-min run flashed a console window. Checked: nothing depended on 10 min — the SessionStart hook fetches the session's own branch, /ui-check fetches its own run, /approve-screens reads the folder those two filled; the task only keeps the OTHER branches' OneDrive folders fresh, now up to a day late. The cadence stays in Task Scheduler, not in the script; the only bound is the artifact's 7-day retention.] PR #2 (the scratch branch, carrying A24 up to a9296f7) was merged to master by the owner; PR #1 carries the rest. NOTE FOR ANY SESSION: master's ios + web-e2e jobs were already red at 258c543 / a34e4a1 (CelebrationPostTests, SyncQueueTests, HomeStatesTests.testRestDayAsksNothing — A22 follow-ups, another session's work in the main checkout); A24 was built in the worktree C:	mpcrew-a24 to stay out of that session's uncommitted files.
- Git: UNBLOCKED 2026-09-17 — the agent commits and pushes directly (never a force-push, a history rewrite or a branch deletion; the hook enforces exactly those). The commit queue is retired for new work; F46 (Build B) is the one block still held in it.

## Notes for next session

- **2026-09-19 00:45Z — START HERE.** A26 (the owner's canonical Push / Pull / Legs, 3×8 · 4×8 · 5×8, named swaps, equipment symbols) is on master and on TestFlight as **build 199** (a6bcfd6; CI run 35407920313 green). Nothing is queued for the builder. Open from that session, all the owner's: the web chip without a glyph (R-079 (5)), the five symbols and six renamed rows to look at on the phone (R-079 (3)(6)), `/approve-screens` (the tour gained three shots, so CHANGES.md reads 22 new · 7 removed — renumbering), and three pre-existing session findings ui-reviewer failed (ghost set rows under the contrast gates · Swap / Skip in label gray · an opened exercise's header under the navigation bar — debt.md) that wait for the design direction. The note below is the state before A26.
- **2026-09-18 21:06Z — (superseded by the line above)** Master (e89d9f5) is green — CI run 35391799095, five jobs — and the six-item order is complete: TestFlight **build 193** (run 35394604478; the same phone app as 191, plus nothing — Q12 is server-side and ships through Vercel) is the one for the phone checklist (`docs/OWNER-REVIEW.md` §4). Everything left before T047 is the owner's (`docs/OWNER-REVIEW.md` §2 and §5); the builder's open items are small: (1) read the tour of run 35387497620 and get ui-reviewer's verdict on the two screens 8c83a74 moved (rule 13); (2) Q13 is owner-visible only, Q14 (swift-xref's one provable type rule) is the next unchecked ledger item; (3) the three debt lines opened today (journey ③ one-off, three tour shots, plus the older 2026-09-18 ones). The owner's design session works from `design/claude-design-brief/` and `design/INVENTORY.md`; `design/DESIGN.md`'s four owner sections and the inventory's "Screen job" lines are the owner's to fill — no UI redesign starts before a direction is picked. Local branch `wip/w3-crew-surface` (f8dbf22) is superseded by 3a2d744 and is the owner's to delete (`git branch -D wip/w3-crew-surface` — the agent's hook refuses branch deletion); `archive/a20-build-b` stays until A21.12 is ruled.
- 2026-09-18: W3 → W6 are on master and CI-GREEN (run 35302729856, first attempt; 148 unit + 12 UI tests on iOS). **TestFlight build 145 (6abd914) is UPLOADED** — the workflow archives unsigned and the export signs with the cloud-managed Distribution identity (run 35305232232), so the certificate cap is gone for good. Next: the owner installs 145 and does the ONE smoke test, then rules on appearance / launch wait / Build B / G1–G4 in one message. Builder's next work, each on an owner input: W3b (G1–G4 ruled, A22 ratified) · W7 (accounts: host, Associated Domains, Team ID in the AASA, APNs key, Blob store, Resend domain, Services ID) · W8 (addendum ratified, A16.b rating) · W9 (privacy/terms text, the store listing) · A21.12 Build B (rebuild-or-drop after the walkthrough). Nothing is built before those inputs. W3b (plate-journal removal) waits on G1–G4; W7 on the owner's accounts; W8 on the addendum's ratification; W9 on the privacy/terms text. W2's build 136 still waits on the certificate revocation. Build B stays on `archive/a20-build-b` until the W6 walkthrough decides rebuild-or-drop (A21.12). The nutrition addendum draft awaits ratification (W8).
- CI run 34351357853 (push 5374a2f, 2026-09-09 12:30Z): contracts ✓ · web ✓ · ios engine ✓ · ios ✗ with ONE diagnostic across the ~95 rewritten Swift files — `ShellStatesTests.swift:11: type 'PlanLoadState' has no member 'offline'` (the editor rewrite dropped the case); F23 restores it. The unit + UI test outcome is unknown until the next run. The web e2e job also failed on ONE check: the phone-375 a11y sweep measured 11 px of sideways scroll on a signed-in page under the Linux runner's fallback fonts (green here on Windows fonts). Reproduced locally by forcing a wide font: the Settings profile `<input type=file>` and the session exercise header (name · chip · Swap · Skip) overflowed; F23 makes the file input span the column and lets that header wrap, and the assertion now names the page.
- CI run 34354352786 (push 178c1b4 = F23, 2026-09-09 13:00Z): contracts ✓ · web ✓ · web e2e ✓ (the wide-font overflow fix held on the runner) · ios engine ✓ · ios ✗ — the whole app compiled, 89 unit tests ran, 3 assertions failed in TWO tests of `SyncDeliveryTests`, both test bugs: they enqueued at `Date()` (2026) and stepped the queue at `Date(timeIntervalSince1970: 1_000_000)` (1970), so the op was `.waiting`, never `.sent`; and `attachPhotoKey` re-serialised the payload with JSONSerialization, which escapes `/` as `/`, so `contains("blob/abc")` was false. F24: the tests share one clock; the re-serialisation (SyncDelivery, PostPayloadPhotoStripper) uses `.withoutEscapingSlashes`. The journeys did not run (the unit step failed first) — Q09 is still unread.
- The owner's ask after that run — "how can this be checked locally before it fails on GitHub?" — answered in F24 (docs/testing-without-a-mac.md Stage 0/1): (1) `node shared/scripts/swift-xref.mjs` — a compiler-free cross-reference check that reproduces every compile error the macOS job has ever reported (removed enum case, renamed parameter, removed struct field, shadowed SwiftUI type; a scratch copy with all four re-introduced reports all four; the real tree is clean) — first step of the `contracts` CI job and the command to run before every queue-and-push; (2) `expectNoHorizontalScroll` measures a second time under a wide fallback font (Verdana here, DejaVu Sans on the runner), so the e2e sweep on this machine sees what the runner sees — and names the overflowing element; its first full run caught a REAL one the runner would have found next: the crew header's name + pulse row pushed the pulse 9 px past a 375 edge in journeys ② and ③ (`CrewHeader.tsx` now wraps that row; journeys ② ③ 6/6 green on all viewports after the fix); (3) the `ios` job runs unit AND journeys even when unit fails and a `verdict` step writes both logs' error lines and suite totals to the run summary — one run, every failure. What no local check can do: run SwiftData/SwiftUI code — test logic against Foundation behaviour still meets the macOS job first.
- CI run 34360394481 (push = F24, 2026-09-09 13:55Z): contracts ✓ (swift-xref in the chain) · web ✓ · web e2e ✓ · ios engine ✓ · ios: unit **89 tests, 0 failures** (the SyncDeliveryTests fix held); journeys ran for the first time on the new screens — 3 of 5 green (Launch, CameraDenied, journey ②), journey ① and OfflineSessionTests (Q09) both failed at the same line: `app.buttons` matching "set 1 of" found nothing. Read from Windows without a Mac: the xcresult's `Data/` files are zstd (Node 22 opens them) and the failure's accessibility dump showed the session screen open with the row exposed as `Other` — an HStack with a tap gesture is not a button to XCUITest (nor to VoiceOver) — and the whole card 484 pt wide on a 402 pt window (Skip at x = 418, Complete 516 pt wide): the set row's fixed parts (label 64 + two 44-pt steppers + check) never fit an iPhone. Journey ① had passed on 2026-09-08 only because that was a Tuesday: its Mon/Wed/Fri plan took the meal branch. Q09's cause is the same row.
- F25: SetRow gains `.accessibilityAddTraits(.isButton)` and a `ViewThatFits` (one line where it fits, the steppers under the label on a phone — the twin of the web's `.setrow` flex-wrap), the stepper label's minimum width is a touch target instead of the ring diameter, exercise names wrap; journey ① now selects all seven days (deterministic: it always logs a set), and `JourneySteps.swift` holds the shared day-toggle step (third occurrence) plus `expectOnScreen` — the journeys measure that the set row, its Skip and Complete lie inside the window (the iOS twin of `expectNoHorizontalScroll`). WRITTEN — UNVERIFIED: swift-xref and doctrine-lint clean; the layout itself is the next run's verdict.
- CI run 34364030257 (push = F25, 2026-09-09 14:30Z): contracts ✓ · web ✓ · web e2e ✓ · ios engine ✓ · ios unit 89/0 · journeys 3/5 again, but two steps further: the set row is found as a Button, `expectOnScreen` passed for the row, Skip and Complete (the dump's frames: Skip at x = 345 of 402, the card 338 wide — the F25 layout holds), and the tap landed. What the tap did: the row's label went from "…, 10 reps" to "…, 10 reps, 0.0 lb" — XCUITest (and VoiceOver's activate) touch an element at its CENTRE, and the centre of the wrapped 96-pt row is the steppers line: the weight stepper's minus took the tap (weight nil → 0) and the set stayed unchecked; journey ① then hit Complete and got "Check off at least one set and this counts." (0/15 sets); the offline test never saw ", done".
- F26: the check button IS the row to assistive tech — it carries the whole "Machine Chest Press, set 1 of 3, 10 reps, 135 lb, done" label and the double-tap hint; the row container is `.accessibilityElement(children: .contain)`, so the steppers stay reachable as their own buttons, now named "Decrease reps" / "Increase weight" / "Decrease minutes" / "Increase sets" (`Stepper` gains `noun`; CardioRow, ExerciseSheet updated); the weight in the label reads as displayed ("0 lb", not "0.0 lb"); the row's whole-area tap gesture stays for fingers (Flow 3). The journeys' `firstSet` query now resolves to that 44-pt button, whose centre is unambiguous. WRITTEN — UNVERIFIED: swift-xref and doctrine-lint clean.
- CI run 34367618719 (push = F26, 2026-09-09 15:02Z): every job green but `ios`, and `ios` at ONE journey: unit 89/0; journeys **4 of 5** — journey ① passed END TO END for the first time on a simulator (fresh install → seven days → plan → save → Home bridge → set 1 checked → Complete → "+XP" celebration → Done → the bridge gone), plus journey ②, CameraDenied and Launch. OfflineSessionTests (Q09) got further than ever — set 1 checked and photographed — and failed after the kill: the relaunch woke on the HERO (the dump: "One plan. Every week…", Build my week, I have an invite, Log in), i.e. signed out. Cause: the CI job built the simulator app with `CODE_SIGNING_ALLOWED=NO`, so the app carried no entitlements, and on a simulator an app without entitlements cannot write the Keychain (errSecMissingEntitlement, -34018 — KeychainStore ignores SecItemAdd's status, C6); the session lived in memory only, so the kill lost it. Journeys ① ② never relaunch, which is why only Q09 ever saw it. A signed TestFlight build is unaffected.
- F27: the `ios` job signs simulator builds ad hoc (`CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO` — no certificate, no team, no profile; the entitlements are embedded, so the Keychain works) for both steps; OfflineSessionTests asserts Home ("Today") before the Resume banner and names the signed-out state in its message. WRITTEN — UNVERIFIED (workflow parses; swift-xref and doctrine-lint clean). If ad-hoc signing trips on the entitlements, the verdict will say so in one line.
- CI run 34371679615 (push = F27, 2026-09-09 15:40Z): the first ad-hoc-signed simulator build stopped in ten seconds, before compiling: `Cannot code sign because the target does not have an Info.plist file and one is not being generated automatically … (in target 'CrewTests')` — the test bundles had never needed a plist while nothing was signed. F28: `GENERATE_INFOPLIST_FILE: YES` on CrewTests and CrewUITests in project.yml (the app target already has Crew/Info.plist). The signing switch itself was accepted (`Using codesigning identity override: -`); the entitlements question is still the next run's first line.
- CI run 34373681818 (push = F28, 2026-09-09 16:05Z): the signed simulator build compiles and its unit suite is green (89/0) — signing with the entitlements works without a team. Journeys 2/5: journey ② (seeded session) and Launch pass; journey ①, CameraDenied and Offline all stop at "Save your plan": the dump shows the form still up, `At least 8 characters.` under the password and the SecureTextField holding ONE character (`value: •`); the dev server saw no register POST from the app (the unsigned run had five). Cause: a SIGNED app gets Password AutoFill, and a `.newPassword` field answers focus with iOS's Automatic Strong Password — the generated text replaces what XCUITest types, one character survives, validation blocks submit silently. The Keychain fix from F27 is what exposed it.
- F29: the signup password field is `.textContentType(.password)` (iOS still offers to save the pair and autofills it at login — S05 — the strong-password suggestion is deferred, docs/debt.md); the UI tests install a UI-interruption monitor (`dismissSystemPrompts`, JourneySteps.swift) that answers Save Password / permission prompts with the quiet button, since a signed build now shows them. WRITTEN — UNVERIFIED: swift-xref and doctrine-lint clean.
- **CI run 34377505665 (push = F29, 2026-09-09 16:30Z): EVERY JOB GREEN** — contracts (with swift-xref) · web · web e2e (23 passed, 1 skipped) · ios engine (Linux) · ios: 89 unit tests, 0 failures, and **all five journeys on an iPhone 17 simulator** — journey ① (install → seven days → plan → email save → bridge → set 1 → Complete → celebration → Done), journey ② (seeded member, quick complete, a crew-mate's reaction), CameraDenied (text-first meal post), Launch (no splash) and OfflineSessionTests (set 1 checked, the app killed, relaunched signed in, Resume banner, the checked set still there — **Q09 closed**). The signed simulator build is what made the last two possible. The A1–A8 rewrite is DONE-VERIFIED on both platforms.
- TestFlight build 3 UPLOADED from that commit: `gh workflow run testflight.yml -f build_number=3` → run 34379733146 (2026-09-09 16:55Z; archive, cloud signing and "Upload succeeded" at 16:58Z — App Store Connect numbers it itself, likely 0.1.0 (3)). The owner installs it from the TestFlight app (delete the old Crew first — the SwiftData schema changed with A1/A2 and there is no migration, docs/debt.md).
- 2026-09-09 evening: the owner installed build 3 and it CRASHES AT LAUNCH. Crash log requested (Settings → Privacy & Security → Analytics & Improvements → Analytics Data → Crew-….ips → Mail → C:	mpcrew-crash). Prime suspect without the log: build 3 over build 2's SwiftData store — the A1/A2 schema (plans, sets) cannot open the old file and Store.init hit `fatalError`. F31 (queued, not yet pushed): Store removes an unopenable store and starts over (the server re-hydrates), fatalError only if a fresh store also fails; debt line updated. The other two fatalErrors (Api URL from CREW_API_SCHEME/HOST, SeedCatalog decode) worked in build 2 and in the simulator journeys, so they are unlikely — the log decides.
- The owner pasted a crash report — for BUILD 2 (`"build_version":"2"`, 07:49 local, 37 min after launch), not build 3. Read: `EXC_BAD_ACCESS / SIGBUS KERN_PROTECTION_FAILURE` in `swift_retain` on a cooperative (async) thread inside Crew code with URLComponents/Date/URLRequest values in the registers (an Api call), while a second cooperative thread sat in `SecItemDelete` from Crew code (KeychainStore.write deletes before it adds — i.e. `AuthStore.store`). Two concurrent `validAccessToken()` refreshes (sync drain + Home refresh + crew poll) wrote AuthStore's Strings off the main thread while the main thread read them: a data race a Release build turns into a crash. F32: `AuthStore` is `@MainActor` (every model that reads it already is; Api awaits it; tests are @MainActor). swift-xref and doctrine-lint clean.
- Build 3's own crash log is still wanted: the right file says `"build_version":"3"` in its first line and a capture time after the build 3 install. F31 (the store) + F32 (the race) go up together; TestFlight build 4 follows the green run.
- CI run 34405436792 (F31 + F32 pushed): ONE compile error, and it is the shape of change that causes it — `HomeModel.swift:40: main actor-isolated property 'currentUser' can not be referenced from a nonisolated context`. A parameter's DEFAULT VALUE is evaluated in a nonisolated context even inside a @MainActor type, so `welcomeBackAckDay: String? = AuthStore.shared.currentUser?.welcomeBackAckDay` stopped compiling the moment AuthStore became @MainActor (F32). `Type = .shared` defaults are unaffected — a static let is only a warning today; it is the `.shared.property` READ that fails. F33: the default is `nil` and HomeScreen passes the account value (as ProgressScreen, SettingsScreen and CelebrationScreen already read units from the account); the tests already passed theirs explicitly, so nothing about E4's behaviour moved.
- F33 also teaches swift-xref the rule: it collects every `@MainActor` type and reports a parameter default that reads `<MainActorType>.shared.<property>`. Verified both ways — clean on the tree as fixed, and a scratch copy with the exact line back reports it at HomeModel.swift:42. That is the third class of macOS-only error the Windows check now catches (removed members, wrong labels, main-actor defaults).
- **CI run 34406449090 (push 99614c1 = F31 + F32 + F33): EVERY JOB GREEN again** — contracts · web · web e2e · ios engine · ios (89 unit tests + all five journeys) with AuthStore main-actor isolated and the store's self-repair in. TestFlight build 4 started from that commit: `gh workflow run testflight.yml -f build_number=4` → run 34407879045, "Upload succeeded" at 21:39Z. App Store Connect numbers it itself (build 2 uploaded as (1), so expect 0.1.0 (4) or the next free number).
- F34 (same audit, one word): `Api.baseURL` was a `var` on the shared nonisolated `Api` — read from every thread that calls the API, never reassigned. It is a `let` now, so the one remaining piece of shared mutable state outside an actor is gone. Nothing else in the app has any: Store, SyncQueue, AuthStore and every model are @MainActor; SeedCatalog is an immutable struct; the rest of the `var`s are DTO fields and computed properties.
- NEXT: the owner deletes Crew from the phone and installs build 4 from TestFlight. If it launches: the phone pass (rest-day Home, Plan map → editor → sheet, Crew, Journal, Settings) and the Stage 2 steps still owed — Blob store, APNs key, DB drop; Appendix A ratification; the ≤ 2-day question. If it still crashes: the newest `.ips` at that moment (`"build_version":"4"`) names the line.
- Plan notes (5.6 map / 5.2 tree additions, all logged in R-055): shared/scripts holds generate · check-drift · render-spec-constants · render-ember · render-seed · check-vectors · vector-shapes · vector-invariants · check-seeds · doctrine-lint; Generated/ gains EmberTokens.swift; Api/ gains JSONValue.swift, HttpStatus.swift, KeychainStore.swift and per-resource Api*.swift files (C9); Storage/ gains SyncDriver, ServerHydrate, PlanLocal, GamificationLocal, AchievementFacts, PostPayloadPhotoStripper, SyncTransport, ModelsSocial; ios/ gains Package.swift + ExportOptions.plist + scripts/doctrine-lint.sh; `.github/workflows/testflight.yml`; web gains `api/cron/notifications`, `photos` routes, `crews/[id]/{stream,mute}`, `vercel.json`, `scripts/metrics.mjs`, `/journal`, `/onboarding` outside the (app) group (pre-auth by design, Flow 1); web/AGENTS.md + web/CLAUDE.md are written by `next dev`.
- **CI run 34491587098 (push 2de1909 = R01 + R02 + S6, 2026-09-10 14:49Z): contracts ✓ · web ✓ · web e2e ✓ · ios engine ✓ · ios ✗ on ONE compile error** — `OnboardingModelAuth.swift:37: extra argument 'measurementSystem' in call` (Stage 1 added the label at the call site; `AuthStore.signInWithApple` reads `MeasurementSystemHint` itself). Neither iOS test layer ran, so the Stage 1–6 iOS surface is still unverified by Xcode. Two things made the red hard to read: the verdict step's own log said only "exit code 1" (its findings went to the summary page the owner did not open), and the two xcodebuild steps above it showed ✓ because they are `continue-on-error`. swift-xref had said "clean" — it label-checks `Type(...)` and `Type.f(...)` but stopped at `.shared` on an instance call.
- F35 (queued): the call site drops the label. swift-xref gains class 4 — `Type.shared.method(...)` label-checked like a static call; a scratch copy with the line restored reports `AuthStore.shared.signInWithApple(credential:timezone:eulaAccepted:birthYear:measurementSystem:) matches none of (credential:timezone:eulaAccepted:birthYear:)` at OnboardingModelAuth.swift:39, the real tree is clean (183 files, 367 types). The verdict is `ios/scripts/verdict.sh`: headline first in ITS OWN step log, the same text on the summary page, and one `::error file=…,line=…,col=…` annotation per distinct error (deduped across the two logs) — tested against this run's saved unit.log/ui.log (1 error each, first error named repo-relative, exit 1) and against the green path (exit 0). The xcodebuild steps carry names. `docs/testing-without-a-mac.md` step 3 rewritten to say "read the verdict step's log first". Nothing behavioural changed; the runner's next verdict is the real one.

## 2026-09-10 (evening) — A17, the third phone review: Home

The owner opened the shipped Home on the phone and said: *"I am looking at it and clearly don't know what to do next or what this screen is for or what the colors are for."* Three questions; the screen answered none. Contract: `docs/home-plan-2026-09-10.md`. Evidence: a 41-agent review across eight lenses with every finding adversarially verified against the source — **62 findings, 52 confirmed, 10 refuted** — plus outside research. Twenty owner decisions answered; four Decision Registry amendments authorised as **A17**.

**The root diagnosis:** four elements on Home (flame, ring, week strip, crew strip) each build a complete English sentence and render it ONLY to VoiceOver. Home explained itself to a screen reader and to nobody else.

**Three defects the review found that the owner had not reported, and which outrank what he did:**

1. **A paused plan could be un-paused into a full-credit workout.** The vector row rendered while paused, its Workout slot called `startWorkout()`, and `todayWorkout` came from a rotation projection that never consults the pause — so tapping a grey box started a session with `isPlannedDay: true` and paid **V25 +100** from a screen that says the streak is frozen. This is **F14 recurring verbatim**: the same pass had fixed it for Quick complete by gating on the STATE and the new row was written without the gate. Fixed at the model (`if isPaused { todayWorkout = nil }`), so every present and future reader is safe, with a regression test.
2. **Six of the seven status marks failed 6.5's 3:1 non-text gate** (missed 2.39:1, rest/upcoming 1.19:1, unlogged dot 1.26:1, crew dot 2.53:1, ember 2.77:1) — and the A14 pass had CERTIFIED them compliant by answering the wrong rule: it argued WCAG 1.4.1 ("the marks carry a shape as well as a colour") against a spec clause that states 1.4.11 (non-text contrast). There was no contrast test anywhere in the repo. There is now (`web/tests/contrast.test.ts`, 34 assertions, both modes), and it was PROVEN by restoring #FF6600 in a scratch copy: 5 failures, then restored.
3. **The web bottom anchor did nothing at all.** `.stack--page` asked for the viewport height with `min-height: 100%`, which resolves against the parent's height property — `auto` here — so `margin-top: auto` had no free space to consume and the day's primary sat at y=186 on a 667 px phone. It looked plausible, passed tsc, lint and every existing e2e assertion. **The first run of the new `home-layout.spec.ts` found it.**

**Shipped:** the stack reordered so the card and its filled primary land in the thumb zone (the first time 6.7's bottom-anchor clause is literally true on Home) · a `WeekSummary` twin producing "This week: Wed done · Mon missed · next Sun" for the eye and the full-day-name form for VoiceOver from ONE function · a per-state nav title · the streak stake folded into the existing rest-day line · the shield rendered for the first time (computed since day one, shown nowhere) · `ember` repaid #FF6600 → #DF5908 (2.77 → 3.56:1, hue h24 → h23) · the faint marks recoloured onto `secondaryText` · the crew posted-dot given the hollow ring spec:290 already called for · a fifth strip mark for the next training day only · the vector slots saying "Log" instead of "—" and wearing control chrome instead of card chrome · the card's duplicate Log cardio / Bonus workout pair removed (seven controls → five) · a crew of one suppressed on Home, as the Crew tab has always done · `WeeklyRing.days` finally deleted, the dead parameter F12 was about.

| Stage | Task IDs | State |
|---|---|---|
| A · the eleven defects | H001–H011 | **DONE** |
| B · A17 on paper | H012–H013 | **DONE** |
| C · colour and contrast | H014–H018 | **DONE** |
| D · layout | H019–H021 | **DONE** |
| E · words | H022–H027 | **DONE** |
| F · the vector row | H028–H030 | **DONE** |
| G · the week strip | H031–H032 | **DONE** |
| H · the crew strip | H033–H035 | **DONE** |
| I · coverage | H036, H038 | **DONE** — H037 (SE device in CI) NOT done, deliberately: D18 chose code assertions; logged in debt.md |

**Counts:** vectors **56 → 56** (A17 adds no vector and changes no engine rule, by design) · web **389 → 429** tests (41 files) · Swift **70 → 76** · e2e **23 → 29** passed (the two new Home layout assertions across all three viewports).

**NEXT: the owner's phone review (D20).** Stage 7 of the previous plan (A15, change today's workout) is **held** until Home is confirmed on the device — A15 routes "do a different day" to the same bonus list, which would become a fourth control for that destination if Home is not settled first.

---

## 2026-09-10 · CI — the ios job compiles the app once instead of twice, and the verdict can count

Run 34540455856 was red on **one line**. `Journey2_FastLogTests.swift:33` waited for `app.navigationBars["Today"]`, and A17.4 had just made Home's title name the state. Journey ②'s member trains every day and has already posted, so that screen is titled with the workout's name and can never say "Today" again. The other four journeys passed. `OfflineSessionTests.swift:62` asserts the same string and passed — correctly, but by luck of state: its member never posts, so Home is still the BRIDGE, the one state where "Today" survives. Both assertions now say in-comment which state they are in, because they look contradictory and are not.

Two things around the failure cost more than the failure did.

**The verdict could not tell a compile error from a failing test.** It reported `1 error(s) · 0 failing test(s)` — both numbers wrong — and printed a `Failing tests:` heading with nothing beneath it. One cause: xcodebuild prints an XCTest assertion in the compiler's own `file:line: error:` shape, so the assertion was counted as a compile error; and the failing-test count came from the trailing summary block, whose real format is `\tJourney2_FastLogTests.testReturningUserFastLogs…()` — no bundle prefix, a **digit** in the class name, a `.` separator — against a regex wanting `[A-Za-z]+Tests\.[A-Za-z_]+/test`, which matches none of those three things. Failing tests are now counted off `Test Case '-[…]' failed (`, which xcodebuild prints per failure and has not changed shape across Xcode versions, and the two kinds of finding are counted, headlined and annotated separately. Added rule: **a failed step whose log yields no finding at all prints its tail** — a simulator that never boots was previously a red step whose log said only `** TEST FAILED **`. All three paths were run against the real saved logs and against fixtures before pushing.

**The job compiled the 151-file app twice**, because two `xcodebuild test` invocations meant two schemes, and the `Crew` scheme carried `gatherCoverageData: true` while `CrewUITests` did not — different flags on the same target, so nothing could be reused. Coverage data was produced on every run and read by nothing: no `xccov`, no gate, no report.

> ⚠️ **The two lines below that read "92 s build" and "82 s build" are WRONG, and the pass built on them made the job 86% slower. They are left here because the next section is the correction and it only makes sense against them.** They were arrived at by subtracting test time from step time — which silently attributes the simulator's ~60 s preparation phase to the compiler. The real split is in the 23:35 entry.

| | before (run 34540455856) | after |
|---|---|---|
| setup · npm ci · dev server · warm-up · sim pick | 35 s serial | ~10 s (npm + next detached, overlapping the build) |
| unit step | **95 s** = ~~92 s build~~ + 3.1 s test | — |
| journeys step | **231 s** = ~~82 s build~~ + 149 s test | — |
| build (once, both bundles, no coverage) | — | ~95 s |
| unit (`test-without-building`) | — | ~10 s |
| journeys (`test-without-building`) | — | ~155 s |
| **job** | **6m 11 s** | ~~**~4¾ min expected**~~ → **11m 31 s actual** |

**Shipped:** a CI-only `CrewAll` scheme carrying both test bundles, so one `build-for-testing` feeds two `test-without-building` runs and the unit/journeys split survives as `-only-testing:` · `gatherCoverageData` dropped · `npm ci` + the dev server detached so they come up during the build, with the wait moved after it and made to print `dev-server.log` instead of timing out mute · the unit suite reordered ahead of the harness wait, since 127 tests against bundled vectors need no server · `verdict.sh` taking three outcomes and three logs · the two `navigationBars["Today"]` assertions corrected and explained. `-scheme Crew` and `-scheme CrewUITests` are untouched: `CrewAll` exists only so CI pays for the app once.

**Verified locally before the push:** `check-drift` · `check-vectors` (56) · `check-seeds` · `doctrine-lint` (185 Swift files) · `swift-xref` (185 files, 371 types) · `ios/scripts/doctrine-lint.sh` · docker `swift test` **76** · web `npm test` **429** (41 files) · `tsc --noEmit` · `eslint` — all clean. `verdict.sh` run against run 34540455856's real `unit.log` and `ui.log` (now: `0 compile error(s) · 1 failing test(s)`, first failing assertion named, annotation at `Journey2_FastLogTests.swift:33`, exit 1) and against fixtures for the compile-error and unbootable-simulator paths. Web e2e not re-run: no web source changed in this pass.

**NEXT:** the runner is the only oracle for `build-for-testing`/`test-without-building` — push and read the verdict. The owner's phone review of Home (D20) and the held Stage 7 (A15) are unchanged by this pass.

---

## 2026-09-10 · CI — the correction: the duplicate compile was ~21 s, the duplicate SIMULATOR PREPARATION was ~60 s, and splitting the build made both worse

Run 34542854485 took the pass above to the runner and came back **86% slower: 6m11s → 11m31s**, red on `CameraDeniedTests.swift:32`. Both halves of that are the same mistake.

**The measurement was wrong.** "92 s build + 82 s build" came from subtracting test time from step time. But an `xcodebuild test` step is three things, not two — compile, then the simulator's preparation (boot, install, automation session), then the tests — and xcodebuild reports the middle one itself, as `IDETestOperationsObserverDebug: N elapsed` around the test phase. Reading that counter in both runs gives the real split:

| | 2× `xcodebuild test` (34540455856) | `build-for-testing` + 2× `test-without-building` (34542854485) |
|---|---|---|
| compiling | 30.3 s + 20.8 s = **51 s** | **46 s** |
| simulator preparation | 60.5 s + 61.2 s = **122 s** | 149.5 s + 189.4 s = **339 s** |
| tests | 4.2 s + 149 s = **153 s** | 7.5 s + 218.5 s = **226 s** |
| **job** | **6m 11 s** | **11m 31 s** |

So the duplicate compile was worth ~21 s, not 82 s. The expensive duplicate was the **simulator preparation** — and separating the build did not remove it. It made each preparation ~3× slower and still paid it twice, because `test-without-building` has no build phase to run alongside it. The ubuntu jobs moved <10% between the two runs, so this is the change, not the runner.

**The red followed from the same slowdown.** With the machine 47% slower, CameraDenied's `waitForExistence(timeout: 2)` for "Your week, built." expired on a run where synthesizing one tap took 10 s. That wait was always a coin flip — it is a 2-second budget for a screen transition on a shared runner — and this is precisely the failure mode `debt.md` predicted for parallel UI testing hours earlier. The old ordering had been landing it heads.

**Shipped:** `ci.yml` back to ONE `xcodebuild test`, but on the `CrewAll` scheme, which is the only shape that pays for the compile once AND the simulator preparation once (the old two-scheme job paid both twice; the split paid preparation twice and worse). `-only-testing:`, `-derivedDataPath` and the detached harness are gone with it — the harness is serial again, keeping only its new failure message, which prints `dev-server.log` instead of timing out mute. **Sixteen positive `waitForExistence` timeouts raised 2–3 s → 15 s**; a positive wait returns the instant the element appears, so this costs a fast run nothing. The three NEGATIVE waits and the `share || done` either/or stay tight, because those burn their whole timeout on success — the rule is written at the top of `JourneySteps.swift`. `verdict.sh` reads the one `test.log`. Expected ~5 min, but the runner is the oracle and the estimate above was wrong once already.

**Kept from the previous pass, both proven on the runner:** the `CrewAll` scheme (built and ran both bundles correctly), the Journey ② / OfflineSession title assertions (both passed), and the verdict's compile-error-vs-failing-test split, which reported this run as `0 compile error(s) · 1 failing test(s)` with the first failing assertion named and a clickable annotation — the thing it got wrong the run before.

**Verified locally:** `check-drift` · `doctrine-lint` (185 files) · `swift-xref` (371 types) · `ios/scripts/doctrine-lint.sh` · `bash -n verdict.sh` · both YAML files parse · brace balance on all five UI test files · `verdict.sh` against a `test.log` built by concatenating this run's real build+unit+ui logs (`0 compile error(s) · 1 failing test(s)`, annotation at `CameraDeniedTests.swift:32`, exit 1), against the green path (exit 0), and against an unbootable-simulator log (prints the tail, exit 1).

---

## 2026-09-10 · CI GREEN (run 34544705389, commit 91c9604) — and the speed work netted approximately nothing

All five jobs green, including the five iPhone journeys. The two test fixes and the verdict fix are proven on the runner. The speed work is not, and this entry says so plainly so the next session does not re-litigate it.

**Three measured runs**, from xcodebuild's own `IDETestOperationsObserverDebug` counter rather than from subtraction:

| shape | compiling | simulator prep | tests | job | run |
|---|---|---|---|---|---|
| 2× `xcodebuild test` (baseline) | 30.3 + 20.8 | 60.5 + 61.2 | 153 s | **6m 11 s** | 34540455856 |
| `build-for-testing` + 2× `test-without-building` | 46 | 149.5 + 189.4 | 226 s | **11m 31 s** | 34542854485 |
| 1× `xcodebuild test` (now) | 38.2 | 169.6 | 188 s | **7m 34 s** | 34544705389 ✅ |

**The honest reading of row 3: one invocation saves ONE COMPILE, ~13–21 s, and nothing else.** It does NOT prepare the simulator once — I assumed that too, and the counter says preparation still contains two install cycles (the host app for `CrewTests`, then the UI runner app for `CrewUITests`), which no scheme arrangement can merge. The remaining spread between 6m11s and 7m34s is macOS runner variance: the four ubuntu jobs moved <15% across all three runs while the macOS job moved 83 s, and ±60 s swamps a 20 s saving. **The current shape is kept because it is the simplest thing that is not wasteful, not because it is measurably faster.**

**The raised timeouts earned their place.** CameraDenied went 44.0 s → **72.2 s and PASSED**; at its old 2-second waits it would have gone red again on this runner. A positive `waitForExistence` returns the instant the element appears, so the 15 s ceiling costs a fast run nothing and converted a red into a slower green. Journey ① 35.2 s, Journey ② 22.9 s, Launch 7.4 s, OfflineSession 43.1 s.

**Where the time actually is, for whoever picks this up:** the journeys are **181 s of the 396 s step**, and simulator preparation is another 170 s. Compiling is 38 s — it is not the problem and never was. The one lever left with a clear mechanism is the `debt.md` entry on `OfflineSessionTests` and `CameraDeniedTests` re-driving the whole onboarding flow through the UI purely as setup (~20 s each), which Journey ① already covers as its subject; it is the owner's call because it weakens what OfflineSession proves about the Keychain. **Do not attempt another CI-shape optimisation without reading the counter across three runs** — two attempts from one run's numbers produced one 86% regression and one no-op.

**NEXT:** unchanged by all of this — the owner's phone review of Home (D20), with Stage 7 (A15) held behind it.

---

## 2026-09-11 · TestFlight builds itself now — a green CI run had never shipped anything

The owner asked why the app on their phone had not changed. It had not changed because **nothing connected `ci.yml` to `testflight.yml`**: TestFlight was `workflow_dispatch` only, so a build happened when, and only when, somebody clicked "Run workflow". The last upload was commit `4ef2096` at 21:12 on 2026-09-10 — **before A17 landed**. The whole Home redesign, and both CI passes after it, had gone green on master and reached no phone. Four commits deep, and the only symptom was the app looking the same.

**Shipped:** `testflight.yml` gains a `workflow_run` trigger on `ci` completion, gated to `conclusion == 'success' && head_branch == 'master'` — `workflow_run` fires on every completion including failures and pull-request runs, so the gate is the whole safety. Three things that are easy to get wrong and are now right:

- **It checks out the triggering commit, not the branch tip.** A `workflow_run` job defaults to the default branch's HEAD, which would silently ship whatever landed while the build was queued. `ref: github.event.workflow_run.head_sha` makes the TestFlight build the code that actually went green.
- **The build number is `git rev-list --count HEAD`** (116 next), not a human-supplied input. App Store Connect rejects any number not higher than the last upload for the same version string; the commit count only ever goes up. `fetch-depth: 0`, because a depth-1 clone reports the count as 1.
- **`concurrency: { group: testflight, cancel-in-progress: true }`** so two quick pushes cannot race two uploads. Latest commit wins, which is the point of the whole thing.

`workflow_dispatch` survives with `build_number` now optional — blank uses the commit count, a value forces one. A final step writes the build number, the commit and **"App Store Connect now PROCESSES it, which takes a few minutes; until that finishes TestFlight still shows the previous build"** to the job summary, because that delay is the other half of "why don't I see the update yet".

**The cost, stated plainly:** every commit that lands on master now spends ~7 min of macOS CI plus ~5 min of macOS archive-and-upload, both at the 10× minutes multiplier — documentation-only commits included. That is the price of never having to remember, and it is the owner's to revisit. `workflow_run` cannot filter by path, so skipping docs commits would need a job-level diff check; not built, because the ask was "I always want to see the update".

**NEXT:** the first automatic build is the proof — it should appear as build 116 under version 0.1.0. Then the owner's phone review of Home (D20), with Stage 7 (A15) held behind it.
