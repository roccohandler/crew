# Crew build progress

Updated: 2026-09-04 · Current phase: 0

## Ledger

- [x] T001 spec-constants ⚙ — done 2026-09-04 (115 constants in 20 sections; two numbers the spec never states are OMITTED, not guessed — gaps G1, G2 below)
- [x] T002 generate pipeline (design-tokens + generate.mjs + check-drift.mjs) ⚙ — done 2026-09-04 (both scripts run clean; drift check proven to fail on a hand edit)
- [ ] T003 vector fixtures V01–V40 🛑 owner reviews vectors ← NEXT
- [ ] T004 seed exercises.json 🛑 owner approves
- [ ] T005 seed plan-templates.json 🛑 owner approves
- [ ] T006 seed achievements.json + docs/api.md 🛑 owner signs → Phase 1
- [ ] T007 monorepo scaffold ⚙
- [ ] T008 CI + doctrine lint ⚙
- [ ] T009 lib/db.ts + collections + unique indexes
- [ ] T010 server auth (register/login/refresh/logout)
- [ ] T011 lib/email.ts + password reset flow
- [ ] T012 Sign in with Apple (server + iOS AuthStore + web)
- [ ] T013 iOS shells + five-state scaffolds ⚙
- [ ] T014 SyncQueue + in-memory SwiftData tests
- [ ] T015 standing-checks.gen.test.ts
- [ ] T016 DayKey twin
- [ ] T017 GamificationEngine streak + XP core
- [ ] T018 Shields + Pause in engine
- [ ] T019 Completion/undo/edit rules (gate: V01–V36 green both)
- [ ] T020 PlanGenerator + SwapFinder twins + property test
- [ ] T021 Onboarding screens S02–S04
- [ ] T022 SaveAuthScreen (S05; S06 removed v1.9)
- [ ] T023 Plans/Sessions/Sync API routes
- [ ] T024 Home S07 today-state machine + bridge
- [ ] T025 Session feature S09
- [ ] T026 CelebrationScreen + workout post + Posts API (S10)
- [ ] T027 Nutrition posting S11 + lib/blob.ts
- [ ] T028 Journey ① green 🛑 Phase 2 gate review
- [ ] T029 Crews API
- [ ] T030 Messages + Reactions API
- [ ] T031 Crew feature S12–S13
- [ ] T032 Engine crew rules + comeback (V37–V40)
- [ ] T033 Notifications (push-token route, APNs, eligibility)
- [ ] T034 Moderation (reports, blocks, EULA gate)
- [ ] T035 Journey ② + security matrix 🛑 Phase 3 gate review
- [ ] T036 Web onboarding + plan builder
- [ ] T037 Web session logging + posting
- [ ] T038 Web crew stream/chat/progress + invite landing (W1)
- [ ] T039 Playwright ③④ + Lighthouse + token parity 🛑 Phase 4 gate review
- [ ] T040 Progress + Journal both platforms (S15–S16)
- [ ] T041 Settings S17: pause, export, delete cascade
- [ ] T042 Edge screens: welcome-back, stale-session, failed-upload
- [ ] T043 A11y pass + offline matrix + perf signposts
- [ ] T044 Security sweep + zero P0/P1 🛑 Phase 5 gate review
- [ ] T045 TestFlight + web beta + metrics 🛑 owner reviews metrics weekly
- [ ] T046 Production env, monitoring, backups, secrets rotation
- [ ] T047 App Store submission + launch checklist + registry audit 🛑 SHIP

## Blockers

- OPEN OWNER DECISION (non-blocking until S06): Firebase Auth ⏳ (Appendix B) is unresolved. Per Part XII 12.5 the approved custom auth proceeds by default — Sign in with Apple + email, jose JWTs + crypto.scrypt hashing, Resend reset emails. Nothing may be built against Firebase until the owner decides.
- PROCESS: `git init` is blocked by the owner's user-locked hook, so the S01 commits (docs setup, T001, T002) could not be made by the agent. The owner runs `git init` + the three commits listed in the S01 handoff message; after that the loop commits normally.
- SPECIFICATION GAP G1: XP per reaction is never stated — V27 caps reactions at five per day (reactionXpDailyCap = 5 is recorded) but the amount each of the first five earns is undefined. Constant omitted from spec-constants.json. (T001 recorded; needed for T003 V27 and T017, waiting on owner)
- SPECIFICATION GAP G2: level thresholds — GamificationState.level and Award.levelUp(Int) exist (Part IX, 5.6.1) but no XP→level table exists anywhere. (T001 recorded; needed for T003/T017, waiting on owner)
- SPECIFICATION GAP G3 (interpretation to confirm): Flow 8 "≤15 exercises/day, ≤20 sets" — recorded as planMaxSetsPerDay = 20 (per training day). If the owner meant per exercise, rename the constant before any code uses it. (T001, waiting on owner)
- SPECIFICATION GAP G4: dark-mode values for missedGray and emberText are not in Part III. design-tokens.json carries `dark: null`; generate.mjs emits the light value with a `SPECIFICATION GAP` comment until the owner fills them (see debt.md). (T002, waiting on owner)
- SPECIFICATION GAP G5: 5.2 says design-tokens.json carries spacing and 6.4 requires one app-wide spring curve; the spec gives no spacing scale and no spring parameters. Both omitted from the token file. (T002; needed by T013, waiting on owner)
- SPECIFICATION GAP G6: "perfect week" is never defined. V18 implies every planned workout completed; unstated whether every day must also carry a post and whether a shield-absorbed day disqualifies. (T003 V13/V14/V17/V18/V28, waiting on owner)
- SPECIFICATION GAP G7: exercise count for the "Some" experience answer — only Brand new = 4 and Experienced = 6 are given. (T005, waiting on owner)
- SPECIFICATION GAP G8: the softTap haptic is named in 6.4 but never assigned a trigger (1B's "selection haptic" is the likely one). (T013/T021, waiting on owner)
- SPECIFICATION GAP G9: rest timer default length (spec says only "per-workout length · off-able") and the plate-math plate inventory + bar weight. (T025, waiting on owner)
- SPECIFICATION GAP G10: time-smart meal-tag hour boundaries — the spec gives examples only (7 AM 🍳 · 12:30 🥗 · 7 PM 🍽 · odd hours 🥤). (T027, waiting on owner)
- SPECIFICATION GAP G11: JWT access/refresh lifetimes and the auth + posting rate-limit values (8.7 requires rate limits; no numbers). (T010, waiting on owner)
- SPECIFICATION GAP G12: default reminder time — Flow 2 shows 7:00 AM as an example only. (T033, waiting on owner)

## Notes for next session

- Session S02 = T003 (40 vector fixtures in shared/vectors/*.vectors.json, append-only), ends at its 🛑. Gaps G1, G2, G6 affect V13–V18, V27, V28 — get them answered first, or write those vectors with the gap named in the fixture so the 🛑 review resolves them.
- Not yet emitted by generate.mjs: SeedData.swift and seed.ts — added when the seed JSONs land (T004–T006); no speculative code before then (C5).
