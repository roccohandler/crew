# design/targets/

The owner's APPROVED MOCKUPS (Appendix A, A28 — owner-approved 2026-09-19): the Focus Card system (`design/focus-card-system.md`),
twelve screens drawn in both modes and exported from Claude Design at 390×844. `ui-reviewer` judges a tour screenshot against
`design/DESIGN.md` always, and against the mockup that governs it (the map below) in the MATCHING MODE — a light screenshot
against `…-light.png`, a dark one against `…-dark.png`. A mockup is approved intent: layout, hierarchy, spacing rhythm, component
choice and where accent appears. Its seeded content (names, numbers, exercises, the date) is illustrative; where its copy
contradicts the spec, the spec wins (DESIGN.md, introduction).

Until the light lock lifts (the Home session, A28 (a)), the tour photographs light only, so only the `-light` files are compared.
`01-home-first-day-light.png` was not supplied: the first-day Home is judged in light against DESIGN.md and against
`03-home-training-day-light.png` for the card itself (same card, no reward block; its sub-line "Your season starts today" is
where mockup 01 draws it — where the string finally lives is GAP 5 in A28).

| mockup (light / dark) | the screen and state | governs the tour shot(s) |
|---|---|---|
| `01-home-first-day-dark.png` (light: not supplied) | Home — first day: no reward block, the card, "Start your first workout" | `tour_hometests/NN_home_home_bridge.png` |
| `02-home-no-plan-{light,dark}.png` | Home — no plan: no reward block, the card is the hero at 44 pt | `tour_hometests/NN_home_home_empty.png` |
| `03-home-training-day-{light,dark}.png` | Home — training day: ring + flame, the card, Start workout, Quick complete, Macros row | `tour_hometests/NN_home_home_filled.png`, `tour_nutritiontests/NN_home_home_macrosrow.png` |
| `04-home-rest-day-{light,dark}.png` | Home — rest day: no filled button, the card carries tomorrow | `tour_hometests/NN_home_home_restday.png` |
| `05-home-done-{light,dark}.png` | Home — done: no filled button, "Edit today's log" as text | `tour_sessiontests/NN_home_home_done.png` |
| `06-home-off-season-{light,dark}.png` | Home — off-season (paused): snowflake, the ring stays accent, "End the pause" | `tour_settingstests/NN_home_home_paused.png` |
| `07-logger-start-{light,dark}.png` | Logger — set 1: last time below the card | `tour_sessiontests/NN_session_logger_start.png`, `tour_sessiontests/NN_session_logger_longname.png` (set 1 of the second exercise) |
| `08-logger-mid-set-{light,dark}.png` | Logger — mid-set: the running ledger replaces the last-time line | `tour_sessiontests/NN_session_logger_midset.png` |
| `09-logger-whole-workout-{light,dark}.png` | Logger — the whole-workout sheet: jump between exercises; **Finish lives here** | none yet — the Logger session adds the tour step |
| `10-logger-mobility-{light,dark}.png` | Logger — the mobility checklist: tick the holds, Mark all done, Finish | none yet — the Logger session adds the tour step |
| `11-logger-after-finish-{light,dark}.png` | Logger — after Finish: the celebration (flame, streak, XP, share or keep private) | `tour_sessiontests/NN_session_celebration_complete.png` |
| `12-progress-{light,dark}.png` | Progress — top: title, the season line, the heat map; no accent | `tour_progresstests/NN_progress_charts_filled.png` |

`NN` is the tour's step number, which moves when steps are added; match on the rest of the name. A screen with no row here has no
mockup yet: judge it against DESIGN.md alone.
