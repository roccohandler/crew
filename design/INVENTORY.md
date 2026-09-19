# Crew — UI inventory before the redesign

Source: the master UI tour of ci run 35351054305 (commit 9d309d1, 2026-09-18, 65 screenshots, iPhone 17 simulator, light). Screenshot
paths are relative to the tour folder (`CREW_TOUR_DIR/master/`, or `design/tour/latest/`); tap paths are TOUR.md's. Actions were read
from the Swift views, visuals from the pixels. Rule numbers are `design/DESIGN.md`'s, with the spec section each one cites.
This file observes. It proposes no direction. **The "Screen job" lines are the owner's to fill in.**

Legend — **P** filled ink primary · **S** outlined secondary · **T** text button (a bare word) · **Row** tappable row · **TB** toolbar item.
⚑ marks a duplicate or unclear action.

---

## 1. Onboarding

### Intro — `tour_onboardingtests/01_onboarding_intro_default.png` · fresh install, first launch
- Actions: "Build my week" P · "I have an invite" S · "Log in" T.
- Patterns: hero sentence; three stacked buttons at the bottom.
- Density / colour: none. Data: none.
- Screen job (one sentence): Say what Crew is and let me start, join, or log back in.

### Invite code — `tour_onboardingtests/02_onboarding_invitecode_empty.png` · intro → I have an invite
- Actions: "Paste" T · "Find my crew" S (keyboard Search does the same ⚑) → becomes "Continue" P in the same slot ⚑.
- Patterns: outlined field; disabled = faded outline.
- Violations: the only action is outlined and mid-screen — 4.2 (6.3, 6.7). Data: titled "Your invite" here, "I have an invite" on the Crew sheet, for the same form.
- Screen job (one sentence): Take my friend's code and show me the crew it belongs to.

### Log in — `tour_onboardingtests/03_onboarding_login_empty.png` · intro → Log in
- Actions: Sign in with Apple (black system button) · Email, Password · "Forgot your password?" T ⚑ (sends a reset at once, no confirmation) · "Log in" P (bottom bar).
- Violations: two filled buttons — 3.1 (6.9). Apple's button is #000 with its own radius (system-mandated). Data: "Log in" looks enabled with empty fields.
- Screen job (one sentence): Get me back into my account.

### Days question — `tour_onboardingtests/04_onboarding_days_default.png` · intro → Build my week
- Actions: seven day circles (ink fill = selected) · "Continue" P.
- Patterns: selected circle looks like the primary (same ink fill). Data: "1 of 2", while the empty states say "three questions".
- Screen job (one sentence): Ask which days I train.

### Experience question — `tour_onboardingtests/05_onboarding_experience_default.png` · days → Continue
- Actions: three option cards; tapping one advances by itself ⚑ (no Continue).
- Data: ~800 pt of empty canvas between header and options.
- Screen job (one sentence): Ask how experienced I am.

### Plan reveal — `06_onboarding_plan_built.png`, `07_onboarding_swap_sheet.png` · answered Brand new; tapped an exercise
- Actions: every exercise row opens the swap sheet ⚑ (no chevron, no "Swap"; only a one-time whisper says so) · "Looks good" P (bottom bar).
- Patterns: seven hairline day cards; workout card; equipment as an outlined pill.
- Data that looks wrong: **Mon and Wed rows are blank** though three days were chosen; the whisper "Tap any exercise to swap it." shows with no exercise on screen; `07` shows NO swap sheet (the tour's tap did not open it).
- Screen job (one sentence): Show me the week you built and let me change exercises I don't want.

### Save / sign up — `08_onboarding_save_empty.png`, `09_onboarding_save_typing.png` · Looks good; typed a name
- Actions: Sign in with Apple · Name, Email, Password, Birth year · "Log in instead" T · "Save your plan" P (bottom bar). "the terms" in the legal line is not a link ⚑.
- Violations: two filled buttons — 3.1 (6.9). Data: heading "Save your plan" = button "Save your plan"; in `09` Email and Password are already red though untouched, Password red with no message; the heading slides under the back button.
- Screen job (one sentence): Keep this plan by making me an account.

## 2. Home

### Home, first day (bridge) — `tour_hometests/01_home_home_bridge.png` · launched with a plan and no post yet
- Actions: one P ("Start your first workout").
- Data: ~1000 pt of empty canvas; no week strip or log rows, unlike every other Home state.
- Screen job (one sentence): Get me into my first workout.

### Home, no plan — `tour_hometests/01_home_home_empty.png` · launched with no plan
- Actions: "Build my week" P.
- Violations: the page is white, not canvas — section 1 table (Part III). Data: "three questions" vs "1 of 2" in the flow; full-bleed band floating mid-screen.
- Screen job (one sentence): Get me to build a plan.

### Home, training day — `tour_hometests/01_home_home_filled.png`, `tour_nutritiontests/01_home_home_macrosrow.png` · launched with a streak, a crew, today open; scrolled
- Actions: "Start workout" P (in the card) · "Quick complete" S · rows "Log workout", "Log cardio", "Log macros" · (when a session is open) "Resume workout" S at the top. ⚑ Up to FOUR controls start or finish the same workout; "Log workout" silently means "start today's" or "open the bonus picker".
- Patterns: streak = ember flame + number; weekly goal = ember ring "4/7"; week strip = letters + dots (ember done · thick ring today · ink dot next · thin ring other) with a sentence restating it; workout = white card; log rows = outlined group, no chevrons; crew = avatars + corner dot + bare number.
- Violations: streak explainer, ring, strip + sentence, card, Quick complete + explainer, three log rows and the crew strip need a second scroll length — 3.2 / 3.3 (6.9). Colour: none (all ember is progress).
- Data: "Push day" title directly above "PUSH DAY" card (three times once scrolled); log rows ghost through the tab bar; streak 6 beside "4/7"; numbers under avatars unlabelled.
- Screen job (one sentence): Tell me what I'm training today and start it.

### Home, rest day — `tour_hometests/01_home_home_restday.png` · launched on a rest day
- Actions: "Log workout" (→ bonus sheet; the word "bonus" appears nowhere ⚑) · "Log cardio" · "Log macros".
- Violations: "Nothing to do here" sits directly above three actions — 3.2 borderline (6.9).
- Data: "Rest day" title + "Rest day —" card; the ink "●" before "25 min" is the strip's "next" glyph; "This week: nothing logged yet" beside a logged 25 min.
- Screen job (one sentence): Tell me today is rest and keep my streak safe.

### Home, done — `tour_sessiontests/08_home_home_done.png` · shared the workout, back on Home
- Actions: log rows remain; "Log workout · Done" still opens a picker ⚑.
- Data: "Done for today" twice; "1/6 sets · 0 min"; captured mid-dismiss (tab icons dimmed).
- Screen job (one sentence): Confirm today is finished and show what I did.

### Home, paused — `tour_settingstests/08_home_home_paused.png` · paused the plan, went Home
- Actions: "End the pause now" S ⚑ (also on Settings → Pause) · log rows.
- Violations: four-word CTA — 8 (6.6). Data: "Plan paused" twice; future-day dots drawn differently from the training-day Home.
- Screen job (one sentence): Remind me the plan is paused and let me end it.

### Rebuild sheet — `tour_hometests/02_home_rebuild_sheet.png` · Home (no plan) → Build my week
- Actions: day circles · "Continue" P. No Cancel, no grabber ⚑. Same first screen as Plan → Change days ⚑.
- Screen job (one sentence): Ask which days I train now.

### Bonus workout sheet — `tour_hometests/02_home_bonus_sheet.png` · rest-day Home → Log workout
- Actions: list rows start a bonus session. No close button.
- Patterns: system list + chevrons; "Next up" outlined pill (same shape as a button and as the equipment tag).
- Screen job (one sentence): Let me pick a workout that isn't today's.

### Cardio log — `tour_hometests/02_home_cardiolog_empty.png` · Home → Log cardio
- Actions: 3×3 activity chips · system stepper for minutes ⚑ (the session uses the custom stepper for the same datum) · Distance field · "Log Walk" P (bottom bar).
- Violations: Distance field has no boundary — 1.6 (A18.11). Data: the selected chip is drawn exactly like the primary; "Log Walk" is not sentence case — 8 (6.6).
- Screen job (one sentence): Log the cardio I just did in a few taps.

### Reminder opt-in — `tour_sessiontests/07_home_reminder_sheet.png` · after the first shared workout
- Actions: time picker · "Remind me" P · "Not now" T.
- Data: ~600 pt blank above the heading; system gray pill.
- Screen job (one sentence): Ask whether I want a nudge on workout days, and when.

## 3. Plan

### Week map — `tour_plantests/01_plan_week_empty.png`, `01_plan_week_filled.png` · Plan tab
- Actions: day rows → editor · "Change days" S · "Rebuild my week" S ⚑ (both begin with the same days screen; nothing says Rebuild replaces the exercises). No P.
- Patterns: outlined rows with chevrons; "✓" typed inline in the title.
- Violations: list + two buttons exceed one screen — 3.3 borderline (6.9); empty state on a white page — section 1.
- Data: the second button hides behind the tab bar with mirrored ghost text; every day reads "2 exercises + mobility".
- Screen job (one sentence): Show my week at a glance and let me change it.

### Change days — `tour_plantests/02_plan_days_sheet.png` · Plan → Change days
- Actions: day circles · "Save days" P. No Cancel.
- Data: all seven selected beside "Most people start at 3 days."
- Screen job (one sentence): Ask which days I train from now on.

### Workout editor — `tour_plantests/03_plan_editor_filled.png` · Plan → Push day
- Actions: TB "Cancel" · TB "Save" · rows → exercise sheet · "Reorder" T ⚑ (reorder also lives in the exercise sheet as Move up / Move down) · "+ Add exercise" · "+ Add cardio".
- Patterns: system list.
- Data: "Mobility · 0 holds · ~0 min" under a header that says "+ mobility"; "~10 min" for 2 × 3 × 8.
- Screen job (one sentence): Let me change one day's exercises, sets and order.

### Exercise sheet — `tour_plantests/04_plan_exercise_sheet.png` · editor → an exercise
- Actions: TB "Done" ⚑ (closes; nothing persists until the editor's Save) · Sets / Reps steppers · "Swap exercise" S · "Move up" / "Move down" S · "Remove from Push day" T (ink, no confirmation). Four buttons, no P.
- Violations: edit, swap and reorder in one half-sheet — 3.2 borderline (6.9).
- Screen job (one sentence): Let me adjust, swap, move or remove this one exercise.

### Swap / Add exercise sheets — `tour_plantests/05_plan_swap_sheet.png`, `06_plan_addexercise_sheet.png`, `tour_sessiontests/04_session_swap_sheet.png`
- Actions: tap a row to pick ⚑ (no chevron, no close button — drag only).
- Data: ~100 pt gap under the title; last row clipped by the sheet corner.
- Screen job (one sentence): Let me pick a different exercise for this slot.

## 4. Crew

### Crew, solo — `tour_crewtests/01_crew_solo_empty.png` · Crew tab with no crew
- Actions: "Start a crew" P · "I have an invite" S.
- Data: heading "Start a crew" = button "Start a crew"; buttons mid-screen — 4.2 (6.3).
- Screen job (one sentence): Explain what a crew does and get me to start or join one.

### Create crew — `tour_crewtests/02_crew_create_sheet.png` · Start a crew
- Actions: name field · eight emoji circles · "Start a crew" P · TB "Cancel".
- Violations: field and emoji chips have no boundary — 1.6 (A18.11); emoji row clipped both sides — 4.3 (6.7). Data: all content flush to the left edge, no gutter.
- Screen job (one sentence): Name my crew and start it.

### Join by code — `tour_crewtests/03_crew_joincode_sheet.png` · I have an invite
- Same form as onboarding's invite code, with a different title ⚑.
- Screen job (one sentence): Take my friend's code and put me in their crew.

### Crew stream — `tour_crewtests/01_crew_stream_filled.png`, `02_crew_react_dialog.png` · Crew tab; tapped React
- Actions: TB "Invite" ⚑ (the sheet behind it also renames, regenerates, removes and leaves) · "React" T (long-press does the same ⚑); Report and Block hide under "React" ⚑.
- Patterns: members = avatar + ember/hollow dot + bare number; posts = white cards; system lines = centred gray text.
- Colour: ember dot on avatars as a status mark — 1.1 / 1.2 borderline (Part III).
- Data: "0 min" on both posts; "Four people who know you…" with three members; ~350 pt blank gap above the stream; `02` shows NO dialog.
- Screen job (one sentence): Show me who showed up today and let me react.

### Invite sheet — `tour_crewtests/03_crew_invite_sheet.png`, `04_crew_invite_sheet_lower.png` · Crew → Invite
- Actions: "Send invite link" (hand-rolled ink fill) · "Copy code" S · crew name + emoji fields · "Save name" S ⚑ (also saves the emoji) · "Regenerate link (old one dies)" S · "Remove" per member (red T, no confirmation) · "Leave crew" (red T, no confirmation) · TB "Done" on the left.
- Violations: five jobs in a sheet titled "Invite" — 3.1 / 3.2 (6.9). Data: emoji is free text here, a picker in Create; `04` reveals nothing new.
- Screen job (one sentence): Get the invite to my friends.

## 5. Progress

### Charts — `tour_progresstests/01_progress_charts_empty.png`, `01_progress_charts_filled.png`, `02_progress_charts_filled_lower.png`
- Actions: Charts | Journal segment · heat-map cells are tappable ⚑ (nothing says so) · empty: "Go to today" P.
- Patterns: heat map (unlabelled squares); weekly rings in a sideways row; stats as dot-separated gray sentences; one line chart in a card.
- Violations: ~12 rows of empty cells fill the first screen; about three scroll lengths in all — 3.2 / 3.3 (6.9); ring captions clipped at the edge — 4.3 (6.7); empty state on white — section 1.
- Data: all four rings "0/7" beside "6 workouts · streak 6" (Home says 4/7); no weekday, month or legend labels; ember cells tint the tab bar.
- Screen job (one sentence): Show me whether I've been showing up, and whether I'm getting stronger.

### Journal — `tour_progresstests/02_progress_journal_empty.png`, `03_progress_journal_filled.png`
- Actions: swipe a row → Delete ⚑ (swipe only, no visible button — 4.2 (6.3); no confirmation).
- Patterns: borderless white capsule rows (a radius nothing else uses).
- Data: "0 min" on every row; rows look static though the note says they are editable.
- Screen job (one sentence): Let me look back at what I actually did, day by day.

## 6. Session

### Logger — `tour_sessiontests/01_session_logger_start.png`, `03_session_logger_midset.png` · Home → Start workout; checked set 1
- Actions: TB "Discard" · "Yes" / "Use kg" T · exercise name (hidden button → cue) ⚑ · "Swap" / "Skip" T · reps ± · weight ±, tape and tap-to-type (three inputs for one number ⚑) · check circle or row tap ⚑ · swipe → Remove (swipe only) · "+ set" / "+ warm-up" T · rest: "Rest 1:30" T (a toggle ⚑), ±, "Skip" T (second "Skip" in one card ⚑) · "Complete workout" P (bottom bar).
- Patterns: "Barbell  Swap  Skip" are three same-styled gray words, one label and two buttons.
- Violations: unit prompt, three hint lines, three sets with 14 stepper buttons and a ruler on one screen — 3.1 / 3.2 (6.9); upcoming sets greyed below 4.5:1 — 7 (6.5).
- Data: ruler labels clipped ("5", a stray tick); needle between 125 and 150 while the value reads 150 (`03`); `03` shows no rest timer though the step says it is running; "+ set" cut by the bottom bar.
- Screen job (one sentence): Log each set as I do it, with as few taps as possible.

### Weight alert — `tour_sessiontests/02_session_weight_alert.png` · tapped the weight
- System alert: field, "Set", "Cancel". Field has no outline — 1.6. Covers the card title.
- Screen job (one sentence): Let me type an exact weight.

### Discard dialog — `tour_sessiontests/05_session_discard_dialog.png` · tapped Discard
- One red "Discard" in a system popover; no text, no Cancel; covers the button that opened it. System red, not the berry `danger` — 1.5 plausible.
- Screen job (one sentence): Confirm I'm throwing this workout away.

### Celebration — `tour_sessiontests/06_session_celebration_complete.png` · Complete workout
- Actions: "Share to crew" P · "Keep it private" T (solo: "Done" P).
- Colour: ember is the reward layer here — correct. Data: captured mid count-up; "1/6 sets · 0 min".
- Screen job (one sentence): Show me what I just did and let me choose whether the crew sees it.

## 7. Settings

### Settings list — `tour_settingstests/01_settings_settings_top.png`, `02_settings_settings_bottom.png`, `07_settings_pause_active.png`, `tour_nutritiontests/11_settings_settings_nutrition.png`
- Actions: profile row · "Pause my plan" · Weight / Distance pickers · four toggles (+ reminder time) · "Nutrition targets" ⚑ (opens a screen titled "Your birth year" when the year is unknown) · "How targets are estimated" · "Delete my nutrition data" (ink) · "Blocked people" · "Privacy policy" · "Terms" · "Export my data (JSON)" · "Log out" (no confirmation) · "Delete account" (red) · "How Crew works" · Version.
- Patterns: system inset list, ~26 pt radius; chevrons on some link rows and not others.
- Violations: ~20 rows, 2.5 screens — 3.3 (6.9); radius is not 16 — 4.1 (G5).
- Data: title floats over blurred rows when scrolled; mirrored ghost text under the tab bar; `07` shows Settings mid-transition, not the Pause screen.
- Screen job (one sentence): Let me find and change anything about my account, plan or privacy.

### Blocked people — `tour_settingstests/03_settings_blocked_empty.png`
- Actions: "Unblock" T per row. Empty = a gray sentence in a capsule row, no invitation — 6.1 / 6.3 (6.1).
- Screen job (one sentence): Show who I've blocked and let me unblock them.

### Profile — `tour_settingstests/04_settings_profile_default.png`, `05_settings_photo_dialog.png`
- Actions: avatar / "Change photo" (looks like a caption ⚑) → one-item menu "Choose photo" ⚑ · name field · "Save" P.
- Violations: name field has no boundary — 1.6 (A18.11), 7 (6.5). Data: Save enabled with nothing changed; the popover covers the title.
- Screen job (one sentence): Let me set my name and photo.

### Pause — `tour_settingstests/06_settings_pause_default.png`
- Actions: return-date picker · "Pause until then" P · (paused) "End the pause now" S.
- Violations: primary mid-screen, ~900 pt empty below — 4.2 (6.3, 6.7). Data: "Pause" title + "Pause my plan" heading.
- Screen job (one sentence): Pause my plan until a date I pick.

## 8. Nutrition (18+)

### Today, first run — `tour_nutritiontests/01_nutrition_today_firstrun.png` · Home → Log macros, no targets yet
- Actions: bodyweight field · "Estimate my targets" P · "How targets are estimated" T (no affordance ⚑).
- Violations: primary mid-screen in this capture — 4.2 (fixed in commit 8c83a74, after this tour). Data: titled "Today", the same word as Home's title.
- Screen job (one sentence): Turn my bodyweight into daily macro targets.

### Today — `02_nutrition_today_filled.png`, `03_nutrition_today_logged.png` · Home → Log macros; tapped the Breakfast slot
- Actions: template slot row (tap logs, tap again undoes ⚑ invisibly) · "Quick add" S · "Logged today · N" S · "Saved meals & template" T. No P; no route to Targets from here.
- Patterns: macro line = letter + name, "x / y g", tinted bar with an unexplained tick at 80 %, "N to go"; three different fill treatments (flat · outlined · striped); calories as text.
- Colour: macro tints without ember — allowed, 1.4 (A16). Data: the fat bar's inner stripe reads as a glitch; 2660 kcal here vs "2650 kcal" on Targets.
- Screen job (one sentence): Show what's left to eat today and log a meal in one tap.

### Quick add — `04_nutrition_quickadd_default.png` · Today → Quick add
- Actions: three gram steppers · "Add" P (bottom bar). Violations: the disabled "Add" label is unreadable — 7 (6.5).
- Screen job (one sentence): Log grams for something not in my saved meals.

### Logged today — `05_nutrition_log_filled.png` · Today → Logged today
- Actions: "Delete" T per row (ink, no confirmation). Bare rows on canvas, no container.
- Screen job (one sentence): Show everything I logged today and let me remove a mistake.

### Saved meals / Template — `06_nutrition_meals_filled.png`, `10_nutrition_template_filled.png` · Today → Saved meals & template; Template segment
- Actions: segment · per meal "Edit" / "Delete" T · "Add a meal" S · "Add from a chain" S (four words — 8 (6.6); the addendum's literal copy) · per slot "Up" / "Down" / "Remove" T ⚑ (a third reorder idiom) · slot picker, label field, "Add to template" S.
- Data: slot name wraps because of the three text buttons; "Up" enabled on the only row; "Remove" ink here, red in Crew.
- Screen job (one sentence): Saved meals — Keep the meals I eat over and over. Template — Set the meals I eat on a normal day.

### Meal form — `07_nutrition_mealform_sheet.png`
- Actions: Name · gram steppers · "Save meal" P (bottom bar) · TB "Cancel". Data: enabled at empty / 0 / 0 / 0 while Quick add disables; label and placeholder both "Name".
- Screen job (one sentence): Enter or edit one meal's macros.

### Chain picker — `08_nutrition_chains_sheet.png`, `09_nutrition_chainitems_sheet.png`
- Actions: chain rows (chevrons) → item rows (no chevron, no "+" ⚑) → prefilled meal form. Items have Back only, no Cancel.
- Violations: list radius not 16 — 4.1 (G5). Data: three glyphs for six chains.
- Screen job (one sentence): Find a fast-food item and save it as a meal.

### Nutrition targets — `12_settings_nutritiontargets_filled.png` · Settings → Nutrition targets
- Actions: bodyweight · gram steppers · "Save targets" P (bottom bar) · "Recalculate from bodyweight" S (overwrites, no confirmation) · "How targets are estimated" T ⚑ (also a Settings row).
- Violations: three captions and a link on one form — 3.2 borderline (6.9).
- Screen job (one sentence): Show and adjust my daily targets.

### Methodology / How Crew works — `13_settings_nutritionmethod_default.png`
- Actions: underlined source links. A destination document; text and garbled glyphs show through the tab bar.
- Screen job (one sentence): Explain the reasoning and show the sources.

---

## 9. Words that mean more than one thing

- **"Done"** — keyboard dismiss · close the exercise sheet · close the Invite sheet · end reorder mode · mark cardio done · dismiss the celebration · Home's status "Done".
- **"Today"** — Home's title and the nutrition screen's title; the tab is "Home"; the CTA is "Go to today".
- **"Skip"** — skip the exercise and skip the rest, in one card. **"Keep it"** — cancel a delete (Settings) and cancel a swap (Session).
- **The ink dot "●"** — "next" in the week strip, "25 min logged" and "Done" in the log rows.

## 10. Every UI component in use, and its visual variants

| Component | Variants | What they are |
|---|---|---|
| Filled primary button | 2 | `PrimaryButton`; a hand-rolled ink ShareLink (Invite ×2) |
| Disabled treatment | 4 | dark-gray fill · light-gray fill with unreadable label · faded outline · gray-text pill; plus three forms whose primary never disables |
| Outlined button | 3 | `SecondaryButton`; CardioRow's "Done"; system `.bordered` (failed upload) |
| Text button | 3 | `TextActionButton`; hand-rolled ink word (~10 uses); underlined source link |
| Selectable tile | 4 | day circle · activity chip · experience card · emoji circle |
| Card / surface | 6 | `Card` · week row · unit prompt · compact session row · "Set removed" bar · outlined row group (written twice: Home log rows, template rows) |
| Group of rows | 5 | white 16 pt card · outlined canvas group · system inset list (~26 pt) · borderless capsule rows · bare rows on canvas |
| Tappable row | 7 + system | chevrons on some, none on others |
| Stepper / number entry | 5 | custom − value + · labelled stepper row · gram field (− box +) · rest-timer pair · native system stepper; plus the weight tape |
| Text field | 8 | outlined r12 (auth, nutrition) · outlined r16 (invite ×2) · no outline (create crew, profile) · gray fill (cardio distance) · bare (in-session distance) · system alert capsule |
| Segmented / menu picker | 1 + 1 | system |
| Toggle · date picker | 1 each | system, ink tint / gray pill |
| Chip / tag | 4 | equipment pill · "Next up" pill · "Sending" capsule · reaction pill; equipment also appears as plain text two ways |
| Toast / snackbar | 3 | bone toast · undo snackbar · inline "Set removed · Undo" |
| Banner | 1 | offline |
| Empty state | 3 | `EmptyState` band on a white page · left-aligned canvas layout · a gray sentence |
| Error | 2 (+3 colours) | full `ErrorState`; inline line in danger, ink or secondary ink |
| Loading | 3 | `LoadingLine` · in-button spinner · label swap ("Saving…") |
| Bottom bar | 2 | `crewBottomBar` with a rule · bottom-anchored with no rule; many primaries use neither |
| Sheet chrome | 6 | Cancel left · Done left · Done right · grabber only · nothing · back button inside a sheet |
| Dialog | 3 | confirmation dialog (system popover) · alert · inline confirm |
| Destructive style | 5 | ink toolbar text · red text · ink text · red swipe fill · system bordered; confirmation is a dialog, an inline confirm, an undo bar, or nothing |
| Reward / data visuals | 8 | flame · weekly ring · week strip · heat map · line chart · macro bar (3 fills) · crew strip · avatar (2 sizes) |
| Education line | 1 | `Whisper` |
| Section heading | 4 | question header · caps caption · title3 · list section header |

## 11. Tour captures that do not show what they are named for

`02_crew_react_dialog` (no dialog) · `07_onboarding_swap_sheet` (no sheet) · `07_settings_pause_active` (Settings, mid-transition) ·
`03_session_logger_midset` (no rest timer) · `06_session_celebration_complete` and `08_home_home_done` (mid-animation) ·
`04_crew_invite_sheet_lower` (nothing new revealed). These are tour-step defects, listed so nobody designs from them.

## 12. Inconsistencies for the owner's Claude Design session to resolve

Added 2026-09-18 with the ratified screen jobs (spec Appendix A, A27). They join the top ten in `design/claude-design-brief/README.md`.

- **Three reorder idioms.** One exercise can be reordered in three places — the exercise sheet's "Move up" / "Move down", the
  editor's "Reorder", the nutrition template's "Up" / "Down" — and one idiom should win.
- **Settings is one long list.** ~20 rows across 2.5 screens — 3.3 (6.9); it needs grouped destinations rather than one list.
- **Blocked people's empty state is a gray sentence, not an invitation** — 6.3 (6.1).
