# Handoff prompt — merge the A18 Home pass with the A19 app-wide ergonomics audit, then implement

> **How to use this file.** Paste everything below the line into a fresh Claude Code session in `C:\Users\princ\CREW_2.0`.
> It is self-contained: it assumes zero chat history, names every document it depends on, and states what is already done.
> It is written to be executed, not discussed.

---

## Who you are and what you are doing

You are Claude Code working the Crew repo under `CLAUDE.md` and `docs/crew-mvp-spec.md` Appendix C. Re-read
**Appendix A (Decision Registry) + Appendix C + `docs/progress.md`** before your first edit — that is rule 1 and rule 11 and it
is not optional.

Two UX passes exist and must now be merged into one ordered piece of work:

| Pass | Scope | Contract | State |
|---|---|---|---|
| **A18** | Home screen only, both engines | `docs/home-plan-a18-2026-09-10.md` + spec Appendix A A18.1–A18.13 | **RATIFIED. Implementation landed (J001–J021). Tests and close-out NOT done.** |
| **A19** | App-wide interaction ergonomics, iOS-led | `docs/ios-ux-audit-2026-09-10.md` | **DRAFT. Not ratified. Nothing implemented except the three items listed under "Already done" below.** |

Your job: finish A18's open tail, then land A19 in the order given, without reopening a single ratified A18 decision.

---

## Non-negotiable ground rules (from CLAUDE.md + Appendix C)

1. **Concrete by law.** No protocol with one implementation, no generic, no repository/DI/use-case layer, no mock, no middleware,
   no barrel file. Extraction only on the **third** occurrence, and only into a plain function or a small concrete view/modifier.
   A19 creates exactly **one** new modifier and **one** rename. If you find yourself designing a "design system", stop.
2. **Every number comes from `shared/spec-constants.json` / `shared/design-tokens.json` via the `Generated/` files.** Never type a
   spec number inline. Never hand-edit anything under `Generated/` — run `node shared/scripts/generate.mjs`.
3. **Every function implementing a spec rule carries a `// SPEC:` tag.**
4. **Vectors are append-only.** A18 added none and ruled that it needed none. A19 needs none **except possibly R4** (see below).
   If you think you need a new vector, you have probably drifted outside the amendment — stop and say so.
5. **Work one feature folder at a time.** Before coding each item, state: *files touched → tests added → vectors/criteria affected.*
6. **Record every compromise in `docs/debt.md` in the same commit that creates it.**
7. **Undefined behaviour → STOP** and emit `SPECIFICATION GAP: [description]`. Never guess through a gap.
8. **Web parity (6.8).** A19 items R2, R3, R4, R7 and R13 have web twins. They move together or the parity snapshot breaks.
9. Commits are task-sized: `feat(scope): description [SPEC: tag]`.

---

## Verify commands (nothing is "done" until its command has been RUN and its output shown)

```
web:   cd web && npm run typecheck && npm run lint && npm test && npm run vectors && npm run e2e && npm run build
ios:   docker run --rm -v "C:\Users\princ\CREW_2.0:/repo" -w /repo/ios swift:5.10 swift test     # engine + vectors on Linux
shared: node shared/scripts/generate.mjs && node shared/scripts/check-drift.mjs
        node shared/scripts/check-vectors.mjs && node shared/scripts/check-seeds.mjs
        node shared/scripts/doctrine-lint.mjs
xref:   ios/scripts/swift-xref.mjs        # catches call-shape breaks; there is no Xcode on this machine
```

**There is no Mac and no Xcode here.** Every Swift UI change is `WRITTEN-UNVERIFIED` until the GitHub macOS job compiles it.
Run `swift-xref` and `doctrine-lint` locally before every push — the owner has said explicitly that local checks run before a
queue+push, and that no agent pushes to the remote without a yes.

---

## PART 1 — Finish A18's open tail (do this first; it is already ratified)

A18's implementation is on disk and uncommitted. Its **test and close-out tasks were never done**. From
`docs/home-plan-a18-2026-09-10.md`'s ledger, these remain open:

- [ ] **J028** `web/tests/api/today-state.test.ts` — real Mongo, real handlers: the five states, the ring counts, the pause guard.
      `today-state.ts` currently has **zero** unit tests.
- [ ] **J029** iOS: extend `HomeModelTests` / `HomeVectorSlotsTests` to the new facts (`nextUp`, `todaySummaryLines`, `endPause`,
      `offline`, pause-aware `weekMarks`); add a UI assertion on the screen the owner actually photographed.
- [ ] **J032** `home-layout.spec.ts` parameterised over **375×667, 393×852 and 440×956** with the gap threshold. Today the only
      layout gate runs at the one viewport where the defect does not occur.
- [ ] **J033** `a11y.spec.ts` audits a **non-bridge** Home — it has only ever seen the bridge.
- [ ] **J034** iOS CI captures rest / workout / all-done / paused as run artifacts.
- [ ] **J035** `ShellStatesTests` asserts **reachability** of the five states, not the length of a literal array.
- [ ] **J036** `docs/progress.md` updated with an A18 section; every verify command run and its output recorded.

**`docs/progress.md` currently contains no A18 section at all.** That is the single most important gap: a new session reading
progress.md today would not know A18 exists. Fix that in J036 and make it truthful about what is WRITTEN-UNVERIFIED.

Do not restructure A18's Home code while doing this. Its decisions are ratified; you are adding the tests that prove them.

---

## PART 2 — The A19 merge context (read before touching anything)

### How the two passes relate

**A18 is Home-only and content-additive. A19 is app-wide and mechanism-focused. A18 makes A19's first item more urgent.**

A18 added height to Home on every state — two numeral captions (A18.1), a `NextUpBlock` above the card (A18.3), three
full-width verb rows replacing the shorter three-across row (A18.5), a control on the paused card (A18.6c), summary lines on
all-done (A18.9), and an offline banner that now genuinely renders (A18.12).

Home's bottom anchor is `Spacer(minLength: 0)` inside a `ScrollView` with `.frame(minHeight: proxy.size.height)`
(`ios/Crew/Features/Home/HomeScreen.swift`). **A `Spacer` inside scrolling content collapses to zero the instant content
exceeds the viewport.** So A17.2's guarantee — "the day's single ink-filled primary sits in the thumb zone on every state" — is
true only while Home fits, and every element A18 added brings the collapse closer, on more devices and more states. On an
iPhone SE (375×667) at accessibility-XXL it is already false.

**A19-R1 is therefore the natural successor to A18, not a competitor to it.** It does not move anything A18 placed; it replaces
the *mechanism* that holds the placement.

### What A18 already settled that A19 must not reopen

- **The Home toolbar camera** — A18.10 dropped it wherever the card already offers a meal CTA. A19's audit listed this as an
  open owner question; it is **closed**. Do not re-litigate.
- **`controlOutline`** (A18.11, `#938C83` light / `#726A61` dark) is now the token every outline control draws through.
  `SecondaryButton` already uses it (`ios/Crew/Shared/PrimaryButton.swift:45`). **Every new A19 control must use
  `EmberColors.controlOutline`, never `hairline`, never `secondaryButtonOutline`.** `hairline` keeps `#E9E4DD` for card edges
  and dividers only — a boundary between two surfaces is not a component.
- **`VectorRow`** is now three full-width verb rows (A18.5), not three equal-width cells. Where the A19 audit says "VectorRow",
  read A18.5's shape.
- **Home's stack order** is governed by A17.2 + A18.3. A19 governs only anchoring.
- A18 added **no vector**, and V57 is still the next free id (V57–V64 stay reserved for A16/nutrition).

### Files the A18 pass touched — treat as settled, extend only with care

```
ios:  Features/Home/{HomeScreen,HomeModel,HomeModel+Facts,HomeModel+Edges,HomeHeader,EdgePrompts,
                     TodayCard,VectorRow,WeekStrip,NextUpLine}.swift
      Shared/{PrimaryButton,WeeklyRing}.swift · Storage/{Store,SyncQueue}.swift
      Features/Settings/SettingsModel.swift · Generated/EmberColors.swift
web:  app/(app)/home/{page.tsx,TodayCard.tsx,HomeHeader.tsx} · components/{StreakFlame,VectorRow,WeekStrip,EndPauseButton}.tsx
      lib/{today-state,geometry,home-facts}.ts · app.css · generated/ember.css · tests/contrast.test.ts
shared: design-tokens.json
docs: crew-mvp-spec.md (Appendix A A18 + Part VII S07 + Part III) · debt.md · home-plan-a18-2026-09-10.md
```

---

## PART 3 — Already done (do not redo)

Three A19 items were implemented ahead of this handoff, deliberately chosen to sit **entirely outside A18's blast radius**:

- **R3 — Sign in with Apple no longer swallows failure.** `LoginScreen.swift` and `SaveAuthScreen.swift` gained a
  `case .failure` branch; `OnboardingModelAuth` gained the error→line mapping.
- **R6 — VoiceOver can react to a post.** `PostCard.swift`'s `.accessibilityElement(children: .combine)` replaced with explicit
  accessibility actions.
- **R7 (partial) — `SetCountButton` renamed `TextActionButton`** and adopted at the sub-44pt sites outside Home.

Check `git status` and `git diff` before assuming any of the above is or is not present.

---

## PART 4 — The A19 implementation order

Full reasoning, per-item rationale, file lists, test requirements, a11y notes and regression risk are in
**`docs/ios-ux-audit-2026-09-10.md`** (Phase 10 roadmap + Phase 11 plan). That document is the contract. Summary of the order:

### Gate first — this is paperwork, not code

**A19 IS NOT RATIFIED.** Before writing implementation code beyond Part 3, the owner must:

1. Ratify `docs/ios-ux-audit-2026-09-10.md` as Appendix A entry **A19**.
2. Rule on **R4's shape** — the celebration's "Share to crew" toggle is currently inert: the post is queued with
   `shareToCrew: true` hardcoded at `SessionScreen.swift:56` and `HomeScreen.swift` (quick complete) *before* the celebration
   renders, so flipping the toggle off still shares the workout, and the button label misstates what it does. Two honest shapes:
   **(a)** carry the real choice into completion so the toggle acts on this post, or **(b)** drop the toggle and make the
   celebration two buttons — primary "Share to crew", text "Keep it private". **(b) is simpler and removes a control.**
   *If (a), visibility becomes a completion input — that is a behaviour change and needs its own registry clause and quite
   possibly a new append-only vector.*
3. Rule on **Journal's placement** (currently a top-right toolbar button inside Progress — a first-class S16 screen reached
   through another screen's toolbar).

If the owner has not ruled, **stop after Part 1 and report**. Do not guess through the gate.

### Stage A — the mechanism (unblocks six items)

- **R1** Build `Shared/BottomBar.swift` — a small `.crewBottomBar { }` `ViewModifier` wrapping
  `safeAreaInset(edge: .bottom)`, using `EmberColors.controlOutline` for its top edge and `@ScaledMetric` for its metrics.
  This is the **third-occurrence-and-beyond** extraction the doctrine permits: eight live call sites, each currently hand-rolling
  a different wrong version (`Spacer`, `VStack` sibling, `overlay` + hand-computed padding at `PlanScreen.swift:66` and
  `WorkoutEditorScreen.swift:99`).
- Adopt on **`GeneratedPlanScreen` first** — the lowest-risk of the six, outside journeys ①②. Verify, then roll to
  `NutritionPostScreen`, `CardioLogScreen`, `SessionScreen`, `WorkoutEditorScreen`, and **Home last** (Home is the highest-risk
  and the most recently changed; let A18's tests land first).
- The bar is **conditional**: absent on states with no primary. A18.9 gave all-done no button and A17.3 ruled that a day asking
  nothing carries no filled primary. A permanent chrome strip that manufactures an ask is a regression, not a feature.
- **R7 (finish)** any remaining sub-44pt sites, now including anything A18.5's new rows introduced.

### Stage B — the dead ends

- **R2** CTA above the keyboard (falls out of R1) + `ToolbarItemGroup(placement: .keyboard)` Done on every `.numberPad` /
  `.decimalPad`. Those keyboards ship **no return key**, so today the user can reach a state with no way to dismiss them:
  `CardioLogScreen` (distance) and `SaveAuthScreen` (birth year).
- Web twins for anything in Part 3 that has one.

### Stage C — the share decision (R4) — blocked on the owner's ruling above

### Stage D — cheap ergonomic wins, all visual, very low risk

- **R9** Move `Spacer()` **above** the options in `SingleSelectQuestion` (`PlanQuestionsScreen.swift`) and above `Save` in
  `EditProfileScreen`. Two-line changes with the highest ergonomic return in the document: today the only action on the
  experience/equipment questions sits in the hardest-to-reach third of a Pro Max with ~400pt of dead space beneath it. This is
  *exactly* the defect A17.2 fixed on Home and never applied anywhere else.
- **R10** Wrap `IntroScreen` and the question screens in `ScrollView` as an XXL overflow valve (6.7 non-negotiable).
- **R5** Move "Discard workout" out of the session's scroll tail — it currently sits immediately above the Complete primary,
  violating 6.3 at the exact moment the user reaches for Complete.

### Stage E — core-loop feel (changes flows; needs journey coverage)

- **R8** `ScrollViewReader` + `scrollTo(focusIndex)` on `advanceFocus` — the session currently never scrolls to the exercise you
  are on.
- **R11** Workout editor: Save/Cancel out of the top-right nav bar; restore the interactive back-swipe that
  `navigationBarBackButtonHidden(true)` kills.
- **R12** Tappable reaction chips; move Report/Block out of the reaction sheet (destructive beside the most common action).
- **R13** Account deletion: replace the inline expansion (confirm appears under the finger that just tapped) with
  `confirmationDialog(role: .destructive)`, keeping the two-step and the "can't be undone" sentence.

### Stage F — P2/P3

R14 `.refreshable` on the crew stream · R15 `TabView` selection binding (needed before deep links) · R16 separate "Rebuild my
week" from "Change days" · R17 toasts to `safeAreaInset` · R18 `.sensoryFeedback` for the 6.2 haptic budget · R19–R23 polish.

---

## PART 5 — Ordering against the Part XI ledger

`docs/progress.md` says **Stage 7 (A15, "change today's workout")** is the next unchecked task. A17.3's forward note says
*"A15 does not ship until Home is settled."*

A18 settled Home's **content**. A19-R1 settles Home's **anchoring**, and A18's additions are what make that anchoring fail. So
the defensible order is:

> **A18 tail (Part 1) → A19 Stage A → A19 Stages B/D → A15 → A19 Stages C/E/F**

Put that ordering to the owner rather than assuming it. It is a scheduling decision, not a technical one.

---

## PART 6 — Definition of done for every item

Per Appendix C: the screen's **Part VII acceptance criteria** pass + **Part VI** standards hold + relevant **Part VIII** tests
green + `npm run vectors` **and** the Swift engine both green + doctrine lint clean. The happy path rendering is not done.

For A19 specifically, add one gate that does not exist today and is the whole point of R1:

> **Every screen carrying a primary action must be asserted hittable at accessibility-XXL on a 375×667 viewport.**
> That is the device/type combination spec 6.7 names as a non-negotiable, and it is the assertion that would have caught
> both the collapsing `Spacer` and the keyboard-covered CTAs. Extend `home-layout.spec.ts` (J032) for web and the
> `Screenshots` sweep for iOS.

Close every session by updating `docs/progress.md` with real command output. A future session with zero chat history must be
able to pick this up and lose nothing.
