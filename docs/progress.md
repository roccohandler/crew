# Crew build progress

Updated: 2026-09-04 · Current phase: 0

## Ledger

- [x] T001 spec-constants ⚙ — done 2026-09-04 (132 constants in 23 sections after the 2026-09-04 gap resolutions G1–G12; every number tagged to its rule)
- [x] T002 generate pipeline (design-tokens + generate.mjs + check-drift.mjs) ⚙ — done 2026-09-04 (emits SpecConstants.swift · EmberColors.swift · EmberTokens.swift · spec-constants.ts · ember.css; drift check proven to fail on a hand edit)
- [x] T003 vector fixtures V01–V40 (+V18b, V41–V44 = 45) — written 2026-09-04; `node shared/scripts/check-vectors.mjs` green; independent reference fold reproduced every expected value (0 mismatches) 🛑 OWNER REVIEWS VECTORS — line stopped
- [ ] T004 seed exercises.json 🛑 owner approves ← NEXT, starts only after the T003 🛑 clears
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

- 🛑 T003 VECTOR REVIEW (S02 exit): the owner reviews shared/vectors/*.vectors.json (45 vectors) + shared/vectors/README.md (the fixture contract). Interpretations flagged with `reviewNote` in the fixtures, each needing a yes/no: V08 (DST "user's favor" = the day keeps a full 24 h, boundary at 04:00 that night) · V14 (+150 still paid when shields are capped) · V24 (Part IX type `text` earns only the first-post XP; a text-only meal is kind `meal`) · V32 (a session with only warm-up rows checked is NOT complete) · V38/V40 (the crew weekly ring = the week's daily pulses, membership as of each day) · V39 (paused days are not "missed" for the comeback rule) · V44 (no second pause may be queued while one is active) · README (postUndone reverses the most recent post of that day; a rollover is the only judge of a missed day). Nothing past T003 starts until this clears.
- OPEN OWNER DECISION (non-blocking until S06): Firebase Auth ⏳ (Appendix B) is unresolved. Per Part XII 12.5 the approved custom auth proceeds by default — Sign in with Apple + email, jose JWTs + crypto.scrypt hashing, Resend reset emails. Nothing may be built against Firebase until the owner decides.
- PROCESS: `git init` is blocked by the owner's user-locked hook, so no commit has been made by the agent (S01 + S02). The owner runs `git init` and the commit sequence from the S02 handoff message; after that the loop commits normally.
- (resolved 2026-09-04) SPECIFICATION GAPs G1–G12 — answered by the owner, logged in Appendix A ("Gamification/Build — gap resolutions 2026-09-04"), applied to spec-constants.json + design-tokens.json, regenerated, drift check green.

## Notes for next session

- After the 🛑 clears: S03 = T004–T005 (seed exercises ~80 + plan templates incl. "Some" = 5 exercises at 3×8–10 per G7), each ending at its own 🛑. generate.mjs then gains SeedData.swift + seed.ts emission (deliberately not written yet — C5).
- Plan notes (5.6 map / 5.2 tree additions, all recorded here so no chat history is needed): shared/scripts holds 7 files (generate · check-drift · render-spec-constants · render-ember · check-vectors · vector-shapes · vector-invariants) to honour the C9 150-line cap; Generated/ gains EmberTokens.swift (spacing, spring, haptic names from G5/G8); the vectors imply Post.isPlannedDay (stamped at creation) and GamificationState.earnedAchievementIds (Part IX additions for T009), recompute(…) gains an asOfDayKey parameter, and T032 needs crewPulse / crewWeeklyRing / comebackBanner / validatePauseRequest twins — names to confirm at T020/T032 plan time.
