# Crew — brief for a design session

## What Crew is

Crew is an iPhone app for people who already train at a gym. It builds one push · pull · legs plan that repeats every week from two
questions. It gives them a set-by-set workout logger they can run with one thumb. A small invite-only crew of two to ten friends
sees each finished workout and can react to it — no chat, no feed, no leaderboards. A streak counts the planned training days
they showed up for; rest days ask nothing, and adults can privately log protein, carbs and fat.

## Hard constraints (from `design/DESIGN.md`, which cites the spec; the spec wins any conflict)

- **Tokens only.** Canvas #FAF8F5 · card #FFFFFF · hairline #E9E4DD · ink #211D19 · control outline #938C83 · secondary text #6F6860 ·
  missed gray #A8A29A · success #3E8E5A · danger #D64550. Spacing 4 / 8 / 12 / 16 / 24 / 32; 24 between groups, 8 within; radius 16.
- **Ember is reward-only.** #DF5908 for shapes, #B84D00 for words, #FFEFE3 for tints: the streak flame, XP, ring and heat-map
  fills, celebration accents — nothing else. No button, link, toggle, tab or control is ever orange. Most screens show no ember at rest.
- **70 / 20 / 10.** 70 % canvas, 20 % ink (all text and ALL controls: filled ink primary, outlined secondary), ≤ 10 % ember.
- **Warm neutrals, no second hue.** One exception: three macro identity tints on nutrition screens only, never beside ember.
- **Light always.** The app renders light whatever the phone is set to; nothing is designed in dark.
- **Density (6.9).** One job and at most one filled primary per screen · secondary information one tap away behind a labelled
  control · a second scroll-length of content becomes its own screen · never buy density by shrinking targets or type.
- **Touch and layout.** Targets ≥ 44 × 44 pt · primaries bottom-anchored in the thumb zone · destructive never next to the primary ·
  the workout logger fully one-handed, tab bar hidden · every swipe has a visible button · portrait, nothing scrolls sideways.
- **Accessibility gate.** Text ≥ 4.5:1 · components ≥ 3:1 · usable at the largest Dynamic Type · no meaning by colour or motion alone.
- **Platform.** SwiftUI, iOS 17+, iPhone only, native iOS feel (system navigation, sheets, lists, haptics; no sound). Five fixed
  tabs: Home · Plan · Crew · Progress · Settings.
- **Voice.** Warm gym buddy; sentence case; verb-first CTAs of one to three words; no "!", no guilt, never red for a missed day.

## The two priority screens

1. **Home** — every state is in `screens/home/`: first day (`01_home_home_bridge`), no plan (`01_home_home_empty`), training day
   (`01_home_home_filled`, scrolled: `01_home_home_macrosrow`), rest day (`01_home_home_restday`), done (`08_home_home_done`),
   paused (`08_home_home_paused`).
2. **The workout logger** — `screens/logger/`: start (`01_session_logger_start`), typing a weight (`02_session_weight_alert`),
   mid-set (`03_session_logger_midset`), swap (`04_session_swap_sheet`), discard (`05_session_discard_dialog`), the celebration
   (`06_session_celebration_complete`).

Screenshots are from ci run 35351054305 (iPhone 17 simulator). Two were captured mid-animation (`06`, `08_home_home_done`), and
`03` does not show the rest timer it should. The full per-screen inventory is `design/INVENTORY.md`.

### Their jobs — ratified by the owner 2026-09-18 (spec Appendix A, A27; the full list is in `design/DESIGN.md`)

A control that does not serve its screen's job is a candidate for removal. A job with two homes has one too many.

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

The last four (Rebuild, Bonus, Cardio log, Reminder opt-in) are sheets with no shot in `screens/home/`; their tour shots are listed in
`design/INVENTORY.md` §2.

**The workout logger**

- Logger: Log each set as I do it, with as few taps as possible.
- Weight alert: Let me type an exact weight.
- Discard dialog: Confirm I'm throwing this workout away.
- Celebration: Show me what I just did and let me choose whether the crew sees it.

## Top 10 inconsistencies, ranked by how much they hurt a first-time user

1. **Buttons drawn as plain words, indistinguishable from labels.** "Barbell  Swap  Skip" are three identical gray words — one is a
   label, two are buttons; also React, Edit / Delete, Up / Down / Remove, "Saved meals & template", "Change photo".
2. **Tappable rows with no sign they are tappable.** Home's three Log rows, journal rows, swap lists, chain items and half of
   Settings have no chevron; other rows do.
3. **Four controls for one workout on Home.** Start workout, Quick complete, Log workout and (when open) Resume all act on
   today's workout; "Log workout" silently means two different things.
4. **The same title printed twice, stacked.** "Push day" over "PUSH DAY", "Rest day", "Done for today", "Plan paused",
   "Save your plan", "Start a crew".
5. **The dot means four things.** Done, today, next and other days in the week strip; "logged" and "Done" in the log rows;
   "trained today" on avatars; and the numbers under avatars have no label.
6. **Numbers that contradict each other.** Streak 6 beside 4/7 and four rings at 0/7 · "three questions" then "1 of 2" ·
   2660 vs 2650 kcal · "0 min" on every workout · "+ mobility" then "0 holds".
7. **One number, five ways to enter it.** System stepper, − value +, − box +, ruler tape, typed alert — three of them for the
   weight alone, on one screen.
8. **Disabled looks four ways, and some forms never disable.** One disabled label is unreadable; "Save meal", "Log in" and
   "Save" look ready with nothing entered.
9. **Destructive actions have no rule.** Red or ink for the same verb; confirmed by a dialog, an inline line, an undo bar or
   nothing ("Leave crew" and "Log out" act at once).
10. **No rule for where the main button sits or how a sheet closes.** Bottom bar with a rule, bottom without, or mid-screen;
    sheets close by Cancel, Done-left, Done-right, a grabber, or nothing at all.

## Three more, added with the screen jobs (2026-09-18) — for this session to resolve

- **Three reorder idioms.** One exercise can be reordered in three places — the exercise sheet's Move up / Move down, the
  editor's Reorder, the nutrition template's Up / Down — and one idiom should win.
- **Settings is one long list.** About 20 rows across 2.5 screens; it needs grouped destinations rather than one list.
- **Blocked people's empty state is a gray sentence, not an invitation.**

The visual direction is the owner's decision in this session. Nothing here proposes one.
