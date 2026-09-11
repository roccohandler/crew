# Crew build progress

Updated: 2026-09-11 (A18 complete and tested; A19 RATIFIED and Stages A/B/D landed) — earlier: 2026-09-10 night (A18 — the fourth Home review)
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

**NEXT:** A15 (Stage 7, "change today's workout") per the ratified ordering — after the CI run that compiles A18 + A19
Stages A/B/D, so Home's bar adoption and the editor's R11 can follow on proven ground.

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
- [ ] Q12 SERVER: `DELETE users/me` reports a completed cascade as a failure when the "account deleted" email cannot be sent — seen on production 2026-09-08 22:10Z: the smoke account was gone (`users/me` → 404) but the response was 500, because `lib/account-delete.ts` awaits `sendAccountDeletedEmail` after the irreversible cascade and Resend's sandbox sender refuses any address but the account owner's. Fix: the email is best-effort after the cascade (try/catch + one log line; the response stays 200 with the cascade done — E9 promises the confirmation "states the cascade is done", not that the deletion waits on it); test: `account.test.ts` with a throwing transport (`RESEND_API_KEY` set to a junk key makes `deliver` throw) expects 200 and the cascade. Verify: `npm test tests/api/account`. [SPEC: E9; 8.2 Account; Part IV email touchpoints] [SPEC: XI T046; OWNER-REVIEW §5 step 6]

## Blockers

- OPERATING MODE (Appendix A, 2026-09-04): CONTINUOUS BUILD — no 🛑 stops the line; former checkpoints are self-reviews in docs/ratification.md; gaps get the most conservative in-spec call tagged `// GAP:`; iOS is WRITTEN-UNVERIFIED (no Xcode here; GitHub's macOS job is the compiler); no real credentials in the repo or the chat.
- BLOCKED-CREDENTIALS (owner steps, docs/testing-without-a-mac.md Stage 2): the Atlas password (production `MONGODB_URI` fails with "bad auth" — the owner is regenerating the `crew` user's password and replacing the variable; the Blob store `crew-photos` is still not connected) (T046) · the APNs key → Vercel (T033; the Team ID and bundle id are known) · a Services ID for web Sign in with Apple (T012) · an iPhone for the device pass (T028/T035/T043).
- ⏳ STAGE 9 ENTRY GATE (A16.b, owner task): the App Store Connect age questionnaire is re-answered with A16 in mind and the resulting rating is recorded in the 2026-09-10 section above. Stage 9 does not start until then. Open alongside it: the A16.c birth-year GAP (absent birth year reads as under 18 unless the owner rules otherwise).
- ⏳ STAGE 8 SHIP GATE (A13, owner task): lawyer confirmation on CC BY-SA 4.0 assets inside a FairPlay-protected binary. Vendoring, the hash test and the attribution screen may be prepared behind a feature flag; nothing reaches TestFlight until it clears.
- OPEN OWNER DECISION (non-blocking): Firebase Auth ⏳ (Appendix B) — custom auth proceeds by default (12.5); nothing built against Firebase.
- Git is hook-blocked for the agent: commits are queued in `docs/commit-queue.sh` (FIX QUEUE section); the owner runs `& "C:\Program Files\Git\bin\bash.exe" C:/Users/princ/CREW_2.0/docs/commit-queue.sh` then `git push`.

## Notes for next session

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
