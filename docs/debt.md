# Crew technical debt ledger

Every compromise, recorded in the same commit that creates it (CLAUDE.md rule 9; Appendix C).
Format: `- <date> · <task> · <what was compromised> · <why> · <how it gets repaid>`

## Open

- 2026-09-04 · T003 · V35 ("earned achievements survive undo") uses the opaque placeholder id `first-post`; no vector yet AWARDS an achievement · shared/seed/achievements.json does not exist until T006 (owner approves the list) · repaid by appending achievement-awarding vectors (V45+) right after T006 is signed, never by editing V35.

## Repaid

- 2026-09-04 · T002 · EmberColors.swift and ember.css emitted the LIGHT value for `missedGray` and `emberText` in dark mode (Part III defined no dark values; gap G4) · repaid the same day: owner set missedGray dark = #5E574F and emberText dark = #FF7A1F (Decision Registry G4), tokens updated, files regenerated, the generator no longer tolerates a missing dark value.
