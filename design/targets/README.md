# design/targets/

The owner's APPROVED MOCKUPS (Appendix A, A28 — owner-approved 2026-09-19): the Focus Card system (`design/focus-card-system.md`),
twelve screens drawn in both modes and exported from Claude Design at 390×844. `ui-reviewer` judges a tour screenshot against
`design/DESIGN.md` always, and against the mockup that governs it (the map below) in the MATCHING MODE — a light screenshot
against `…-light.png`, a dark one against `…-dark.png`. A mockup is approved intent: layout, hierarchy, spacing rhythm, component
choice and where accent appears. Its seeded content (names, numbers, exercises, the date) is illustrative; where its copy
contradicts the spec, the spec wins (DESIGN.md, introduction).

The Home session (R1) lifted the iOS light lock: every Home state is photographed twice, and a shot whose name ends `_dark` is judged
against the `-dark` file of its row, the rest against `-light`. The other screens stay light-only in the tour until their own
session adds their dark shot. `01-home-first-day-light.png` was not supplied: the light first-day Home is judged against DESIGN.md
and against `03-home-training-day-light.png` for the card itself (same card, no reward block; its sub-line "Your season starts
today" is where mockup 01 draws it — R-084 reads GAP 5 as that card, and only that card).

| mockup (light / dark) | the screen and state | governs the tour shot(s) |
|---|---|---|
| `01-home-first-day-dark.png` (light: not supplied) | Home — first day: no reward block, the card, "Start your first workout" | `tour_hometests/NN_home_home_bridge.png`, `…_bridge_dark.png` |
| `02-home-no-plan-{light,dark}.png` | Home — no plan: no reward block, the card is the hero at 44 pt | `tour_hometests/NN_home_home_empty.png`, `…_empty_dark.png` |
| `03-home-training-day-{light,dark}.png` | Home — training day: ring + flame, the card, Start workout, Quick complete, Macros row | `tour_hometests/NN_home_home_filled.png`, `…_filled_dark.png`, `tour_nutritiontests/NN_home_home_macrosrow.png` |
| `04-home-rest-day-{light,dark}.png` | Home — rest day: no filled button, the card carries tomorrow | `tour_hometests/NN_home_home_restday.png`, `…_restday_dark.png` |
| `05-home-done-{light,dark}.png` | Home — done: no filled button, "Edit today's log" as text | `tour_sessiontests/NN_home_home_done.png`, `…_done_dark.png` |
| `06-home-off-season-{light,dark}.png` | Home — off-season (paused): snowflake, the ring stays accent, "End the pause" | `tour_settingstests/NN_home_home_paused.png`, `…_paused_dark.png` |
| `07-logger-start-{light,dark}.png` | Logger — set 1: last time below the card | `tour_sessiontests/NN_session_logger_start.png`, `…_logger_longname.png` (set 1 of the second exercise); no dark shot yet (debt) |
| `08-logger-mid-set-{light,dark}.png` | Logger — mid-set: the running ledger replaces the last-time line | `tour_sessiontests/NN_session_logger_midset.png`, `…_midset_dark.png` |
| `09-logger-whole-workout-{light,dark}.png` | Logger — the whole-workout sheet: jump between exercises; **Finish lives here** | `tour_sessiontests/NN_session_whole_workout_sheet.png`, `…_sheet_dark.png` |
| `10-logger-mobility-{light,dark}.png` | Logger — the mobility checklist: tick the holds, Mark all done, Finish | `tour_sessiontests/NN_session_logger_mobility.png`, `…_mobility_dark.png` |
| `11-logger-after-finish-{light,dark}.png` | Logger — after Finish: the celebration (flame, streak, XP, share or keep private) | `tour_sessiontests/NN_session_celebration_complete.png`, `tour_hometests/NN_session_celebration_complete_dark.png` |
| `12-progress-{light,dark}.png` | Progress — top: title, the season line, the heat map; no accent | `tour_progresstests/NN_progress_top_filled.png`, `…_top_filled_dark.png`, `…_top_empty.png` (Charts and the Journal, one tap below: DESIGN.md alone) |

The Logger's other shots — the weight keypad (`session_weight_alert`), ⋯ (`session_more_menu`), the discard confirm and the swap sheet —
have no mockup and are judged against DESIGN.md alone.

The "+" sheet (`tour_hometests/NN_home_add_sheet.png`, `…_add_sheet_rest.png`) has no mockup: A28 (d) names the "+" and the
system draws its sheet surface (§6, the card on a scrim), so it is judged against DESIGN.md alone.

`NN` is the tour's step number, which moves when steps are added; match on the rest of the name. A screen with no row here has no
mockup yet: judge it against DESIGN.md alone.
