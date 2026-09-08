# Crew — owner review (regenerated after the cold-start audit, 2026-09-08 evening)

Read this first on a cold resume. It replaces the 2026-09-04 review in full. Every state below was produced by a command run
on this Windows machine on 2026-09-08, or read from GitHub with `gh run view` — never carried over from an earlier claim.
`docs/progress.md` is the ledger (rewritten from scratch the same evening, with the audit's command table at the top and the
gap-closure queue), `docs/ratification.md` R-001 … R-055 holds every self-review and gap call (R-055 is the audit itself),
`docs/debt.md` every compromise, `docs/testing-without-a-mac.md` the owner's route from Windows to an iPhone.

## 1. The four states

- ✅ **DONE-VERIFIED** — the verify command ran here today and passed (or `gh run view` read a green job today)
- 📝 **WRITTEN-UNVERIFIED** — Swift app code. No Mac here. GitHub's macOS job compiled it, ran 49 unit tests and journeys ①②
  on an iPhone 17 simulator (run 34252964640, green) — but nothing has run on a phone: gestures, haptics, camera, push,
  offline, VoiceOver, Dynamic Type are unproven
- 🔌 **BLOCKED-CREDENTIALS** — needs a vendor value or an account step only the owner can do
- ❌ **NOT DONE** — nothing exists for it yet

## 2. Completion matrix, T001–T047

| Task | State | Evidence today / what is missing |
|---|---|---|
| T001 spec-constants | ✅ | generate + check-drift clean |
| T002 generate + check-drift | ✅ | same; working tree unchanged after generate |
| T003 vectors (51) | ✅ | check-vectors; `npm run vectors` 51/51; docker swift test 25/25; owner-ratified R-001 |
| T004 exercises.json | ✅ | check-seeds |
| T005 plan-templates.json | ✅ | check-seeds |
| T006 achievements + api.md | ✅ | check-seeds; achievements.test.ts + V45–V50; the api.md `POST events` route now exists (audit gap Q03) |
| T007 monorepo scaffold | ✅ | web typecheck/lint/build; ios project generated + built by the CI ios job |
| T008 CI + doctrine lint | ✅ | `gh run view 34252964640`: five jobs green; doctrine-lint clean (132 Swift files); codemagic.yaml deleted |
| T009 db + indexes | ✅ | db.test.ts |
| T010 server auth | ✅ | auth.test.ts |
| T011 email + reset | ✅ | auth-reset.test.ts (Resend behind the outbox) |
| T012 Sign in with Apple | ✅ server + web (auth-apple.test.ts) · 🔌 the real Apple round-trip (Services ID, bundle id, a device) |
| T013 iOS shells | 📝 | CI: ShellStatesTests green on the simulator |
| T014 SyncQueue | 📝 | CI: SyncQueueTests 9 green |
| T015 standing checks | ✅ | 139 generated checks green (every route under app/api/v1, events included) |
| T016 DayKey twin | ✅ | V05–V10 both engines; NEW unit files both engines (audit Q06) |
| T017 engine streak + XP | ✅ | 51/51 TS; 51/51 Swift (Linux + Xcode) |
| T018 shields + pause | ✅ | same |
| T019 completion/undo/edit | ✅ | same — the "both engines" gate holds |
| T020 PlanGenerator + SwapFinder | ✅ | property tests both engines |
| T021 Onboarding S02–S04 | 📝 | CI journey ① walks them; screenshots reviewed R-052/R-053 |
| T022 Save/auth S05 | 📝 | CI journey ① saves with email |
| T023 plans/sessions/sync API | ✅ | plans/sessions/sync tests incl. the iPhone batch replay |
| T024 Home S07 | 📝 | CI: HomeModel tests; bridge + post-state screenshots |
| T025 Session S09 | 📝 | CI: SessionModel tests; journey ② logs 3/3 |
| T026 Celebration + Posts API | ✅ API + web (posts.test.ts; e2e ④) · 📝 iOS |
| T027 Nutrition + blob | ✅ API + web (photos.test.ts EXIF fixture; e2e ①) · 📝 iOS (+ NEW CameraDeniedTests probe) |
| T028 🛑 Journey ① | ✅ on the CI simulator and on web · ❌ on a device · owner ratification of R-022/R-053 pending |
| T029 Crews API | ✅ | crews.test.ts (mute now covered — audit Q04) |
| T030 Messages/Reactions API | ✅ | messages.test.ts |
| T031 Crew feature iOS | 📝 | CI journey ② sees the reaction; MessageRow/CreateCrewScreen split into their own files |
| T032 crew engine rules | ✅ | V37–V40 both engines |
| T033 Notifications | ✅ route + apns2 lib + eligibility + cron tests · 🔌 a push to a device (APNs key + phone) |
| T034 Moderation | ✅ | moderation.test.ts |
| T035 🛑 Journey ② + 8.7 | ✅ web ② + the 8.7 items runnable here · 📝 iOS ② (CI simulator green) · ❌ device items |
| T036 Web onboarding | ✅ | build; e2e ① (three viewports) |
| T037 Web session + posting | ✅ | e2e ④ |
| T038 Web crew + landing | ✅ | e2e ③ |
| T039 🛑 Playwright + Lighthouse | ✅ e2e matrix (see §3 for today's run) + token parity · 🔌 Lighthouse (`@lhci/cli` needs your approval — debt) |
| T040 Progress + Journal | ✅ web · 📝 iOS |
| T041 Settings/pause/export/delete | ✅ routes + web (account.test.ts) · 📝 iOS |
| T042 Edge screens | ✅ web (welcome-back, lapsed-user tests) · 📝 iOS |
| T043 A11y/offline/perf | ✅ web substitute audit · ❌ Xcode a11y audit, VoiceOver, Dynamic Type XXL, Reduce Motion, 8.6 offline matrix, device signposts · 🔌 axe-core/Lighthouse (dependencies) · 📝 NEW Resume-after-kill + camera-denied probes |
| T044 🛑 Security sweep | ✅ everything runnable (standing 403s, audit 0, EXIF, cascade, rate limits; harness isolation fixed today) · ❌ device items · ratification pending |
| T045 TestFlight + beta + metrics | ✅ metrics (`npm run metrics`, tested) · 🔌 TestFlight (Admin App Store Connect key, Team ID, bundle id, deployed host) |
| T046 Production env | 🔌 Atlas/Resend/Blob values exist in your local `web/.env` (never printed, never committed); whether the Vercel deploy exists is unknown from here — report the host; monitoring/backups/rotation deferred (debt) |
| T047 🛑 App Store | ❌ needs a TestFlight build first; the registry audit (R-040) and the launch checklist (§6) are done |

## 3. Proof — commands run 2026-09-08 (evening)

| Command | Result |
|---|---|
| `node shared/scripts/generate.mjs && node shared/scripts/check-drift.mjs` | clean, tree unchanged |
| `node shared/scripts/check-vectors.mjs` · `check-seeds.mjs` · `doctrine-lint.mjs` | 51 vectors · seeds consistent · 132 Swift files clean |
| `web: npm run typecheck` · `npm run lint` | clean · clean |
| `web: npm test` | before the audit 28 files / 285 tests; after it 31 files / 309 tests (events 4, validators 7, day-key 9, mute 1, standing checks +3) — green |
| `web: npm run vectors` | 51/51 |
| `web: npm run build` | green |
| `web: npm audit --audit-level=high` | 0 vulnerabilities |
| `web: npm run e2e` | first run of the day: 22 passed · 1 skipped · 1 FAILED (journey ① phone-375 hydration flake; passed alone). After the helper fix: see the last line of `docs/progress.md` "Audit evidence" for the re-run |
| `docker run … swift:5.10 swift test` | 25 tests, 0 failures (18 + the 7 new DayKey cases) |
| `gh run view 34252964640` | contracts ✓ web ✓ web-e2e ✓ ios-engine ✓ ios (macOS: build, unit + vectors, journeys ①②) ✓ |

## 4. What the audit changed (R-055)

- **Server**: `POST /api/v1/events` built and tested (api.md had promised it since R-004); `PATCH crews/[id]/mute` gained its
  test. Every other route already existed and was tested — the "server unfinished" impression came from somewhere else.
- **Web**: the onboarding funnel (hero → days → experience → plan built → saved) is recorded and flushed after sign-up, so
  the 1C "hero → Home ≤ 90 s" reading exists in the `events` collection.
- **Tests**: 8.3 validators (every input limit) and DayKey unit tests on both engines; the Playwright helper no longer flakes on
  a pre-hydration fill.
- **Hygiene**: the Playwright harness pins every vendor key to empty (a local `.env` with real keys could have reached it);
  the stray `ios/.env` and the never-run `codemagic.yaml` are gone; `.env.example` gained `APP_STORE_URL`; MessageRow and
  CreateCrewScreen live in their own files (C10); two 8.4 probes (camera-denied, Resume-after-kill) wait for their first CI run.

## 5. Everything ratifiable — the gap calls that need your yes

Unchanged from the 2026-09-04 review, all still tagged `// GAP:` in code and logged in `docs/ratification.md`: reactions on
posts only (R-023) · achievements by a separate pass (R-037) · swap keeps the row's targets (R-016/R-034) · server-clock window
7 days back / 5 min forward (R-018) · holds count in x/y (R-018) · photo pipeline + unguessable keys (R-020) · web reminder
in-app only (R-031) · progress spans 12/8 weeks (R-033) · welcome-back per quiet spell (R-034) · stale session two choices
(R-034) · iOS S14 editor built without a ledger task (R-034) · empty states as h1 (R-035) · dev-only substitutes (R-005 …) ·
mid-workout swap helper + 15 s rest step (R-038) · metrics denominators (R-039) · the phone's replay contract (R-043) · the
GAP constants (R-044) · fresh-phone hydration (R-046) · the sync driver (R-045) · the XCUITest seed (R-046) · S03 day circles
inscribed in the column (R-052) · **new today**: the funnel event names and the auth-only events route (R-055).

Open owner decision: Firebase Auth ⏳ (Appendix B) — custom auth proceeded by default; nothing built against Firebase.

## 6. The ordered ship path (one step per message from the agent; real values never in the repo or the chat)

1. **Commit and push the audit.** `& "C:\Program Files\Git\bin\bash.exe" C:/Users/princ/CREW_2.0/docs/commit-queue.sh` then
   `git push` — blocks F08–F13. CI runs the two new UI probes for the first time; if one fails, the agent reads the job log
   with `gh api` and fixes it (behaviour never changes to make a test pass).
2. **Report the Vercel host** (or say it is not deployed yet). The agent curls `/api/v1/users/me` (401) and `/` (200), then
   runs Playwright against production. Until then T046 stays 🔌.
3. **Rotate Resend and Blob** (you said you would): new values into Vercel's environment, redeploy, and update your local
   `web/.env`; nothing in the repo changes.
4. **Apple**: accept the updated Program License Agreement; Team ID + APNs key into Vercel (`APNS_*`, `APNS_ENVIRONMENT=
   production`); an **Admin** App Store Connect API key; GitHub secrets/variables per `.github/workflows/testflight.yml`.
5. **Actions → testflight → Run workflow** (build number 1). Install from TestFlight.
6. **Device pass** on your iPhone: journeys ① and ② by hand; the 8.6 offline matrix (§7); one push; one photo; VoiceOver
   through a session; Dynamic Type XXL on Home / Session / Crew; Reduce Motion on the celebration. Tick each in
   `docs/progress.md` (T028, T035, T043 flip from 📝/❌ to ✅), one commit each.
7. **Gate ratifications**: R-015 (Phase 1), R-022/R-053 (Phase 2), R-027 (Phase 3), R-032 (Phase 4), R-036 (Phase 5), plus
   the §5 list — a "no" on any gap call is a small local change.
8. **Production tier** when a second tester exists: Vercel Pro (cron back to `* * * * *`), Atlas M10+ with backups and a
   real allowlist, a verified Resend domain, log drains and alerts (debt entries name each).
9. **App Store (T047)**: bundle id, capabilities, privacy labels, EULA link, 13+, review notes with a test account and an
   invite link, screenshots; final audit `node shared/scripts/doctrine-lint.mjs` + `grep -rn "GAP:" web/src ios/Crew`.

## 7. The 8.6 offline matrix — first device pass checklist

Airplane mode: view plan · full session · complete + celebration (local engine) · post queued with chip · reconnect →
auto-send, silent reconcile · chat draft held · kill mid-queue → nothing lost (the simulator half of this is now
`OfflineSessionTests`) · 24 h failed upload → Retry / Post without photo / Delete.

## 8. Production notes (T046) — decisions, not steps

Unchanged: Atlas continuous backup + a restore drill before launch · Vercel log drain + 5xx alert, Atlas alerts · `JWT_SECRET`
rotation expires access tokens within 15 min while refresh tokens (server-side records) survive · `CRON_SECRET` rotates in
Vercel and `vercel.json` together · APNs/Resend/Blob keys rotate at the provider, redeploy, one smoke each · photos under
unguessable keys, deleted by the account cascade; the JSON export is the user's copy; nothing is aggregated beyond Part IV.
