# Crew iOS — one-handed UX audit and improvement specification

**Date:** 2026-09-10 · **Status:** DRAFT — NOT RATIFIED, NOTHING IMPLEMENTED · **Scope:** the iPhone app (`ios/Crew`), 188 Swift files

**Contract position:** this document proposes a Decision Registry entry (provisionally **A19**). Under Appendix C nothing here
may be built until the owner ratifies it, and under CLAUDE.md rule 12 it does not jump the Part XI queue — Stage 7 (A15) is
still the next unchecked work.

**Method:** every screen file under `ios/Crew/Features` read in full; every claim below carries a `file:line`. Claims that need
a device or simulator to confirm are marked **[verify]** and are never counted as defects. Apple guidance and UX research were
re-checked online today (sources at the end), not recalled.

---

## Reconciliation with A18 (added after the audit, same day)

This audit was written while a parallel session was landing **A18** — the owner-ratified fourth Home review
(`docs/home-plan-a18-2026-09-10.md`, spec Appendix A A18.1–A18.13). The two passes do not collide: **A18 is Home-only and
content-additive; this audit is app-wide and mechanism-focused.** Three consequences, all of which strengthen rather than weaken
what follows:

1. **A18 makes R1 more urgent, not less.** A18 adds height to Home on every state: two numeral captions (A18.1), a `NextUpBlock`
   above the card (A18.3), three full-width verb rows in place of the shorter three-across row (A18.5), a control on the paused
   card (A18.6c), summary lines on all-done (A18.9), and an offline banner that now genuinely renders (A18.12). Home's
   `Spacer(minLength: 0)` anchor (`HomeScreen.swift:87`) collapses when content exceeds the viewport — so every element A18 adds
   brings that collapse closer on more devices and more states. **R1 is the natural successor to A18, not a competitor to it.**
2. **Two of this audit's open questions are now answered by A18 and are struck.** The Home toolbar camera is resolved by
   **A18.10** (dropped wherever the card already offers a meal CTA) — that item is closed, not pending. And `controlOutline`
   (**A18.11**, `#938C83` light / `#726A61` dark) is now the token every outline control draws through, which is the token the
   proposed `.crewBottomBar` and `TextActionButton` must use; the audit's original note about the 1.26:1 hairline is repaid.
3. **A18's ratified content is not reopened anywhere below.** Where this document names `VectorRow`, read A18.5's full-width verb
   rows. Where it names Home's stack order, A17.2/A18.3 govern the order and this audit governs only the *anchoring mechanism*.

**Numbering:** this document was drafted as "A18" before that number was taken. It is renumbered **A19** throughout.

## Executive summary

The app is in better ergonomic shape than a first look suggests. A17 (2026-09-10) already moved Home's flexible space above the
day's card so the primary lands in the thumb zone, `SetCountButton` already fixes touch targets the correct way, `@ScaledMetric`
grows targets with Dynamic Type across the session screen, and every gesture in the session already has a button equivalent.
This audit does not re-argue any of that.

What it found instead is that **the fixes were applied one screen at a time and never generalised**, and that the app is missing
the one SwiftUI API that makes bottom-anchored primaries actually hold.

Six findings outrank everything else:

1. **No screen in the app uses `safeAreaInset`.** Zero occurrences (`bottomBar` zero as well). Every "bottom-anchored" primary is
   either a `Spacer` inside scrolling content — which collapses the moment content exceeds the screen — or a hand-built `VStack`
   sibling. The consequence is that A17.2's guarantee ("the day's primary sits in the thumb zone on every state") is true only
   while Home's content fits, and is **false on an SE at accessibility XXL**, which is the exact device/type combination spec 6.7
   names as a non-negotiable.

2. **The keyboard covers the primary action on three screens, and on two of them it cannot be dismissed.**
   `NutritionPostScreen` ("Post" below the caption field), `CardioLogScreen` ("Log {activity}" below a `.decimalPad` field), and
   `SaveAuthScreen` ("Save your plan" below a `.numberPad` field). `.decimalPad` and `.numberPad` have no return key and the app
   adds no keyboard toolbar anywhere, so on the cardio and signup screens the user can reach a state where the CTA is behind a
   keyboard they have no button to close. This is a direct 6.7 violation ("keyboard never covers the focused field or the
   primary action").

3. **Sign in with Apple silently swallows every failure.** `LoginScreen.swift:20-24` and `SaveAuthScreen.swift:25-29` both handle
   only `case .success`. There is no `.failure` branch, no error line, no retry. Apple returns `.canceled` both when the user
   cancels *and* when the device has no credential to offer — so a user in the second case taps the button and **nothing happens,
   forever, with no explanation**. This is the single worst dead end in the app and it sits on the conversion screen.

4. **The "Share to crew" toggle on the celebration screen does nothing to the workout it appears on.** The post is created and
   queued with `shareToCrew: true` hardcoded at `SessionScreen.swift:56` and `HomeScreen.swift:92`, before the celebration
   renders. `CelebrationScreen.swift:40` then offers a toggle that writes only the `shareToCrewDefault` preference, and
   `:41` labels the button "Share to crew" as though pressing it performs the share. Turning the toggle off and pressing the
   button still shares the workout. This is a correctness defect found by a UX read, not a placement opinion.

5. **VoiceOver cannot react to a post.** `PostCard.swift:53` applies `.accessibilityElement(children: .combine)` to the whole
   card, which flattens the inner `Button("React")` into the merged element rather than leaving it reachable. 6.5 makes
   "reacting fully completable non-visually" a release-blocking gate.

6. **The touch-target fix that `SetCountButton` documents was never applied to its eight siblings.** Bare text `Button`s sized by
   their label, in custom layouts, relying on an ancestor's `minHeight` — precisely the bug `SetCountButton.swift:1-6` describes.
   Confirmed sites: `SessionScreen.swift:97, 99, 106` (Swap / Skip / Open), `RestTimerView.swift:21, 23` (Skip / Rest length),
   `PostCard.swift:42` (React), `PostComposer.swift:30` (Same as yesterday), `EditProfileScreen.swift:26` (Open Settings).

Two further structural points, both in the core loop:

7. **The session never scrolls to the exercise you are on.** `ScrollViewReader` has zero occurrences. `SessionModel.advanceFocus`
   (`:177`) moves `focusIndex`, which expands the next card and collapses the finished one — changing content height above the
   viewport with no scroll correction. In a five-exercise workout the user finishes a set and must hunt for where the app moved.

8. **The weight tape and the destructive swipe are the same gesture in the same rectangle.** `SetRow`'s tape (`:107-118`) is a
   horizontal `ScrollView`; `SwipeToRemove` (`:47`) attaches a horizontal `DragGesture` to the content that contains it. A
   leftward drag on the tape is both "lower the weight" and "reveal Remove". **[verify]** which wins on device — but one of the
   two is degraded either way, and the tape sits on the open row, which is usually removable.

### On the bottom-right principle specifically

The brief asks for primary actions in the **bottom-right**. The research does not support making that the general rule, and this
app is already closer to the better answer than a floating bottom-right button would be.

Steven Hoober's observation of 1,333 real device interactions found **49% one-handed, 36% cradled, 15% two-handed**, and of the
one-handed half, **67% right thumb and 33% left**. A bottom-right-only CTA is therefore optimised for roughly a third of all
users (49% × 67%) and actively penalises left-thumb users, who must cross the full width of a Pro Max. A **full-width
bottom-anchored primary** — which is what `PrimaryButton` already is — is reachable for every grip and every handedness, and its
right edge still lands in the right thumb's arc.

So the recommendation is **not** "move the buttons right". It is: **keep the full-width ink primary, and make the bottom anchor
real** by pinning it to the bottom safe area with `safeAreaInset` instead of hoping a `Spacer` holds. Bottom-*right* placement is
reserved for the cases where it genuinely wins: a trailing control paired with a leading secondary inside a bottom bar, and the
already-correct `Send` button in the crew composer (`CrewScreen.swift:84`).

Apple is moving the same direction independently: iOS 26's Liquid Glass redesign moved **search to a bottom tab**, lets the tab
bar **minimise on scroll**, and added `tabViewBottomAccessory` for persistent bottom controls — all explicitly to bring frequent
actions closer to the thumb. The app targets iOS 17 (`ios/project.yml:7-8`), so none of that is available, but the direction of
travel validates a bottom-weighted layout.

---

## Design principles going forward

These are proposed as the app's standing UX rules. They are deliberately few, and each one is falsifiable.

1. **The bottom edge belongs to the day's one action.** Every screen with a dominant action pins it to the bottom safe area with
   `safeAreaInset(edge: .bottom)`. Not a `Spacer`, not an `overlay`, not a `VStack` sibling — the API that also insets the scroll
   content and rises above the keyboard.
2. **Full-width before bottom-right.** A full-width primary serves every grip; a corner-anchored one serves a third of users.
   Bottom-right is for a trailing control that shares a bar with a leading one.
3. **One filled primary per screen is a ceiling, not a floor.** A17.3 already established this on Home's rest state and it holds
   app-wide: on a day that asks nothing, no filled button manufactures an ask.
4. **A control's touch target is its own frame, never its ancestor's.** `minHeight` on an `HStack` sizes the row, not the button.
   Every interactive label carries its own `frame` + `contentShape`.
5. **No dead ends.** Every asynchronous action has a visible failure path with a retry. A callback that handles only `.success`
   is an incomplete implementation, not a happy path.
6. **The keyboard never hides the thing you are trying to press.** Any numeric keyboard carries a Done item; any screen with a
   field and a CTA pins the CTA above the keyboard.
7. **Destructive actions are never adjacent to the primary, and never appear under the finger that just tapped.**
8. **Gesture and button are the same action, and the button is always reachable to VoiceOver.** Already law under 6.3; this
   extends it to the accessibility tree, not just the visual layer.

---

## Screen inventory

Classification per the brief: **A** strong candidate for thumb-zone relocation · **B** possible, content-dependent ·
**C** keep existing placement · **D** the problem is larger than a button move.

| # | Screen (file) | Primary goal | Primary action | Current placement | Recommended placement | Class | Pri | Reason |
|---|---|---|---|---|---|---|---|---|
| 1 | Launch / `HomeSkeleton` (`RootView.swift:18`) | Get to Home | none | — | unchanged | C | — | Correctly has no action; skeleton matches Home per 1A |
| 2 | Hero (`IntroScreen.swift`) | Start the plan | Build my week | bottom, after `Spacer` ✓ | same, but wrap in `ScrollView` | B | P1 | Placement is right; no `ScrollView` means at XXL on an SE the three CTAs can clip — 6.7 names this exact case |
| 3 | Days question (`PlanQuestionsScreen.swift:17`) | Pick training days | Continue | bottom, after `Spacer` ✓ | same + `ScrollView` | B | P1 | Same clipping risk: title + 7×56pt toggles + 2 lines + CTA exceeds 667pt at XXL |
| 4–5 | Experience / Equipment (`SingleSelectQuestion:109`) | Answer one question | tap an option (auto-advances) | **options at top, `Spacer` below** | move `Spacer` above the options | **A** | **P1** | The tap *is* the primary action and it sits in the hardest-to-reach third of a Pro Max with ~400pt of dead space beneath. This is exactly the defect A17.2 fixed on Home, unfixed here |
| 6 | Generated plan (`GeneratedPlanScreen.swift:35`) | Approve the plan | Looks good | bottom of a `ScrollView`, below N cards | `safeAreaInset` bottom bar | **A** | **P0** | The onboarding's peak moment and its CTA is below the fold from first render; the reveal stagger pulls the eye down past it |
| 7 | Save your plan (`SaveAuthScreen.swift:43`) | Create the account | Sign in with Apple / Save | inside `ScrollView`, below 4 fields | Apple button stays high; email CTA into a `safeAreaInset` bar | **D** | **P0** | Keyboard covers the CTA; `.numberPad` has no dismiss; Apple failures are swallowed. Needs a flow fix, not a move |
| 8 | Log in (`LoginScreen.swift`) | Recover access | Log in | inside `ScrollView` | same treatment as #7 | **D** | **P0** | Same swallowed-failure defect; by 1C this screen is a failure state and must behave like one |
| 9 | **Home** (`HomeScreen.swift`) | Know what today is; log it | the day's filled primary | `Spacer` inside `ScrollView` (A17.2) | `safeAreaInset` for the card's primary | **B** | **P0** | Correct *intent*, fragile *mechanism* — the anchor collapses once content exceeds the viewport (offline banner + resume + shield + strip + card + quick-complete + vectors + crew) |
| 10 | **Session** (`SessionScreen.swift`) | Log sets one-handed | Complete workout | pinned `VStack` sibling ✓ | `safeAreaInset` + move Discard out | **D** | **P0** | Anchor works but is hand-built; **"Discard workout" (`:49`) is the last scroll row, directly above the Complete primary** — a 6.3 violation at the exact moment the user reaches for Complete |
| 11 | Cardio log (`CardioLogScreen.swift:45`) | Log minutes | Log {activity} | bottom of `ScrollView`, below a decimal field | `safeAreaInset` bar + keyboard Done | **A** | **P0** | Keyboard covers the CTA and `.decimalPad` offers no way out |
| 12 | Celebration (`CelebrationScreen.swift`) | Bank the win | Done / Share | bottom ✓ | replace toggle+button with two buttons | **D** | **P0** | Placement fine; the toggle is **non-functional** for this post and the button label misstates what happens |
| 13 | Nutrition post (`NutritionPostScreen.swift:28`) | Post a meal | Post | bottom of `ScrollView`, below caption field | `safeAreaInset` bar | **A** | **P0** | Keyboard covers the CTA; S11 promises text-only in ≤3 taps |
| 14 | Plan week map (`PlanScreen.swift:50`) | See the week | open a day (row tap) | rows ✓; two secondaries at list end | leave rows; group the two secondaries | **B** | **P2** | Row-tap primary is correct. "Rebuild my week" is semi-destructive and sits with identical weight directly under "Change days" |
| 15 | Workout editor (`WorkoutEditorScreen.swift:29-34`) | Edit a workout | Save | **nav bar, top-right** | bottom bar (Save trailing, Cancel leading) | **A** | **P1** | Longest-scroll editing screen in the app commits from the least reachable point. Also `navigationBarBackButtonHidden(true)` kills interactive back-swipe |
| 16 | Crew (`CrewScreen.swift`) | Read and react | compose / react | composer bottom ✓, Send bottom-right ✓ | keep; add `refreshable` | **C** | **P2** | Already the best-placed screen in the app. Missing pull-to-refresh on a polled feed |
| 17 | Post card (`PostCard.swift`) | React to a friend | add a reaction | long-press → action sheet | tappable reaction chips + `contextMenu` | **D** | **P1** | Reaction lives in an action sheet that also contains **Block** (destructive beside the most common action); existing chips aren't tappable; VoiceOver can't reach React |
| 18 | Create crew / Invite | Name it / share the link | Create / Share | sheet, standard | unchanged | C | — | Standard sheet affordances are correct |
| 19 | Progress (`ProgressScreen.swift`) | Did I show up | none (read screen) | — | unchanged | C | P3 | No primary action to place. Journal behind a top-right button is a discoverability question, not a reach one |
| 20 | Journal (`JournalScreen.swift`) | Find a past day | none (read) | — | unchanged | C | — | Swipe-to-delete is a correct `List` idiom here |
| 21 | Settings (`SettingsScreen.swift`) | Change one thing | none | `List` rows | unchanged | C | — | A grouped `List` is the right pattern; rows are system-sized |
| 22 | Account rows (`AccountRows.swift:14-20`) | Delete / log out | Delete account | **inline expansion under the finger** | `confirmationDialog(role: .destructive)` | **D** | **P1** | Two-step exists but its geometry is unsafe: the confirming control appears ~one row from the tap that summoned it |
| 23 | Edit profile (`EditProfileScreen.swift:34`) | Change name/photo | Save | **above a trailing `Spacer`** | move `Spacer` above Save | **A** | **P2** | Same spacer-inversion as #4–5; Save floats mid-screen with dead space below |
| 24 | Pause / Blocked / Export / Legal | single settings task | varies | `List` / sheet | unchanged | C | — | Correct as built |
| 25 | Swap / Days / Exercise / Bonus sheets | pick one item | tap a row | sheet rows ✓ | unchanged | C | — | `presentationDetents` already used; row-tap is the action |
| 26 | Welcome back / Stale session / Failed upload | choose one of two | varies | full-screen / sheet ✓ | unchanged | C | — | Two-choice screens, correctly presented |

---

## Phase 4 — primary / secondary / tertiary / destructive, per surface

Only the surfaces where the ranking is currently wrong or absent are listed; everywhere else the existing ranking holds.

| Surface | Primary | Secondary | Tertiary (→ menu/sheet) | Destructive | What is wrong today |
|---|---|---|---|---|---|
| Session | Complete workout | Swap · Skip · Rest length | Add set · Add warm-up · plate math | Discard workout · Remove set | Discard is a peer of Complete by position; Swap/Skip/Open are sub-44pt |
| Celebration | Share to crew | Keep it private | — | — | Expressed as a toggle + a button that both claim the same decision; the toggle is inert for this post |
| Post a meal | Post | Snap · Library | Earlier today · meal tag | — | Post is under the keyboard; "Same as yesterday" is sub-44pt |
| Workout editor | Save | Cancel · Reorder | Add exercise · Add cardio | Remove exercise (has Undo ✓) | Save is at the top-right of a long scroll; no back-swipe |
| Post card | React | — | Report | Block | Report and Block share one sheet with the five reactions |
| Settings → Account | — | Export · Log out | — | Delete account | Destructive confirm lands under the finger |
| Plan week map | open a day | Change days | — | Rebuild my week | Rebuild carries the same weight as a benign secondary |

---

## Phase 5 — bottom-right CTA analysis

Answering the brief's checklist for the screens that actually change.

**Is the primary reachable?** On Session, Crew, Home (short states), Hero and Days — yes. On Generated plan, Nutrition post,
Cardio log, Save auth, Workout editor, Edit profile, and Home at XXL — no.

**Should it be bottom-*right*?** Only in the workout editor, where Save is trailing and Cancel is leading in one bar; and in the
crew composer, where it already is. Everywhere else the answer is full-width bottom, for the handedness reason above.

**Does it need to stay visible while scrolling?** Yes on Generated plan, Session, Nutrition post, Cardio log and Workout editor —
all are "review a list, then commit" screens. No on Hero and the question screens, which do not scroll by design (and must gain a
`ScrollView` only as an XXL overflow valve, not as a normal-use scroll).

**Does the keyboard obscure it?** Yes on Nutrition post, Cardio log, Save auth, Login, Edit profile. `safeAreaInset` resolves all
five, because content placed there rises above the keyboard automatically.

**Does the safe area affect placement?** Yes — and this is the mechanical argument for `safeAreaInset` over `overlay`: it insets
the scroll content by the bar's height, so the last row is never trapped behind the bar, and it sits above the home indicator
without a hardcoded number. Two screens currently fake this with hand-computed padding: `PlanScreen.swift:66` and
`WorkoutEditorScreen.swift:99`.

**Does Dynamic Type affect it?** Yes. `PrimaryButton` uses `minHeight: dayToggleMinPt` and `.font(.headline)`, so it grows — but
in a `Spacer`-anchored layout, growth is what collapses the anchor. Pinning makes growth harmless.

**Could it conflict with gestures?** One real case: the weight tape vs. the remove-swipe (finding 8). A bottom bar itself does not
conflict with the home-indicator swipe as long as it sits inside the safe area, which `safeAreaInset` guarantees.

**Would it create a hierarchy problem?** On Home's rest and all-done states, yes — and A17.3 already ruled that those states carry
no filled primary deliberately. The bottom bar must therefore be **conditional**: present when the state has a primary, absent
when it does not. It must not become a permanent chrome strip that manufactures an ask.

---

## Navigation audit

- **Five tabs is correct** and each is a genuine destination. No change.
- **`TabView` has no `tag`/selection binding** (`RootView.swift:28-35`). Tab selection cannot be driven programmatically, which
  blocks deep links and "post a meal → land on Home" style returns. Worth adding before the invite/universal-link work.
- **Journal is a top-right button inside Progress** (`ProgressScreen.swift:37`). S16 is a first-class screen reached through a
  toolbar glyph on another screen. A sixth tab is worse; the better options are a segmented control at the top of Progress, or
  leaving it and accepting the depth. Flagged, not prescribed — **owner call**.
- **Home's camera toolbar button** (`HomeScreen.swift:40, 124-133`) now duplicates the Meals slot of `VectorRow`. A17.3's own
  reasoning ("A3 requires *a way*, not a dedicated button each") applies to it identically, and it sits in the top-right corner —
  the least reachable point. But A3 named this button explicitly, so removing it is an **owner decision**, not an audit finding.
- **`WorkoutEditorScreen` hides the back button** to install Cancel/Save (`:28`), which disables the interactive pop gesture on a
  *pushed* screen. Either present it as a sheet (where Cancel/Save is the native idiom) or restore the swipe.

---

## CTA system

One table, to be enforced by code review rather than by a new abstraction layer.

| Role | Component | Rule |
|---|---|---|
| Primary | `PrimaryButton` | Ink fill, full width, `.headline`, ≥56pt. **At most one per screen.** Lives in the bottom `safeAreaInset` when the screen scrolls |
| Secondary | `SecondaryButton` | Hairline outline, ink label, full width. Never stacked more than two deep |
| Text action | **`TextActionButton`** (rename of `SetCountButton`) | Any inline verb: Swap, Skip, Open, React, Undo, Same as yesterday. Carries its own `frame(minWidth:minHeight:)` + `contentShape` |
| Icon-only | inline `Button` + `frame` + `contentShape` + `accessibilityLabel` | Already correct at `HomeScreen.swift:124` and `CrewScreen.swift:84`; that shape is the standard |
| Bottom bar | **`.crewBottomBar { }`** (new, see Component strategy) | `safeAreaInset(edge:.bottom)`, canvas background, hairline top edge. Conditional — absent when the state has no primary |
| Destructive | native `confirmationDialog` + `role: .destructive` | Never inline-expanded, never adjacent to the primary, never in a sheet that also holds a common action |
| Loading | `PrimaryButton(isLoading:)` | Already correct: label swaps for a `ProgressView`, button disables |
| Disabled | `.disabled` + `Opacity.disabled` | Current practice. Where the reason is knowable, prefer a one-line hint over a silent dim |
| Success | existing `BoneToast` / `UndoSnackbar` | Bottom overlay, tap to dismiss. Should move to `safeAreaInset` so it stops needing hand-computed padding |

---

## Authentication UX — including the Face ID question

**Recommendation: do not add Face ID or `LocalAuthentication` to this app.** This is a considered answer to the brief's example,
not a deferral.

The reasoning is the app's own law. Spec 1C: *"Sessions persist in Keychain indefinitely — a Crew user is asked to authenticate
ONCE per device, ever (the login screen is a failure state, not a feature)."* `RootView.swift:13` implements exactly that. There
is therefore **no recurring login for a biometric shortcut to accelerate** — a "Sign in with Face ID" button would offer to speed
up an event that happens once in the lifetime of an install. Adding it would also mean a new `NSFaceIDUsageDescription`, a new
permission prompt, and a new failure path, in exchange for nothing.

The places biometrics could legitimately appear, ranked, and why each is still a no today:

1. **Gating `Delete account` / `Export my data`** — defensible, but the two-step confirm is the right control for an
   irreversible action, and biometrics would not make the tap safer, only slower.
2. **A16's private nutrition surface** — the one genuinely "private" vector in the product. But A16 is maintenance-only, gated on
   the owner's age-questionnaire task (W070), and pre-building a lock for it is scope expansion under CLAUDE.md rule 10.
3. **Anything else** — no.

**What the brief's example is actually pointing at, correctly, is real here.** "Success moves the user forward automatically;
failure gives an obvious recovery path" is violated today — by Sign in with Apple, not by a missing Face ID button:

```swift
// LoginScreen.swift:20  and  SaveAuthScreen.swift:25  — both identical
} onCompletion: { result in
    if case .success(let authorization) = result, ... { Task { await model.saveWithApple(...) } }
}
// no `case .failure` — cancel, no-credential, and network failure are all indistinguishable from "nothing happened"
```

Apple's `ASAuthorizationError.canceled` is returned **both** when the user cancels and when the system finds no credential — a
deliberate privacy behaviour. So the no-credential user is the one who suffers most: a button that does nothing, with no way to
learn why.

**The target authentication flow:**

1. Hero → 3 questions → plan → Save. Unchanged; plan-before-account is the product's best idea and it works.
2. On the save screen the native Apple button stays primary and stays high — it is the fastest path and App Store guidance wants
   it prominent. Change its label to `.signUp` on `SaveAuthScreen` ("Sign up with Apple"), keeping `.signIn` on `LoginScreen`.
3. **Add `case .failure(let error)` to both.** Map `ASAuthorizationError.canceled` to a quiet, non-alarming inline line that
   offers the email path ("Continue with email instead"); map everything else to the standard one-sentence error + retry.
4. Email path: autofocus the first field, `submitLabel(.next)` chaining to `.done`, keyboard Done item on the birth-year pad, and
   the CTA pinned above the keyboard.
5. Session restoration is already correct and silent (`RootView.swift:13-22`) — leave it alone.
6. The login screen keeps its "failure state, not a feature" character: no biometric chrome, no promotion.

---

## Form UX

Applies to `SaveAuthScreen`, `LoginScreen`, `CardioLogScreen`, `EditProfileScreen`, `NutritionPostScreen`, `CreateCrewScreen`.

- **Focus the first field on appear.** `FocusState` exists in exactly one file today.
- **Chain the keyboard.** `.submitLabel(.next)` / `.done` + `onSubmit` moving focus. Zero occurrences of either today.
- **Every numeric pad gets a Done.** `ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focused = nil } }` —
  required on `.numberPad` (birth year) and `.decimalPad` (distance), which have no return key.
- **The CTA rides above the keyboard** via `safeAreaInset`.
- **Keep field-exit validation** (`AuthField.swift:88`) — it is already the right choice and better than per-keystroke.
- **Keep `.textContentType`** and the deliberate `.password`-not-`.newPassword` decision documented at `SaveAuthScreen.swift:35-38`.
- `.scrollDismissesKeyboard(.interactively)` on every form scroll view, not just `SaveAuthScreen`.

## Error UX

`ErrorState` (one sentence + "Try again") is well built and correctly used on Home, Plan, Progress and Crew. The gaps are the
paths that never reach it:

- Sign in with Apple failure (above) — the P0.
- `SessionScreen.swift:67` shows the coaching cue in an `.alert` with a "Got it" button. An alert is a modal interruption used
  for a non-critical hint; a small inline disclosure under the exercise name would fit the moment better. Also the exercise name
  is a `Button` with no visual affordance, so the cue is undiscoverable. **P3.**
- **[verify]** `confirmationDialog("Discard this workout?", isPresented:)` at `SessionScreen.swift:68` passes no
  `titleVisibility`; the sibling at `WorkoutEditorScreen.swift:36` explicitly passes `.visible`. If `.automatic` hides the title
  without a message on iOS, the discard sheet asks nothing. Confirm on device and make the two consistent either way.

## Loading UX

Already compliant: `HomeSkeleton` / `ListSkeleton` mirror final layout, `PrimaryButton(isLoading:)` swaps in a `ProgressView`,
and the five-state enums are real on Home, Plan, Crew and Progress. One improvement: **`Haptics` creates a feedback generator and
fires it in the same statement** (`Haptics.swift:11-21`) with no `prepare()`, which adds first-fire latency against 6.2's
"set-check → haptic < 50ms" budget. On iOS 17 the idiomatic fix is the `.sensoryFeedback` modifier (zero current uses).

## Accessibility UX

Release-blocking under 6.5. Each item below must hold for any change this document proposes.

| Requirement | Status | Action |
|---|---|---|
| Reacting completable non-visually | **FAIL** — `PostCard.swift:53` `.combine` swallows the React button | Use `.accessibilityActions` or `children: .contain` |
| Touch targets ≥44pt | **FAIL** on 8 controls (listed in finding 6) | Route all through `TextActionButton` |
| Weekday labels unambiguous | **FAIL** — `DayToggle` speaks "T" for Tuesday and Thursday, "S" for both weekend days (`PlanQuestionsScreen.swift:63`) | Full weekday name as `accessibilityLabel`, letter stays visual |
| Primary action visible at XXL on SE | **FAIL** on Home (collapsing `Spacer`), Hero and the question screens (no `ScrollView`) | `safeAreaInset` + `ScrollView` overflow valves |
| Icon-only buttons labelled | PASS — camera, send, check and steppers all carry labels | — |
| Staggered reveal hidden from a11y | **[verify]** `GeneratedPlanScreen.swift:32` uses `.opacity(0)`, which leaves cards in the a11y tree and hit-testable during the 0.5s reveal | Pair `.opacity` with `.accessibilityHidden(index >= revealed)` |
| Reduce Motion honoured | PASS — `withCrewMotion`, and the reveal/count-up both branch | — |
| Dynamic Type on targets | PASS — `@ScaledMetric` throughout the session screen | Extend to the new bottom bar |
| Contrast | Handled by A17.4; not re-audited here | — |

---

## Component strategy

The Concrete Doctrine (C1, C5) forbids abstractions without live users and permits extraction **only on the third occurrence,
into a plain function**. Measured against that, most of the components the brief lists are already present or are not earned:

**Build — the threshold is already passed:**

1. **`.crewBottomBar { }`** — one small `ViewModifier` wrapping `safeAreaInset(edge: .bottom)`. Live users at the moment of
   writing: Generated plan, Session, Nutrition post, Cardio log, Workout editor, Home, Save auth, Login. That is eight, well
   past three, and every one of them currently hand-rolls a different wrong version (`Spacer`, `VStack` sibling, `overlay` +
   hand-computed padding). This is the single highest-leverage change in the document.
2. **`TextActionButton`** — not a new component. `SetCountButton` already *is* this, with the correct implementation and a comment
   explaining why. Rename it, widen its use to the eight sites in finding 6, delete the duplicated frame/contentShape code.

**Do not build:** `PrimaryCTA` (`PrimaryButton` exists) · `LoadingButton` (`isLoading` exists) · `ErrorState` / `EmptyState`
(exist) · `FloatingPrimaryAction` (no screen earns a FAB; full-width wins on handedness) · `AuthenticationButton` (two call
sites, both native `SignInWithAppleButton` — wrapping it would be a C1 violation) · `FormFooter` (that is `.crewBottomBar`) ·
`DestructiveAction` (the native `confirmationDialog` + `role:` is the control; a wrapper adds nothing).

Net: **one new modifier, one rename.** No design-system layer, no protocols, no generics.

---

## Phase 10 — prioritised roadmap

Every item lists: problem → current → recommended → rationale → guidance → files → tests → a11y → regression risk.
Nothing here is implemented. Ordering within a priority is dependency-true: **R1 lands first because six other items sit on it.**

### P0 — critical

**R1 · The bottom anchor is not real**
*Problem:* `safeAreaInset` has zero uses; "bottom-anchored" is a `Spacer` in scrolling content or a `VStack` sibling.
*Current:* the anchor collapses whenever content exceeds the viewport — guaranteed on an SE at XXL.
*Recommended:* add `.crewBottomBar { }`; adopt on Home, Session, Generated plan, Nutrition post, Cardio log, Workout editor.
Conditional — absent on states with no primary (A17.3).
*Rationale:* 6.7 "bottom CTAs sit above the home indicator" + "reachability holds at Pro Max"; principle 1.
*Guidance:* `safeAreaInset(edge:.bottom)` is Apple's API for exactly this and rises above the keyboard.
*Files:* new `Shared/BottomBar.swift`; `HomeScreen`, `SessionScreen`, `GeneratedPlanScreen`, `NutritionPostScreen`,
`CardioLogScreen`, `WorkoutEditorScreen`.
*Tests:* XCUITest asserting the primary is hittable at XXL on an SE for each screen; extend the existing `Screenshots` sweep.
*A11y:* bar must use `@ScaledMetric`; must not trap VoiceOver focus above it.
*Risk:* **medium** — changes layout on the two most-tested screens; journeys ①② touch both. Home's A17.2 reasoning must be
preserved exactly, not re-argued.

**R2 · Keyboard covers the primary; numeric pads cannot be dismissed**
*Current:* `NutritionPostScreen:28`, `CardioLogScreen:45`, `SaveAuthScreen:40,43` — CTA below a field, no keyboard toolbar.
*Recommended:* CTA into the bottom bar (R1) + `ToolbarItemGroup(placement:.keyboard)` Done on every `.numberPad` / `.decimalPad`.
*Rationale:* 6.7; `.decimalPad`/`.numberPad` ship no return key — a Done item is the documented remedy.
*Files:* the three screens + `EditProfileScreen`, `LoginScreen`.
*Tests:* XCUITest — focus the distance field, assert Done exists and the CTA is hittable.
*Risk:* low.

**R3 · Sign in with Apple swallows every failure**
*Current:* `LoginScreen:20-24`, `SaveAuthScreen:25-29` handle only `.success`.
*Recommended:* add `.failure`; `.canceled` → quiet inline line offering the email path; others → one-sentence error + retry.
*Rationale:* 6.1 "never a dead end"; `.canceled` also means *no credential available*, so silence strands that user permanently.
*Files:* both screens + `OnboardingModelAuth`.
*Tests:* unit test on the error→line mapping; the round trip stays BLOCKED-CREDENTIALS (T012).
*Risk:* low. High conversion value — this is the signup screen.

**R4 · The celebration's share toggle is inert and its button label misstates the outcome**
*Current:* `shareToCrew: true` hardcoded at `SessionScreen:56` and `HomeScreen:92`; `CelebrationScreen:40` toggles only a
default; `:41` reads "Share to crew" though the post is already queued.
*Recommended:* **owner decision between two honest shapes** — (a) carry the real choice into completion so the toggle acts on
this post, or (b) drop the toggle and make the celebration two buttons: primary "Share to crew", text "Keep it private", both
writing the post's actual visibility. (b) is simpler and removes a control.
*Rationale:* S10 "share-default remembered"; 6.6 copy law — a CTA must name what it does.
*Files:* `CelebrationScreen`, `SessionModel`, `SessionActions`, `HomeModel.quickComplete`.
*Tests:* unit — a post completed with share off carries `shareToCrew == false` into the queued payload. **New vector likely**
(append-only): if visibility becomes a completion input, that is a behaviour change and needs a Decision Registry entry.
*Risk:* **medium** — touches the completion path and the sync payload. Server already accepts the field.

**R5 · Destructive adjacency in the session**
*Current:* "Discard workout" (`SessionScreen:49`) is the final scroll row, immediately above the Complete primary.
*Recommended:* move Discard to a nav-bar item (or a `Menu`), leaving the bottom bar to Complete alone.
*Rationale:* 6.3 "destructive never adjacent to primary".
*Files:* `SessionScreen`. *Tests:* journey ② still completes; new XCUITest asserts Discard is not in the bottom bar.
*Risk:* low.

**R6 · VoiceOver cannot react to a post**
*Current:* `PostCard:53` `.combine`.
*Recommended:* `.accessibilityActions { }` exposing each reaction, or `children: .contain`.
*Rationale:* 6.5 release-blocking gate.
*Files:* `PostCard`. *Tests:* XCUITest reacting via the accessibility action. *Risk:* low.

### P1 — high value

**R7 · Eight sub-44pt controls** — route Swap/Skip/Open/React/Rest-skip/Rest-length/Same-as-yesterday/Open-Settings through the
renamed `TextActionButton`. 6.3. Files: `SessionScreen`, `RestTimerView`, `PostCard`, `PostComposer`, `EditProfileScreen`,
`SetCountButton`→`TextActionButton`. Tests: a doctrine-lint rule banning a bare `Button("…")` inside `Features/` without an own
`frame` would prevent recurrence. Risk: low; layout shifts slightly where labels grow.

**R8 · The session does not follow the exercise you are on** — wrap the session `ScrollView` in `ScrollViewReader` and
`scrollTo(focusIndex, anchor: .top)` on `advanceFocus`, animated through `withCrewMotion`. Rationale: Flow 3's one-handed
promise; the rest timer was already moved into the focused card (`RestTimerView.swift:2-3`) for the same reason — this finishes
that fix. Files: `SessionScreen`, `SessionModel`. Tests: XCUITest — after checking the last set of exercise 1, exercise 2's first
set row is hittable without scrolling. Risk: medium (scroll behaviour interacts with the tape and the swipe).

**R9 · Question screens push their only action to the top** — move `Spacer()` above the options in `SingleSelectQuestion`; same
for `EditProfileScreen`'s Save. Rationale: A17.2's own finding, applied where it was not. Files: `PlanQuestionsScreen`,
`EditProfileScreen`. Tests: existing journey ① screenshots. Risk: **very low** — this is a two-line change with the highest
ergonomic return in the document.

**R10 · Hero and question screens can clip at XXL** — wrap in `ScrollView` as an overflow valve. 6.7 non-negotiable. Risk: low.

**R11 · Workout editor commits from the top-right and has no back-swipe** — Save/Cancel into a bottom bar, or present the editor
as a sheet where nav-bar Cancel/Save is the native idiom. Restore the interactive pop either way. Risk: medium (it is a `List`
with an edit mode).

**R12 · Reactions: destructive shares a sheet with the most common action** — make existing reaction chips tappable (the
universal idiom), move Report/Block to a `contextMenu` or a separate "…" affordance. 6.3. Risk: low.

**R13 · Account deletion confirms under the finger** — replace the inline expansion with
`confirmationDialog(role: .destructive)`, keeping the two-step and the "can't be undone" sentence. E18 is satisfied either way;
this is about geometry. Risk: low.

### P2 — medium

**R14** Pull-to-refresh (`.refreshable`) on the crew stream and Progress — a polled feed with no manual refresh is a gap against
every iOS social app. **R15** `TabView` selection binding, needed before deep links. **R16** Plan week map: separate "Rebuild my
week" from "Change days" by weight and position. **R17** Toasts/snackbars move to `safeAreaInset`, deleting the hand-computed
padding at `PlanScreen:66` and `WorkoutEditorScreen:99`. **R18** Adopt `.sensoryFeedback` / prepare generators for the 6.2
haptic budget.

### P3 — polish

**R19** Coaching cue as inline disclosure rather than an alert, with a visible affordance on the exercise name. **R20** Hide
un-revealed plan cards from the a11y tree during the stagger. **R21** Confirm and normalise `titleVisibility` on the discard
dialog. **R22** Progress screen's stats are bare text lines ("Sets per week: 12 · 15 · 9") — a small chart would serve Flow 9's
"how much work" layer better. **R23** Weight tape vs. swipe-to-remove gesture arbitration, pending the device check.

---

## Phase 11 — recommended implementation plan

**Nothing above is implemented. This is the proposed sequence, for approval.**

**Stage A — the mechanism (unblocks six items).** Build `.crewBottomBar`, rename `SetCountButton` → `TextActionButton`. Adopt the
bar on **one** screen — Generated plan, the lowest-risk of the six, outside journeys ①② — verify at XXL on the SE simulator, then
roll to the remaining five one commit at a time. *Purely mechanical; no flow changes.*

**Stage B — the dead ends (P0 correctness).** R3 (Apple failure), R6 (VoiceOver react), R2 (keyboard Done). Each is small,
independent, and separately testable. *R3 and R4 are the only items that change what the user experiences functionally rather
than positionally.*

**Stage C — the share decision (R4).** Needs an owner ruling first (shape (a) or (b)), then a Decision Registry entry, and — if
visibility becomes a completion input — a **new append-only vector**. This is the one item that cannot start without paperwork.

**Stage D — the cheap ergonomic wins.** R9 (two-line spacer inversions), R10 (`ScrollView` valves), R7 (touch targets), R5
(Discard relocation). High return, low risk, all visual.

**Stage E — the core-loop feel.** R8 (scroll-to-focus), R11 (editor), R12 (reactions), R13 (delete confirm). These change flows
and need journey coverage.

**Stage F — P2/P3** as capacity allows.

**Which screens change first:** Generated plan → Save auth / Login → Nutrition post → Cardio log → Session → Home.
**Components created:** one (`.crewBottomBar`). **Components renamed:** one (`SetCountButton`).
**Architectural changes:** none. No new layer, protocol, generic, or dependency; the Concrete Doctrine is untouched.
**Purely visual:** R1, R7, R9, R10, R17. **Flow-altering:** R3, R4, R8, R11, R12, R13.
**Needs new tests:** R1 (XXL/SE hittability), R4 (payload + likely a vector), R6 (a11y action), R8 (journey step).

### Process gates before any code

1. **Owner ratification** of this document as Appendix A entry **A19**, with an explicit ruling on R4's shape and on the two
   owner-call items (Home's toolbar camera; Journal's placement).
2. **Part XI ordering** — Stage 7 (A15, "change today's workout") is the current next task. A15's sheet adds a fourth route to
   the bonus list, and A17.3's forward note already says *"A15 does not ship until Home is settled."* If A19 is ratified, Home is
   not settled, and A19 Stage A should precede A15.
3. **Web parity** (6.8) — R2, R3, R4, R7 and R13 have web twins that must move with them.
4. **`docs/debt.md`** gets an entry for anything compromised, in the same commit.

---

## Sources

- [Apple HIG — Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) · [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) · [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass) · [Get to know the new design system (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/356/) · [Build a SwiftUI app with the new design (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Enhancing the tab bar with a bottom accessory](https://www.createwithswift.com/enhancing-the-tab-bar-with-a-bottom-accessory/) · [Exploring tab bars on iOS 26 with Liquid Glass — Donny Wals](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [Steven Hoober — How Do Users Really Hold Mobile Devices? (UXmatters)](https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php) · [The Thumb Zone — Smashing Magazine](https://www.smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users/) · [Action Bar Adaptations for One-Handed Use (arXiv)](https://arxiv.org/pdf/2208.08734)
- [ASAuthorizationError.Code.canceled](https://developer.apple.com/documentation/authenticationservices/asauthorizationerror-swift.struct/code/canceled) · [SignInWithAppleButton.Label](https://developer.apple.com/documentation/authenticationservices/signinwithapplebutton/label) · [Accessing Keychain Items with Face ID or Touch ID](https://developer.apple.com/documentation/LocalAuthentication/accessing-keychain-items-with-face-id-or-touch-id) · [Local Authentication](https://developer.apple.com/documentation/localauthentication)
- [Pin a view to the bottom of safe area in SwiftUI](https://nilcoalescing.com/blog/PinAViewToTheBottomOfSafeArea/) · [SwiftUI Safe Area — fatbobman](https://fatbobman.com/en/posts/safearea/) · [SwiftUI keyboard avoidance — Five Stars](https://www.fivestars.blog/articles/swiftui-keyboard/)
