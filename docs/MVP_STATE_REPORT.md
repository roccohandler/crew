# Crew — MVP state report

Read-only audit of the repository at commit `7fa7e52` (master, 126 commits), 2026-09-17. Judged against
`docs/crew-mvp-spec.md` ("Version 2.0 — Implementation-Ready Edition · APPROVED 2026-09-04", line 2; 1,568 lines,
Appendices A–C through amendment A19 of 2026-09-11). Every claim cites `file:line` or a command run on this Windows
machine with its output; anything not determinable is marked UNKNOWN. No source file was modified.

## 1. Repo map

| Area | Files | Lines | Notes |
|---|---|---|---|
| `ios/Crew` (app) | 156 Swift | 11,380 | `find ios/Crew -name "*.swift" \| xargs cat \| wc -l`; 4 of those are Generated/ (SpecConstants 445, EmberColors 57, EmberTokens 54, SeedData 20) |
| `ios/CrewTests` + `ios/CrewUITests` | 28 + 9 Swift | 2,941 | unit/vector tests + XCUITest journeys |
| `web/src` | 185 files | 10,772 | Next.js app: `app/` (18 pages, 34 `route.ts`), `components/` (45), `lib/` (55 + `lib/engine/` 22), `generated/` (3) |
| `web/tests` | 59 files | 4,239 | `api/` (28), `engine/` (16), `e2e/` (9), root vectors/contrast/token-parity/birth-year |
| `shared/` | 27 files | 3,395 | `spec-constants.json` (192 named constants), `design-tokens.json`, 9 vector files (V01–V55, 56 vectors), 3 seed files, 9 scripts |
| `docs/` | 15 files | 7,574 | spec, progress, debt, ratification, api, 6 plan docs, `commit-queue.sh` (the owner's git gate) |

Top level: `CLAUDE.md`, `.github/workflows/{ci,testflight}.yml`, `docs/`, `ios/`, `shared/`, `web/` (`ls -la`). iOS targets
(`ios/project.yml:16-100`): `Crew` (app, iOS 17.0, iPhone only, portrait), `CrewTests` (unit + vectors), `CrewUITests`; schemes
`Crew`, `CrewUITests`, `CrewAll` (CI). No `Crew.xcodeproj` is committed; XcodeGen generates it. `ios/Package.swift` builds
`Engine/` + `Generated/` + `ApiModels.swift` as a SwiftPM package for Linux/Windows vector runs (`ios/Package.swift:12-23`).

Last 15 commits (`git log -15 --date=short`):
```
7fa7e52 2026-09-16 fix(auth): the birth-year check accepted numbers its own message says it will not …
6dba336 2026-09-16 fix(test): the last three UI failures, diagnosed from the xcresult …
09e1960 2026-09-16 fix(test): five failing tests on the first ios run since 2026-09-10 …
3786306 2026-09-16 fix(ios): F45 committed Build B's HomeScreen, HomeModel and HomeStatesTests inside Build A …
983ff87 2026-09-14 fix(ios,web): A20 Build A — master's five red UI tests, and the four staleness bugs …
2b5e904 2026-09-11 fix(ios): HomeTestFixtures forwarded days as [Int] into PlanGenerator.generatePlan …
0c81950 2026-09-11 fix(ios): SettingsModel.endPause referenced userId as though it were a property …
cb84202 2026-09-11 feat(ios): A19 Stages A/B/D — the bottom anchor becomes real …
14e6c02 2026-09-11 feat(home): A18 — Home answers the four questions it was raising …
2c73e20 2026-09-11 docs(spec): A18 and A19 enter the Decision Registry …
d1f8c42 2026-09-11 feat(ci): a green CI run on master now builds to TestFlight by itself …
334ad67 2026-09-10 docs(ci): record what the green run actually measured …
91c9604 2026-09-10 perf(ci): revert the build/test split — it made the ios job 86% SLOWER …
d362f8b 2026-09-10 perf(ci): the ios job compiled the 151-file app TWICE …
5ed403b 2026-09-10 feat(home): A17 — Home says what it is …
```

Third-party dependencies. Web runtime (`web/package.json:23-34`): `next` 16 (app + API), `react`/`react-dom` 19, `mongodb` 7
(`lib/db.ts`), `zod` 4 (`lib/validate*.ts`), `jose` 6 (JWT sign/verify `lib/auth.ts:5`, Apple JWKS `lib/apple-auth.ts:4`),
`sharp` (EXIF strip/resize `lib/blob.ts:8`), `@vercel/blob` (`lib/blob.ts:7`), `apns2` (`lib/push.ts:5`), `resend` (`lib/email.ts:5`).
Dev (`:35-46`): `@playwright/test`, `vitest`, `mongodb-memory-server` (real Mongo in tests), `eslint` + `eslint-config-next`,
`prettier`, `typescript`, three `@types/*`. All ten runtime packages are on the spec allow-list (spec 5.2 "Allowed npm
dependencies"); the four extra dev packages are logged in Appendix A ("dev-only tooling additions 2026-09-04").
**Swift: zero third-party dependencies** — `ios/Package.swift` declares none (`grep dependencies` → only the internal test
dependency, line 22) and every `import` in `ios/` is an Apple framework (`grep -rh "^import" ios | sort | uniq -c`:
Foundation, SwiftUI, XCTest, Observation, SwiftData, UIKit, AuthenticationServices, AVFoundation, UserNotifications, Security,
SafariServices, PhotosUI, OSLog, Network, Charts). Nothing to flag.

## 2. Build & CI state

**iOS build here: not possible.** `xcodebuild` and `xcodegen` are not installed (`command not found`); Docker Desktop's daemon
is down (`docker run … swift:5.10` → "failed to connect to the docker API"). What ran on this machine:

| Check | Result |
|---|---|
| `node shared/scripts/check-drift.mjs` | all 7 Generated files match `shared/`, exit 0 |
| `check-vectors.mjs` | 56 vectors across 9 files — shape and invariants hold |
| `check-seeds.mjs` | 15 achievements · 110 exercises (86 strength, 15 mobility, 9 cardio) · 45 template lists |
| `doctrine-lint.mjs` | clean — 194 Swift files, 1 hand-written CSS file |
| `swift-xref.mjs` | 194 Swift files, 379 types, clean |
| `cd ios && swift test` (local Swift 6.3.3 for Windows) | 76 tests, 0 failures (engine package only: vectors, DayKey, PlanGenerator, SwapFinder, rotation, units, prefill …) |
| `web: npm run typecheck` / `npm run lint` | exit 0 / exit 0 |
| `web: npm test` | 43 files, 453 tests passed, 93 s (in-memory MongoDB) |
| `npm run e2e`, `npm run build` | not run here (CI evidence below) |

CI (`gh run view 35136653697`, the push of `7fa7e52`, all five jobs green): contracts 9 s · ios engine (Linux, `swift:5.10`
container) 37 s, `Executed 76 tests, 0 failures` · web 1m21s, `Test Files 43 passed` · ios 15m1s — `CrewTests` `Executed 140
tests, 0 failures`, `CrewUITests` `Executed 9 tests, 0 failures (440 s)` on simulator "iPhone 17" · web e2e 3m33s, `32 passed,
1 skipped`. Test counts by area: web API/engine/unit 453 · web e2e 33 (32 + 1 skipped by design) · Swift engine 76 (Linux) ·
iOS unit + vectors 140 (Xcode) · iOS UI journeys 9.

CI configuration: `.github/workflows/ci.yml` — trigger `push` to master/main + `pull_request` (lines 5-8); jobs `contracts`
(generate/drift/vectors/seeds/doctrine/swift-xref), `web` (npm audit --audit-level=high, lint, typecheck, test, vectors, build),
`web-e2e` (Playwright, chromium + webkit, 375/768/1280), `engine-swift` (Linux), `ios` (macos-latest, `brew install xcodegen`,
one `xcodebuild test -scheme CrewAll`, 45-minute timeout, xcresult uploaded always). **Xcode version is not pinned** — the runner
is `macos-latest` (line 67) and the job log shows `/Applications/Xcode_26.6.app`. Signing: simulator builds are signed ad hoc
(`CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO`, lines 120-121); TestFlight uses automatic cloud
signing through an App Store Connect API key (`testflight.yml:73-91`, `ios/ExportOptions.plist`: method `app-store-connect`,
destination `upload`, `signingStyle automatic`, `testFlightInternalTestingOnly true`). **Tests run before upload: yes** —
`testflight.yml:30-33` triggers on `workflow_run` of `ci` and line 42-44 requires `conclusion == 'success' && head_branch ==
'master'`; a manual `workflow_dispatch` bypasses that gate (line 43). Version/build: `MARKETING_VERSION 0.1.0`,
`CURRENT_PROJECT_VERSION 1` (`project.yml:57-58`); the build number is overridden with the commit count (`testflight.yml:56-60`).
Latest upload: run 35138227492 logged `Build 126 from 7fa7e52` (TestFlight build 126, version 0.1.0). Note `ci.yml:87` still
says a green run is "6–7½ minutes"; the last three ios jobs took 15m1s, 15m52s and 11m31s (`gh run list`).

Part XII session schedule (S01–S34), judged from code + CI evidence (progress.md is not the source of these verdicts):

| Session | Tasks | Verdict | Evidence |
|---|---|---|---|
| S01–S04 | T001–T006 | complete | drift/vectors/seeds clean above; `docs/api.md` exists; owner ratifications in Appendix A |
| S05 | T007–T008 | complete | five CI jobs green; doctrine lint CI-blocking (`ci.yml:20-25`) |
| S06 | T009–T010 | complete | `lib/db.ts` unique indexes 58-84; `tests/api/auth.test.ts`, `db.test.ts` in the 453 |
| S07 | T011–T012 | partial | reset flow tested (`auth-reset.test.ts`); Apple verified against a local JWKS (`auth-apple.test.ts`); real Apple round-trip UNKNOWN (no `APPLE_*` env, `lib/apple-auth.ts:31` returns 401 when unset) |
| S08–S09 | T013–T015 | complete on CI | `ShellStatesTests`, `SyncQueueTests` in the 140; `standing-checks.gen.test.ts` |
| S10–S12 | T016–T020 | complete | 56 vectors green on TS (npm test) and Swift (76 local + CI) |
| S13 | T021–T022 | partial | screens exist; **the iOS "I have an invite" path is unbuilt** (§6); journey ① green on simulator only |
| S14 | T023 | complete | `plans.test.ts`, `sessions.test.ts`, `sync.test.ts` |
| S15 | T024 | partial | Home at A20 Build A; **A20 Build B is not in the repo** (§8, §12) |
| S16 | T025 | partial | Session screen complete in code; never run on a device (progress.md "WRITTEN-UNVERIFIED") |
| S17 | T026–T027 | partial | posts/photos APIs tested; **iOS share toggle is inert** (`SessionScreen.swift:62` posts with `shareToCrew: true` before `CelebrationScreen.swift:40` shows the toggle) |
| S18 | T028 | partial | journey ① green on CI simulator + web; no device run |
| S19 | T029–T030 | complete | `crews.test.ts`, `messages.test.ts`, `moderation.test.ts` |
| S20 | T031 | partial | Crew screen complete; no join-by-link on iOS (§6) |
| S21 | T032–T033 | partial | V37–V40 green; **iOS never registers a push token or asks permission** (§4) |
| S22 | T034 | complete (server) | clients report posts only (§9) |
| S23 | T035 | partial | journey ② green on simulator; 8.7 items runnable locally green; no device |
| S24–S26 | T036–T038 | complete | e2e ①②③④ 32 passed on 375/768/1280 |
| S27 | T039 | partial | token-parity test exists; **no Lighthouse** (`debt.md` 2026-09-04 T039) |
| S28–S29 | T040–T042 | partial | both platforms have the screens; Journal is a pushed screen not the A19.4 segment (`ProgressScreen.swift:37-38`) |
| S30 | T043 | partial | hand-rolled a11y sweep (`tests/e2e/a11y.spec.ts`), no axe-core, no 8.9 snapshot matrix, no offline device matrix |
| S31 | T044 | partial | standing 403 checks + npm audit; open items in §9 |
| S32 | T045 | partial | TestFlight auto-ships; `scripts/metrics.mjs` exists; Blob/APNs/Apple credentials absent (`web/.env.example`; progress.md T045/T046) |
| S33 | T046 | partial/blocked | Vercel Hobby cron once a day (`web/vercel.json:3`), Atlas M0 open allowlist, unverified Resend domain (`debt.md` 2026-09-08 T046) |
| S34 | T047 | untouched | progress.md:623 "NOT STARTED"; `/privacy`, `/terms` are placeholders (`web/src/app/privacy/page.tsx:9`) |

## 3. Data model

Server collections (`web/src/lib/db.ts:37-53` getters; shapes in `documents.ts`, `documents-auth.ts`, `documents-social.ts`):

| Collection | Fields (source) | Notes |
|---|---|---|
| users | `_id email emailLower authProvider appleSub? passwordHash? displayName profilePhotoKey units weightUnit? distanceUnit? timezone reminderTime notificationPrefs? welcomeBackAckDay? eulaAcceptedAt createdAt deletedAt?` (`documents.ts:16-35`) | `deletedAt` is declared but **never written** (`account-delete.ts:32` deletes the document outright; `grep deletedAt lib/users.ts lib/account-delete.ts` → none). `eulaAcceptedAt` written once, never read. `units` is a legacy mirror of `weightUnit` (`users.ts:18`) |
| plans | `_id userId(UNIQUE) trainingWeekdays[] workouts[{kind name exercises[{exerciseId name pattern equipment type targetSets targetReps targetRepsMax? targetWeight? holdSeconds? perSide? order}]}] updatedAt` (`documents.ts:40-68`) | `targetWeight` has **no writer** (`grep targetWeight lib/engine/plan-generator.ts` → none; iOS `PlanLocal.swift:17` writes `nil`); read only by prefill |
| sessions | `_id clientId(UNIQUE) userId dayKey status workoutName workoutKind isPlannedDay startedAt completedAt timezone exercises[{… skipped sets[{targetReps actualReps weight holdSeconds distanceMeters weightUnit? isWarmup done asPlanned}]}] updatedAt` (`documents.ts:70-109`) | |
| posts | `_id clientId(UNIQUE) userId type(workout\|cardio\|meal\|text) sessionId photoKey caption mealTag crewId dayKey isPlannedDay workoutCompleted earlierToday summary? createdAt deletedAt` (`documents-social.ts:6-27`) | `cardio` is a display type mapped to `workout` for the engine (`gamification-store.ts:34`) |
| crews / crewMemberships | `name emoji captainId inviteToken(UNIQUE) createdAt archivedAt`; membership `crewId userId(UNIQUE) joinedAt joinedDayKey mutedAt` (`:29-46`) | one crew per user is the unique index (`db.ts:73`) |
| messages / reactions | `clientId crewId userId kind(message\|system) body createdAt deletedAt`; reaction `targetType targetId userId emoji dayKey createdAt` UNIQUE per user-target (`:48-67`) | |
| gamificationStates | `userId(UNIQUE) currentStreak longestStreak totalXP level shields lastCountedDayKey earnedAchievementIds recomputedAt` (`:69-80`) | `recomputedAt` written (`gamification-store.ts:43`), never read |
| pauses / reports / blocks | `startDay endDay`; report `targetType targetId reporterId reason status(open\|resolved) createdAt`; block `blockerId blockedId` UNIQUE (`:82-105`) | report `status` is only ever `"open"` — no route or script sets `resolved` (`grep resolved web/src` → the schema and an email sentence, `email.ts:68`) |
| refreshTokens / passwordResets / pushTokens / events / photos | (`documents-auth.ts:5-54`) | `replacedByHash` written (`refresh-tokens.ts:50`) never read; `receivedAt` written (`events.ts:28`) never read; `pushTokens.platform` always `"ios"` |
| rateLimits, emailOutbox, pushOutbox, notificationLog | created ad hoc outside `db.ts` (`rate-limit.ts:19`, `email.ts:19`, `push.ts:17`, `notification-facts.ts:23`) | not in the `db.ts` index list; `notificationLog` is deleted in the account cascade, the outboxes are not |

iOS SwiftData models (`ios/Crew/Storage/Models.swift`, `ModelsSocial.swift`, `SyncQueue.swift:20-41`): `LocalPlan → LocalWorkoutTemplate →
LocalExerciseTemplate`, `LocalSession → LocalSessionExercise → LocalSetLog`, `LocalPost` (adds `serverId localPhotoPath deliveredAt
summary`), `LocalGamificationState` (adds `engineStateJSON`), `LocalPause`, `LocalCrewSnapshot` (stream/members as JSON blobs),
`OpRecord` (queue). Write-only fields: `LocalSession.syncedAt` (set `ServerHydrate.swift:106`, never read — the only `syncedAt`
read is the crew snapshot's, `Store.swift:115`), `OpRecord.lastError` (set `SyncQueue.swift:178/189`, never displayed).
No SwiftData migration exists; an unopenable store is deleted and re-hydrated (`Store.swift:25-36`, `debt.md` 2026-09-09 A1).

Entities asked about: **user** (above, plus `PublicUser` `users.ts:12-26`), **crew** (above), **post** (above), **workout** = a `sessions`
document with an embedded workout snapshot, plus the `plans` template, **nutrition** = a `posts` document of type meal/text with
`photoKey`, `mealTag`, `caption`, `earlierToday` — no numeric nutrition fields exist anywhere (A16 not built; `find … -iname "*macro*"` → none).

## 4. Feature inventory

Status: DONE / PARTIAL / STUB / MISSING. Evidence is one location per cell; "server" means the API exists and is tested.

| Feature | iOS | Web |
|---|---|---|
| Onboarding / plan selection | DONE — `OnboardingFlow.swift:20-56` hero → 3 questions → reveal → save; swap `GeneratedPlanScreen.swift:48-55`; draft survives abandon `DraftStore.swift` | DONE — `onboarding/OnboardingFlow.tsx:35-92`, localStorage draft `:46-50` |
| Auth (email + Apple + reset) | DONE — `SaveAuthScreen.swift:27-39`, `LoginScreen.swift`, Keychain `AuthStore.swift:32-55`; Apple round-trip on a real device UNKNOWN | PARTIAL — email login/register/reset DONE (`LoginForm.tsx`, `ResetForm.tsx`); Apple is a redirect flow whose failure path redirects to `/save?apple=failed`, a route that does not exist (`auth/apple/callback/route.ts:48`; `find web/src/app -name save` → none) |
| PPL weekly plan (A1 rotation) | DONE — `PlanScreen.swift`, `PlanRotation.swift`, editor `WorkoutEditorScreen.swift`, days `DaysSheet.swift` | DONE — `WeekOverview.tsx`, `WorkoutEditor.tsx`, `ExerciseSheet.tsx` |
| Workout logging (sets/reps, optional weight) | DONE — `SessionScreen.swift`, `SetRow.swift`, weight tape `WeightTape.swift`, prefill `SessionActions.swift:30-38`, quick complete `SessionActions.swift:109-114` | DONE — `SessionLogger.tsx`, `SetRow.tsx` (number input instead of tape, `SetRow.tsx:32-38`) |
| Accessory / mobility blocks | DONE — `MobilityHoldRow.swift` countdown + auto-check; cardio block `CardioRow.swift` | DONE — `HoldRow.tsx`, `CardioRow.tsx` |
| Nutrition / protein logging | PARTIAL by spec — photo/text meal posts DONE (`NutritionPostScreen.swift`, `PostComposer.swift`); no protein/macro numbers (A16 gated, not built) | same — `PostComposer.tsx` |
| Daily posts (workout → post, meal → post) | DONE — `SessionActions.swift:95-101`, `PostModel.swift:58-75`; offline queue `SyncQueue.swift` | DONE — `sessions.ts:81-91`, `PostComposer.tsx:35-46` |
| Crews: create / invite / join | PARTIAL — create + share link DONE (`CreateCrewScreen.swift`, `InviteScreen.swift:19`); **join by link MISSING**: `Api.joinCrew` is called only with a token that is never set (`OnboardingModelAuth.swift:93`; `grep "invitedCrew =\|onOpenURL" ios/Crew` → none; `CrewModel.join(token:)` has no caller) | DONE — landing `join/[token]/page.tsx`, `JoinButton.tsx`, `CrewInvitePanel.tsx` |
| Crew surface (feed vs chat) | DONE as ONE unified stream — see the paragraph below | DONE — `CrewView.tsx`, `StreamList.tsx`, `CrewHeader.tsx` |
| Reactions / comments | DONE reactions (5 emoji, un-react) `PostCard.swift:46-53`, `CrewModel.swift:111-126`; comments intentionally absent (chat is the comment section) | DONE `StreamList.tsx:32-36` |
| Streaks / progress | DONE — engine twins vector-green; `HomeHeader.swift`, `ProgressScreen.swift`, `JournalScreen.swift`, Swift Charts `ExerciseChartView.swift` | DONE — `progress/page.tsx`, `journal/page.tsx`, `HeatMap.tsx` (strength trend as text, no chart) |
| Notifications — push | STUB — server DONE (`push.ts`, `cron/notifications/route.ts`, eligibility tests); **iOS never calls `registerForRemoteNotifications`, never calls `requestAuthorization`, never calls `Api.registerPushToken`** (`grep -rn` → 0 hits outside the Api definition `ApiSettings.swift:111`); the rest-timer chime only fires if already authorized (`RestTimer.swift:45-46`), which nothing ever asks | N/A by spec (`NotificationRows.tsx:37` "Push isn't on web yet") |
| Notifications — in-app | PARTIAL — offline/sync banner `ErrorState.swift:33-73`; no in-app indicator for crew activity | MISSING — no unread/indicator code (`grep -i "unread\|indicator"` → comments only) |
| Settings | DONE — `SettingsScreen.swift` (profile, pause, units, toggles, mute, blocked, legal, export, log out, delete, version) | DONE — `SettingsView.tsx` (+ timezone picker) |
| Account deletion | DONE — `SettingsModel.swift:121-127` → `DELETE users/me` cascade `account-delete.ts` (gaps in §9) | DONE — `SettingsView.tsx:52-61` |
| Reporting / moderation | PARTIAL — report + block a post's author from a long-press (`PostCard.swift:47-53`); reason is fixed text (`CrewModel.swift:131`); messages/crew-name/user reports have no UI; blocked-people list DONE | PARTIAL — `PostMenu.tsx`; same limits |
| Analytics events | PARTIAL — server logs 30+ event names on mutations (`grep logEvent(`); web funnel steps `onboarding_hero/days/experience/plan_built/saved` (`lib/funnel.ts`, `OnboardingFlow.tsx:56,77,87-88`); **iOS sends no client events** (`grep -rn "events\|Funnel" ios/Crew` → one comment) though `POST events` accepts `X-Crew-Client: ios` | PARTIAL (funnel only) |

The crew surface, exactly: one screen per platform. Header pinned at the top with crew name + emoji and the pulse
("4/5 today" or "No posts yet today", `MemberStrip.swift:13`), a horizontal member strip (avatar, posted-dot, streak or ⏸,
`CrewStrip.swift`), a crew-of-one invite card until two members (`CrewOfOneCard.swift`), then ONE time-ordered scrolling
stream mixing post cards, chat lines and system lines ("X joined the crew", `crews.ts:55`) over a 7-day window
(`crew-stream.ts:66-82`), anchored at the bottom like a chat (`CrewScreen.swift:73`), and a text composer that appears only
with ≥ 2 members (`CrewScreen.swift:74`, `CrewView.tsx:84`). A user can: send a message (queued offline), long-press a post
(iOS) or tap React (web) to add/remove one of 🔥💪👏😂❤️, report a post, block its author, open Invite (share sheet, copy
link, regenerate link, remove members — Captain only), leave. A user cannot: delete a message, rename the crew, react to
a message, reply, or scroll past 7 days — the server supports message delete and rename (`crews/[id]/messages/[messageId]`,
`PATCH crews/[id]`) but neither client exposes them (`grep deleteMessage( web/src/components web/src/app` → 0; iOS calls no such endpoint).

## 5. Screen inventory

Columns: Loading / Empty / Error state rendered (Y/N/—), then hardcoded colors+fonts count. iOS has 0 color literals and
0 custom fonts outside Generated/ (`grep -rn "Color(red\|#[0-9A-F]{6}\|Font.custom\|.font(.system" ios/Crew` → comments only);
web has 0 color literals outside `generated/` and 3 font literals (`app.css:20` system font stack, `app.css:308` `17px`,
`session/[id]/done/page.tsx:62` inline `fontSize: "2em"`).

iOS (all reached from `RootView.swift:12-24` → `OnboardingFlow` or `MainTabs` five tabs `RootView.swift:29-34`):

| Screen (spec) | Entry point(s) | L | E | Err | Lit. |
|---|---|---|---|---|---|
| IntroScreen (S02) | signed-out root | — | — | — | 0 |
| Days / Experience / Equipment (S03) | hero CTAs; Home empty CTA; Plan "Rebuild"; Welcome back "Rebuild" | — | — | — | 0 |
| GeneratedPlanScreen (S04) | after equipment | Y (`isLoading` button) | — | Y (`:34`) | 0 |
| SaveAuthScreen (S05) | after "Looks good" | Y | — | Y (`:52`, field errors `:134`) | 0 |
| LoginScreen | hero "Log in" | Y | — | Y (`:38`) | 0 |
| SwapSheet | reveal, editor, session | — | N (empty `List`, no copy) | — | 0 |
| HomeScreen (S07) | tab 1 | Y `:24` | Y `:26` | Y `:27` (+ offline `:59`) | 0 |
| SessionScreen (S09) | Home start/resume/bonus | N | — | Y `:61` | 0 |
| CardioLogScreen | Home "Log cardio" | N | — | Y `:46` | 0 |
| CelebrationScreen (S10) | after complete | — | — | — | 0 |
| NutritionPostScreen (S11) | Home meal CTAs, camera, Progress/Journal empty CTA | N | — | Y `:27`, camera-denied `:19-21` | 0 |
| BonusWorkoutSheet, StaleSessionPrompt, FailedUploadSheet, WelcomeBackScreen (S18) | Home sheets/cover (`EdgePrompts.swift`) | — | — | — | 0 |
| PlanScreen (S14) | tab 2 | Y `:28` | Y `:31` | Y `:32` (`.offline` declared `:14`, never assigned `:70-73`) | 0 |
| WorkoutEditorScreen, ExerciseSheet, DaysSheet | Plan row / editor / "Change days" | Y (`ListSkeleton` `:23`) | Y (`emptyLine` `:72`) | Y (`errorLine` on Plan `:63`, DaysSheet `:34`) | 0 |
| CrewScreen (S12) | tab 3 | Y `:33` | Y solo `:34` | Y `:35` + offline `:53` | 0 |
| CreateCrewScreen, InviteScreen (S13) | solo CTA / toolbar Invite | N | — | Y (`CreateCrewScreen.swift:28`) / — | 0 |
| ProgressScreen (S15) | tab 4 | Y `:29` | Y `:30` | Y `:31` (`.offline` never assigned) | 0 |
| JournalScreen (S16) | Progress toolbar "Journal" | N | Y `:38` | N | 0 |
| SettingsScreen (S17) | tab 5 | N | — | N (`SettingsModel.refresh` swallows failure `:32`; row-level `errorLine` only) | 0 |
| EditProfileScreen, PauseScreen, BlockedPeopleScreen, ExportView, LegalPageView | Settings rows | Y/N/N/N/— | —/—/Y `:14`/—/— | Y `:34` / Y `:27` / Y `:24` / Y `:15` / — | 0 |

Web (routes under `web/src/app`; no `loading.tsx`/`error.tsx` anywhere: `find … -name loading.tsx -o -name error.tsx` → none, so
server-rendered pages have no designed loading or error state):

| Page | Entry | L | E | Err | Lit. |
|---|---|---|---|---|---|
| `/` hero | root | N | — | N | 0 |
| `/onboarding` | hero, Home empty, Plan rebuild, Welcome back | Y (`OnboardingClient.tsx:6`) | — | Y (`SaveForm.tsx:70`) | 0 |
| `/login`, `/reset` | hero; email link | Y (busy) | — | Y | 0 |
| `/join/[token]` (W1) | invite link | N | Y dead link `:12-19`, full `:30` | Y (`JoinButton.tsx:22`) | 0 |
| `/privacy`, `/terms` | Settings, signup line | — | — | — | 0 |
| `/home` (S07) | tab | N | Y `:113` | N | 0 |
| `/session/new` → `/session/[id]` (S09) → `/done` (S10) | Home CTAs | N | — | Y (`SessionLogger.tsx:80,89`) / — | 1 (`done/page.tsx:62`) |
| `/log-cardio`, `/post` (S11) | Home rows | N | — | Y (`CardioLogForm.tsx:72`, `PostComposer.tsx:57`) | 0 |
| `/plan` (S14), `/plan/[kind]` | tab; row | N | Y `:18`; Y (`WorkoutEditor.tsx:86`) | Y status line `:55`; Y `:96` | 0 |
| `/crew` (S12–S13) | tab | Y (`CrewView.tsx:72`) | Y solo `:73` | Y `:71` | 0 |
| `/progress` (S15), `/journal` (S16) | tab; Progress link | N | Y `:44`; Y `:22` | N | 0 |
| `/settings` (S17) | tab | partial (`BlockedPeople.tsx:32`) | Y (`:33`) | Y status lines | 0 |

Exists in code but unreachable: web `components/SignInWithAppleButton.tsx` (0 usages; the pages build the Apple href
directly); web client functions `crewPreview`, `renameCrew`, `getPause`, `getSession`, and `deleteMessage` in `api-client*.ts`
(0 callers outside the client files); iOS `Api.registerPushToken` (`ApiSettings.swift:111`, 0 callers); iOS `CrewModel.join(token:)`
(`CrewModel.swift:166`, 0 callers). Every iOS screen type is referenced at least once (per-type `grep -rl` sweep), so no whole screen is orphaned.

## 6. First-run trace

**Organic new user, iOS (cold install, no invite).** Launch → `RootView` sees no Keychain session → `OnboardingFlow` →
`IntroScreen` (three CTAs). "Build my week" → Days (Mon/Wed/Fri pre-selected, `OnboardingModel.swift:24`) → Experience
(auto-advance 250 ms) → Equipment → `regenerate()` builds the PPL draft locally from the bundled seed (`:92-96`) →
`GeneratedPlanScreen` ("Looks good" in the bottom bar) → draft persisted to disk (`acceptPlan` `:132-136`) → `SaveAuthScreen`:
Apple or email (name, email, password, birth year; client mirrors the server's 1900 floor and 13+ gate `:92-99`) →
`finishSignup` `OnboardingModelAuth.swift:80-100`: register → `PUT plans` → local plan written → draft cleared → `RootView`
now signed in → `HomeSkeleton` while `ServerHydrate.pullIfEmptyBounded` runs (bounded wait, `ServerHydrate.swift:60-69`) →
`MainTabs` → Home in **bridge** state (`HomeModel.swift:118`): unlit flame, one CTA "Start your first workout" (training day) or
"Start your streak — post a meal" (rest day, `TodayCard.swift:109-112`) → `SessionScreen` → check sets → "Complete workout" →
`SessionActions.complete` writes the session, the workout post, applies the engine locally and queues `patchSession`
(`SessionActions.swift:85-105`) → `CelebrationScreen` → Home leaves the bridge (a post now exists).
Dead-end / empty / missing-data points: (a) if `PUT plans` fails after auth succeeded, `authError` is shown but the account
already exists and the draft is not cleared — next launch resumes at Save (`OnboardingModel.swift:49-57`), where a second
register returns `emailTaken` (409, `auth/register/route.ts:18`); the user must know to tap "Log in" (UNKNOWN whether the copy
guides them). (b) The rest-day install offers only "post a meal"; with the camera denied the screen falls back to text
(`NutritionPostScreen.swift:19-21`) — no dead end. (c) Everything is optimistic and offline-safe; nothing on this path waits on
the network except signup itself. (d) Notification permission is never requested at any point (§4).

**Organic new user, web.** `/` → `/onboarding` (same three questions, client-side plan, localStorage draft
`OnboardingFlow.tsx:46-50`) → `SaveForm` → `register` → `finish` `:72-79` (`putPlan`, funnel flush) → `/home` bridge →
`/session/new` (server creates the snapshot with prefill, redirects to `/session/[id]`) → `SessionLogger` (every tap `PATCH`es)
→ "Complete workout" → `/session/[id]/done`. If `putPlan` fails after register, `/home` renders "Build your week" with
`DraftFlusher` retrying from localStorage (`home/page.tsx:113`, `DraftFlusher.tsx`). No loading UI between server pages.

**Invited user, iOS.** The spec's path (1A: link carries the crew token, hero shows "X is waiting for you", auth lands
inside the crew) **does not exist**. "I have an invite" navigates to the same Days screen as "Build my week"
(`OnboardingFlow.swift:45-46`); `invitedCrewLine` is derived from `model.invitedCrew` (`:44`), a property that has no writer
(`OnboardingModel.swift:31`; `grep "invitedCrew\s*="` → none); there is no URL/universal-link handler (`grep onOpenURL` → none)
and the associated-domains entitlement is the placeholder `applinks:crew.example` (`project.yml:49`). The only way an iOS user
can end up in a crew is to create one. An invite link tapped on the phone opens the web landing page in Safari, whose "Get the
iPhone app" button points at `APP_STORE_URL` or `https://apps.apple.com` (`join/[token]/page.tsx:24`) and drops the token.

**Invited user, web.** `/join/[token]` renders the crew name/emoji/member count without auth (`:11-29`); dead or full links are
explicit states. "Continue on web" → `/onboarding?invite=<token>` → questions → save → `finish` joins the crew and routes to
`/crew` (`OnboardingFlow.tsx:74,78`). A signed-in visitor gets a one-tap "Join the crew". Dead ends: the hero's "I have an
invite" links to `/onboarding?invite=` with an empty token (`page.tsx:21`), which `onboarding/page.tsx:13` treats as no invite —
the button is a no-op relative to "Build my week"; the Apple sign-in failure redirect lands on a 404 (`callback/route.ts:48`).

## 7. Spec vs code drift

Built but not in the spec's route map (5.2) or flows — each exists and is tested, ratification status per Appendix A noted:
`auth/reset`, `auth/reset/confirm`, `auth/apple/callback`, `photos` + `photos/[key]` (registry R-004), `events` (Q03),
`crews/[id]` PATCH rename, `crews/[id]/messages/[messageId]`, `crews/[id]/mute`, `crews/[id]/stream`, `cron/notifications`
(`find web/src/app/api -name route.ts`; 51 exported handlers). Data beyond Part IX: `photos`, `events`, `rateLimits`,
`notificationLog`, `emailOutbox`, `pushOutbox` collections; `posts.type = "cardio"`; `sessions.workoutKind`; `users.weightUnit/
distanceUnit/notificationPrefs/welcomeBackAckDay` (all from A1–A9). Cardio itself (A2) overturns Appendix A's original "no cardio
workouts MVP" by a logged amendment. Web has a timezone picker in Settings (`SettingsView.tsx:46`) that S17 does not list.

Required by the spec but not built (beyond §4): the invite-aware hero and iOS join path (1A, S02, S13); push permission ask
"after the first workout completes" (1D) and any APNs registration on iOS (T033); contextual profile-photo prompt at first crew
join (1C — photo only in Settings); the first-perfect-week crew prompt (Flow 10; `grep -i perfect ios/Crew/Features web/src`
→ only the celebration badge); S14 "Rebuild shows diff first" (rebuild saves straight from the reveal, `OnboardingFlow.swift:52-55`);
Journal as a Progress segment (A19.4); two-button share on the celebration (A19.3); A15 "change today's workout"; A13 exercise
media (gated on the lawyer); A16 nutrition targets (gated on the age questionnaire); Lighthouse CI and axe-core (8.5/8.8);
the 8.9 iOS snapshot matrix; launch signposts asserted on CI (`Signposts.swift:1-2` "deferred"); Sentry (post-MVP by spec).

Rejected-list check: no barcode, food recognition, leaderboard, comments, DMs, supersets, Firebase, sound-effect API or
calorie/macro code in either client (`grep -rn -i "barcode\|food recognition\|leaderboard\|superset\|firebase\|AVAudioPlayer\|
calorie\|\bmacro\b\|comments?" ios/Crew web/src` → 0 non-comment hits). The rest timer schedules a local notification with
`.default` sound (`RestTimer.swift:50`) — Flow 3 explicitly allows "chime+haptic through a locked phone".

Concrete doctrine (C1–C14): lint-enforced parts hold — 0 protocols in `ios/Crew`, 0 barrel files, 0 middleware, `@/*` the only
alias (`tsconfig.json:27-30`), 0 Swift app files over 200 lines, 0 TS files over 150 (`wc -l` sweeps), numeric-literal ban
(`eslint.config.mjs:22`, doctrine-lint) and `// SPEC:` tags in every app file except two named-constants files. Deviations:
**C1 "no `<T>` generics in app code"** — `Api.send<Body: Encodable, Reply: Decodable>` (`Api.swift:56`) and `CrewBottomBar<Bar: View>`
(`BottomBar.swift:36,41`); **C10 "one screen per file"** — `PlanQuestionsScreen.swift` holds six types (lines 13, 52, 79, 95, 112,
164), `SetRow.swift` holds `Stepper` and `StepButton`, `PrimaryButton.swift` holds `SecondaryButton`, `EmptyState.tsx` holds
`ErrorState`, `CrewHeader.tsx` holds `Composer`; **C5/C1 admitted second copy** — the server-state-replaces-local block exists in
`SyncQueue.reconcile` (`SyncQueue.swift:154-167`) and `ServerHydrate.replaceGamification` (`ServerHydrate.swift:112-124`, comment
says "a third extracts"). C9's 40-line function cap: UNKNOWN (not lint-checked; `max-lines-per-function` is switched off in
`eslint.config.mjs:46`). C11: comments are extensive and history-heavy (many 10–30-line headers), which is not a rule breach but
raises the reading cost the doctrine exists to lower.

## 8. Decision Registry

⏳ items in Appendix A/B: (1) **Firebase Auth (Appendix B)** — undecided; code follows the stated default (custom auth: jose JWTs,
`crypto.scrypt`, Resend reset) and contains no Firebase. (2) **W053 lawyer answer on CC BY-SA art (A13)** — nothing vendored,
no attribution screen (`find ios web -iname "*attribution*"` UNKNOWN/none in tree listing). (3) **W070 age questionnaire (A16.b)** —
Stage 9 not started; no macro code. (4) **A16.c GAP: birth year optional on the Apple path** — code matches the recorded reading
(`validate.ts:51` `birthYear: birthYearSchema.optional()`, `LoginScreen.swift:29` passes `nil`). (5) **A18.13 daily streak** —
open owner decision recorded in `debt.md`; engine and rest-day copy still daily (`TodayCard.swift:119-121`).

Decisions the code contradicts or has not yet applied: A19.3 (ruled: toggle removed, two buttons) — `CelebrationScreen.swift:40-41`
still shows a `Toggle` and the post is already queued shared (`SessionScreen.swift:62`); A19.4 (Journal segment) — `ProgressScreen.swift:37`
toolbar push; A19.6 ordering names Stage C/E after A15, so both are "pending", not silent drift. A20 Build B is ratified
(`docs/home-plan-a20-2026-09-11.md`) but **held out of master**: the queue block F46 is guarded by `CREW_BUILD_B=1`
(`docs/commit-queue.sh:282-290`) and its files are not in the tree (`ls ios/Crew/Features/Home/LogRow.swift` → no such file);
the snapshot lives in a previous session's temp scratchpad
(`C:\Users\princ\AppData\Local\Temp\claude\…\29f6db46-…\scratchpad\buildB`, present today). S02's "invite token renders crew
name/emoji on the hero" and 1A are contradicted on iOS (§6). E2 "Captain: rename" and E20 "delete own messages" are server-only.
E9 "report any post/message/crew-name" — clients report posts only (`CrewModel.swift:131`, `CrewView.tsx:35`). 5.2's
`SoloOrCrewScreen` is correctly absent (S06 removed). Spec 5.2 names six vector files V01–V40; the repo holds nine files, 56
vectors, all append-only additions logged in Appendix A.

## 9. Security posture (high level)

Auth as implemented: HS256 JWT access token, 15 min (`auth.ts:21-30`; `JWT_SECRET` must be ≥ 32 bytes, `:16-17`); opaque
refresh token, 30 days, sha256-hashed at rest, rotated on every use, reuse kills the family (`refresh-tokens.ts:40-52`); iOS
sends `Authorization: Bearer` and stores both tokens in the Keychain (`AuthStore.swift:46-55`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
`KeychainStore.swift:39`); web uses `HttpOnly; SameSite=Lax` cookies, refresh cookie scoped to `/api/v1/auth`, **`Secure` only when
`COOKIE_SECURE=true`** (`auth.ts:65-68`). Passwords: `crypto.scrypt` with salt (`password.ts`). Apple: identity token verified
against Apple's JWKS with issuer + audience (`apple-auth.ts:29-41`); the web callback **does not verify a nonce or bind `state` to
the browser session** (`callback/route.ts:29-38` parses tz/eula/next from `state` only), so a login-CSRF into an attacker's Apple
account is possible; UNKNOWN whether Apple's own form_post protections mitigate it in practice. Rate limits: auth 10/min/IP,
posts 60/h/user (`rate-limit.ts:46-52`); photo upload, sync and everything else unlimited (spec G11 says so). Reset tokens are
single-use, 30 min, and revoke all refresh tokens (`password-resets.ts:35-46`); reset requests never enumerate accounts (`reset/route.ts:16-22`).

| Route | Auth | Ownership / scope check |
|---|---|---|
| POST auth/register, login, apple, reset, reset/confirm, refresh; POST apple/callback | public (rate-limited by IP) | n/a; refresh validates the token family |
| POST auth/logout | requireUser | revokes only the presented refresh token |
| GET/PATCH/DELETE users/me · GET users/me/export | requireUser | self only; PATCH verifies `profilePhotoKey` is the caller's own profile upload (`users.ts:71-74`); DELETE requires `{confirm:"delete"}` |
| POST photos · GET photos/[key] | requireUser | GET: owner or a member of the owner's current crew (`photos.ts:27-36`) |
| GET/PUT plans | requireUser | by userId (`plans.ts:41-50`) |
| POST/GET sessions · GET/PATCH sessions/[id] | requireUser | `findOwnSession` (`sessions.ts:46-51`, foreign id → 404) |
| POST/GET posts · GET/PATCH/DELETE posts/[id] · POST/DELETE reactions | requireUser | GET: own or crew-mate of the post's crew (`posts/[id]/route.ts:24-29`); PATCH/DELETE own (`:14-18`); react: crew members only (`reactions.ts:10-17`) |
| POST/GET crews · GET crews/join | requireUser / **public preview** | one crew per user (unique index); preview leaks name/emoji/count to any token holder (by spec W1) |
| POST crews/join | requireUser | full-crew, one-crew, block checks (`crews.ts:45-57`) |
| PATCH crews/[id] · POST invite | requireUser | `requireCaptain` (`crews.ts:75-79`) |
| GET/DELETE crews/[id]/members · GET stream · PATCH mute · POST messages | requireUser | `requireMember` (`crews.ts:24-30`); remove-other requires Captain (`:60-62`) |
| DELETE crews/[id]/messages/[messageId] | requireUser | sender or Captain (`crew-messages.ts:24-31`) |
| POST sync | requireUser | every op re-runs the same lib functions with the caller's userId (`sync-ops.ts:28-69`) |
| GET/POST/DELETE pause · POST/DELETE push-token · GET/POST/DELETE blocks · POST events | requireUser | by userId; DELETE push-token matches token + userId |
| POST reports | requireUser | any existing post/message/crew/user id may be reported (not scoped to the caller's crew) |
| GET api/cron/notifications | `Authorization: Bearer $CRON_SECRET` (`cron/notifications/route.ts:14-17`); unset secret = always 401 | n/a |

Standing checks ①–④ (cross-user 403/404, expired JWT, malformed body, idempotency) are auto-generated for every route file
(`tests/api/standing-checks.gen.test.ts`), and pass in the 453.

Secrets: only `web/.env.example` is tracked (19 variable names); `.env`/`.env.*` are gitignored (`.gitignore:13-15`); a local
`web/.env` with real values exists on this machine and was not read. `JWT_SECRET`, `CRON_SECRET`, `APNS_PRIVATE_KEY`,
`BLOB_READ_WRITE_TOKEN`, `RESEND_API_KEY` are read only via `process.env`. CI holds App Store Connect keys as GitHub secrets
(`testflight.yml:8-17`); the bundle id and API host are repository variables. `email.ts:53` defaults the moderation inbox to
`moderation@example.com` and `RESEND_FROM` to `crew@example.com` when unset.

Validation on user text: zod caps everywhere (`caption ≤ 280`, `chat ≤ 1000`, `crew name ≤ 30`, `displayName`, `report reason`,
`exercise name ≤ 60`; `validate*.ts`), timezone must be resolvable, ids are ObjectId-shaped, emoji is any string ≤ `crewEmojiMaxChars`
(`validate-crews.ts:7`, not checked to be an emoji). Rendering is React/SwiftUI text (no HTML injection path found). Images: multipart
`file` + `purpose`; accepted by client-declared MIME (jpeg/png/heic/heif/webp, `photos.ts:12-16`), source ≤ `photoMaxSourceMb`
(`:13,17`), re-encoded by sharp with all metadata dropped and resized to `photoMaxEdgePx`, quality stepped down to ≤ `imageUploadMaxKb`
(`blob.ts:27-36`); a non-image with an image MIME makes sharp throw → generic 500 (`api-error.ts:39-40`). **Stored photos are
`access: "public"` at an unguessable random-suffixed URL** (`blob.ts:41`) and the auth-checked GET route answers with a 302 to that
public URL (`photos/[key]/route.ts:17`), so anyone holding a leaked URL can fetch the photo without auth — spec 8.7 asks for
"blob URLs unguessable + auth-checked"; only the first half holds.

Account deletion (`account-delete.ts:11-34`): leaves the crew (captaincy passes / archive), then deletes posts, sessions, plan,
reactions given, messages (including the "left the crew" system line just written), pauses, blocks both directions, refresh
tokens, password resets, push tokens, gamification state, notification log; anonymises `events.userId`; deletes photos from
storage; deletes the user; emails a confirmation. **Survives:** `reports` naming the user as reporter or target (never touched),
reactions other people gave on the user's now-deleted posts (orphans), `events.props`, `emailOutbox`/`pushOutbox` rows (dev
transports; contain the email address), `rateLimits` keys until TTL. Photos and blob objects are deleted; a deleted user's
past crew posts vanish from the stream (spec E9 "cascades everywhere"; E2's "leavers' posts remain" applies to leaving, not deletion).

Report flow end to end: long-press → "Report post" (iOS `PostCard.swift:50`, fixed reason "Reported from the crew stream"
`CrewModel.swift:131`) or "…" menu (web `PostMenu.tsx`) → `POST reports` → stores `{targetType, targetId, reporterId, reason,
status:"open"}` and emails `MODERATION_INBOX` with a preview (`reports/route.ts:19-30`, `email.ts:52-70`) → the user sees
"Reported. A human will look." There is no admin surface, no status route, and nothing ever sets `resolved`; the email tells the
owner to edit the Mongo document by hand (`email.ts:68`). Block is immediate, silent, two-way in streams and joins; **blocked
members still count in the pulse and appear in the member strip** (`crew-stream.ts:30-54` never consults `blockedIdsFor`; noted in
`debt.md` 2026-09-09 A5).

Would embarrass us with a stranger in the app: public blob URLs; report queue that is an inbox with a default `example.com`
address; the Apple web failure redirect to a 404 page; the placeholder Privacy/Terms marked "Draft"; "I have an invite" doing
nothing on both platforms; cookies without `Secure` unless the env var is set.

## 10. Dead weight

- Unreachable: `web/src/components/SignInWithAppleButton.tsx` (0 usages); client functions `crewPreview`, `renameCrew`, `getPause`,
  `getSession` (`api-client*.ts`, 0 callers) and `deleteMessage` (client, 0 UI callers); iOS `Api.registerPushToken`
  (`ApiSettings.swift:111`) and `CrewModel.join(token:)` (`CrewModel.swift:166`); the `/save` redirect target (`callback/route.ts:48`).
- Unused packages: none — every runtime npm package has an importer (`jose`, `sharp`, `@vercel/blob`, `apns2`, `resend` cited in §1);
  `apns2` and `resend` only execute when their env vars exist, otherwise the outbox substitutes run.
- Duplicate implementations: server-state-replaces-local in two places (§7); the `units` legacy mirror written beside `weightUnit`
  on every user document and reply (`users.ts:51,106`, `users/me/route.ts:44-45`, `UserDTO.units` `ApiModels.swift:13`) kept for
  TestFlight build 3; Full-Body A/B templates in `shared/seed/plan-templates.json` that no generator uses (`debt.md` 2026-09-09 A1);
  `WeeklyRing` on iOS is drawn by Progress only (`debt.md` 2026-09-12 A20.4). Write-only fields listed in §3.
- TODO/FIXME: **0 in tracked source** — doctrine-lint bans them (`doctrine-lint.mjs:56`); the 14 grep hits are 3 SwiftPM-generated
  files under `ios/.build` and 11 case-insensitive matches on the word `PhotoDoc`. The ten most consequential *open* compromises
  are instead in `docs/debt.md` (open section, 2026-09-04 → 2026-09-16): (1) A20 Build B written, uncompiled, held outside master;
  (2) no SwiftData migration — a schema change wipes the phone's unsynced rows (`Store.swift:25-36`); (3) Vercel Hobby cron runs
  daily, so reminders and streak nudges "effectively never fire in the beta"; (4) Atlas M0 with `0.0.0.0/0` and no backups; (5)
  Resend sends from `onboarding@resend.dev` — delivers only to the owner's own address; (6) `applinks:crew.example` placeholder,
  no AASA file — universal links cannot work; (7) `SetLogDTO` has no id/order, so a set's position is its identity across sync
  (removal can race a concurrent patch); (8) the 8.9 snapshot matrix has never existed while the Phase 5 gate reads green;
  (9) `missedGray` used as a graphical object at 2.39:1 on the heat map and unlit flame; (10) `notification-facts.ts:30,37` pads
  the clock and picks the median with `initialsMaxLetters`, an unrelated constant.

## 11. Cheap wins

Candidates meeting all five criteria (reuses existing infrastructure, no dependency, no new screen, visible on day one, ≤ ~5 files).

| # | What | Reuses (evidence) | Size |
|---|---|---|---|
| 1 | iOS push registration: ask permission after the first completed workout and post the device token | `Api.registerPushToken` (`ApiSettings.swift:111`), `OpKind.pushToken` in the offline queue (`SyncQueue.swift:13`), `POST push-token` route + cron sender already tested; `CelebrationScreen` dismissal in `HomeScreen.swift:39` is the 1D moment | S |
| 2 | Wire "I have an invite" on iOS to a paste field on the existing hero + preview line | `IntroScreen.invitedCrewLine` and `OnboardingModel.invitedCrew/inviteToken` already exist (`IntroScreen.swift:8`, `OnboardingModel.swift:31-32`); `GET crews/join` preview and `joinCrew` after auth already called (`OnboardingModelAuth.swift:93`) | S |
| 3 | Fix the web hero's "I have an invite" to pass a real token (query the preview endpoint) | `page.tsx:21`, `crewPreview()` (`api-client-crew.ts:17`, unused) | XS |
| 4 | Delete own chat message (web and iOS) | route + lib exist (`crew-messages.ts:24-31`); web client `deleteMessage` exists unused; iOS `MessageRow.swift` has a `mine` flag | S |
| 5 | Captain rename crew / change emoji from the invite panel | `PATCH crews/[id]` + `renameCrew()` client exist unused (`api-client-crew.ts:26`); `InviteScreen.swift` already gates Captain tools (`:28`) | XS |
| 6 | Report a message or a crew name from the stream | server accepts `targetType message\|crewName` (`validate-crews.ts:19`); `Api.report(targetType:)` is parameterised (`ApiSettings.swift:112`); `PostCard` dialog pattern (`PostCard.swift:47-53`) | S |
| 7 | Profile photo via the existing upload path, prompted at first crew join (1C) | `EditProfileScreen`/`ProfileForm` and `POST photos purpose=profile` exist; `CrewModel.create/join` are the join moments (`CrewModel.swift:158-168`) | S |
| 8 | Exclude blocked members from the pulse and member strip | `blockedIdsFor` (`crew-stream.ts:25-28`) already used by `streamFor`; apply in `memberDots`/`pulseFor` | XS |
| 9 | Show "N waiting to send" on Home while online, not only offline | `SyncQueue.pendingCount` is `@Observable` (`SyncQueue.swift:77`), banner already takes `pending` (`ErrorState.swift:35`) | XS |
| 10 | Send the iOS funnel steps (hero → saved) to `POST events` | endpoint accepts `X-Crew-Client: ios` (`events/route.ts:15`); web `lib/funnel.ts` is the twin to mirror; `Api.send` handles the call | S |
| 11 | Point the Apple web failure redirect at `/login?apple=failed` and show the line | `callback/route.ts:48`, `LoginForm.tsx` error line | XS |

## 12. Top 10 gaps to a shippable MVP (risk-ordered)

Owner ruling 2026-09-17: #1 and #2 stay at the top of this list; #1 blocks launch; neither is to be built until the owner says go.

| # | Gap | Size | Type |
|---|---|---|---|
| 1 | **BLOCKING** — No invited-user path on iOS: no token entry, no universal links, placeholder associated domain; the growth loop works only through the web landing page (§6) | M | build |
| 2 | iOS never asks for notification permission or registers an APNs token; the whole notification feature (reminders, streak-risk, reaction buzz) is unreachable on the only platform that has push (§4) | M | build |
| 3 | Share control lies: iOS posts every workout to the crew before the celebration shows a toggle (`SessionScreen.swift:62`); A19.3's two-button fix is ruled but unbuilt | S | build |
| 4 | Nothing has run on a physical device: camera, haptics, keyboard, offline, VoiceOver, Dynamic Type, weight tape, swipe-to-remove are all "WRITTEN-UNVERIFIED"; the 8.9 snapshot matrix does not exist | L | polish |
| 5 | A20 Build B (the ratified Home redesign with the type scale) lives only in a temp-folder scratchpad, held out of master | M | build |
| 6 | Production wiring: daily-only cron (reminders never fire), Atlas M0 open allowlist, unverified Resend domain, missing Blob/APNs/Apple credentials, `COOKIE_SECURE` unset by default | L | build (owner) |
| 7 | Photos are public-read at their blob URL behind a 302 (§9) | S | build |
| 8 | Apple web sign-in: no state/nonce binding and a failure redirect to a 404 | S | build |
| 9 | Moderation has no resolution path; messages/crew names unreportable from either client; blocked members still counted in the pulse | S | build |
| 10 | Launch surface untouched: placeholder Privacy/Terms, no App Store listing, T047 audit not started; plus no SwiftData migration for the beta cohort | M | build / polish |

Also worth deleting or deciding rather than building: the dead `SignInWithAppleButton.tsx`, the five unused client functions,
the Full-Body A/B seed templates, and the `units` mirror once no pre-A9 build remains (§10).

## 13. Three questions only the owner can answer

1. Is A20 Build B still the intended Home, and is the scratchpad copy (`…\29f6db46-…\scratchpad\buildB`, a temp directory) the
   only copy? It must be restored and pushed with `CREW_BUILD_B=1 bash docs/commit-queue.sh` (`docs/commit-queue.sh:286`) or
   formally dropped; either way the ratified layout is currently one disk-cleanup away from loss.
2. For invites on iOS, which mechanism for MVP: universal links (needs your Apple Team ID, a real domain, an AASA file served by
   the web app, and the entitlement changed from `crew.example`) or a paste-a-link/code field on the hero? The spec assumes the
   first; only the second is buildable without your accounts.
3. When do the production accounts land — Vercel Pro (minute cron), Atlas M10+, a verified Resend domain, APNs key, Apple Services
   ID for web sign-in, Blob token — and do you want the beta to keep running on the daily-cron / outbox substitutes until then?
   Nothing in notifications, email or Apple web sign-in can be validated end to end before that.
