# Crew technical debt ledger

Every compromise, recorded in the same commit that creates it (CLAUDE.md rule 9; Appendix C).
Format: `- <date> · <task> · <what was compromised> · <why> · <how it gets repaid>`

## Open

- 2026-09-04 · T002 · EmberColors.swift and ember.css emit the LIGHT value for `missedGray` and `emberText` in dark mode · Part III defines no dark value for either (progress.md gap G4); the generator refuses to invent one and marks both with a `SPECIFICATION GAP` comment · repaid when the owner fills the two `dark: null` entries in shared/design-tokens.json and `node shared/scripts/generate.mjs` is re-run — the comments disappear automatically.

## Repaid

(none)
