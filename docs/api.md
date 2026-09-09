# Crew API contract — `/api/v1`

SPEC: Part V 5.2 (route tree) · 5.6.4 (the canonical route shape) · 8.2 (test matrix) · Part IX (data model) ·
Builder's Rule 4 (no UI against an undefined contract) · T006. One `route.ts` per resource + verb; every handler
reads top-to-bottom: validate → authorize → do → respond. Every mutation ends with `recomputeAndStore(userId)`
and `logEvent(...)`.

## Conventions

- **Auth**: `requireUser(req)` reads the access JWT from the `Authorization: Bearer` header (iOS, Keychain) or
  the `crew_access` httpOnly cookie (web). Access tokens live `jwtAccessTokenMinutes` (15); refresh tokens
  live `jwtRefreshTokenDays` (30) and ROTATE on every refresh (a used refresh token is dead; reuse → 401 and
  the whole family is revoked). Routes marked **public** need no token.
- **Errors** — one shape, C13: `{ "error": { "code": "<camelCase>", "message": "<one sentence>" } }` with the
  HTTP status. Codes: `validation` 400 · `unauthorized` 401 · `forbidden` 403 · `notFound` 404 ·
  `conflict` 409 · `rateLimited` 429 · plus the resource-specific codes listed per route.
- **Idempotency** (8.2 ④): every create that carries a `clientId` (UUID from the client) returns the existing
  document on retry, never a duplicate.
- **Server clock wins** (E15): `dayKey` is always computed server-side from `new Date()` and the request's
  `timezone` (IANA); clients never send a dayKey for creation.
- **Scoping** (8.2 ①): every query is scoped by the authenticated `userId` (or crew membership); a foreign id is a
  404, never a 403 that leaks existence — except captain-only actions, which are 403 for members.
- **Rate limits** (G11): auth endpoints `rateLimitAuthRequestsPerMinutePerIp` (10/min/IP); post creation
  `rateLimitPostCreationPerHourPerUser` (60/h/user); everything else unlimited in MVP.
- **Validation**: one zod schema per DTO in `web/src/lib/validate.ts`, names below; iOS `ApiModels.swift`
  mirrors them 1:1.
- **Responses**: `{ ...document }` for single resources, `{ items: [...] }` for lists, `{ post, gamification }`
  for anything that changes gamification (the client REPLACES its local state with `gamification`, 5.6.3).
  `gamification.newAchievementIds` lists the seed achievement ids THIS mutation unlocked (E8: they fold into the
  celebration); `gamification.earnedAchievementIds` is the running list and only ever grows (V35).

## Auth — `auth/*` (T010–T012) · public unless noted

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `auth/register` | `registerSchema` { email, password, displayName, timezone, eulaAccepted: true, birthYear } | scrypt-hash the password, create User + empty GamificationState, issue tokens; the pending onboarding plan is saved by a following `PUT plans` | `validation`, `emailTaken` 409, `eulaRequired` 403, `underage` 403 (< `minimumAgeYears`), `rateLimited` |
| POST `auth/login` | `loginSchema` { email, password } | verify scrypt, issue tokens | `invalidCredentials` 401, `rateLimited` |
| POST `auth/apple` | `appleSignInSchema` { identityToken, authorizationCode?, displayName?, timezone, eulaAccepted, birthYear? } | verify the Apple identity token (JWKS, aud = bundle/service id), find-or-create the User by `appleSub`, issue tokens | `invalidAppleToken` 401, `eulaRequired` 403 |
| POST `auth/refresh` | `refreshSchema` { refreshToken } (iOS) or cookie (web) | rotate: new access + refresh, old refresh dead | `unauthorized` (expired/reused → family revoked) |
| POST `auth/logout` | — (auth) | revoke the presented refresh token, clear cookies | — |
| POST `auth/reset` | `resetRequestSchema` { email } | create a single-use reset token (`passwordResetTokenExpiryMinutes` = 30), send the Resend email; ALWAYS 202 (no account enumeration) | `rateLimited` |
| POST `auth/reset/confirm` | `resetConfirmSchema` { token, newPassword } | consume the token (once), set the hash, revoke every refresh token of the user | `resetTokenInvalid` 400 (unknown, used, or expired) |

Tokens: `{ user, accessToken, refreshToken, accessExpiresAt }` for iOS; on web the same values are set as
`crew_access` / `crew_refresh` httpOnly, Secure, SameSite=Lax cookies and the body carries `{ user }`.

## Users — `users/me` (T010, T041)

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| GET `users/me` | — | `{ user, gamification, pause, crew }` — `user` is the public User: id, email, authProvider, displayName, profilePhotoKey, units, timezone, reminderTime, `notificationPrefs { workoutReminder, streakRisk, crewActivity }` (always present, defaults `true` — A7), welcomeBackAckDay, createdAt; `crew` = `{ id, name, emoji, muted }` or null | — |
| PATCH `users/me` | `updateMeSchema` { displayName?, units?, timezone?, reminderTime? (null clears), profilePhotoKey? (null clears), notificationPrefs? (partial), welcomeBackAckDay? } | update profile fields; `profilePhotoKey` must name a photo the caller uploaded with `purpose: "profile"` (400 `validation` otherwise — A7/E1); `notificationPrefs` is merged over the stored toggles (send only the row that changed — A7); `welcomeBackAckDay` (YYYY-MM-DD) records the answer to the welcome-back screen (E4) so no device asks twice in one quiet spell; replies with the public User | `validation` |
| DELETE `users/me` | `deleteAccountSchema` { confirm: "delete" } | the cascade (E9, 8.2 Account): posts vanish from streams, blobs deleted, memberships removed (captaincy auto-passes, last-out archives), refresh tokens revoked, Resend "account deleted" email; afterwards every resource 404s and re-signup is a fresh identity | `validation` |
| GET `users/me/export` | — | streamed JSON export of everything the user owns (user, plan — in the A1 shape, sessions, sets, posts, reactions given, memberships, messages, gamification, pauses, blocks) — 8.2 completeness test | — |

## Photos — `photos` (T027) — tree addition, see ratification R-004

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `photos` | multipart `file` (image/jpeg, image/png, image/heic) + `purpose` ∈ {post, profile} | `sharp`: strip ALL metadata (EXIF/GPS), auto-orient, resize to ≤ 1600 px long edge, JPEG ≤ ~`imageUploadMaxKb`; store in Vercel Blob under an unguessable key; returns `{ photoKey }` | `validation` (type/size), `photoTooLarge` 413 |
| GET `photos/[key]` | — (auth) | serves/redirects to the blob only if the caller may see it (own photo, or a crew-mate's post photo) — blob URLs are never public (8.7) | `notFound` |

## Plans — `plans` (T023)

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| GET `plans` | — | the user's single Plan — `PlanResponse { trainingWeekdays: number[], workouts: [WorkoutTemplate], updatedAt }` (A1): `trainingWeekdays` are the ISO weekdays (1 = Mon … 7 = Sun) the user trains, sorted; `workouts` is the ORDERED rotation, one per `kind` ∈ push \| pull \| legs \| fullBodyA \| fullBodyB \| custom, each `{ kind, name, exercises: [ExerciseTemplate] }` — no weekday on a workout: the rotation assigns days (the next workout is the one after the last completed rotation workout). A document written before A1 (one workout per weekday) reads back normalised: `trainingWeekdays` = its weekdays, workouts deduped by kind in first-seen order, `weekday` dropped; it is rewritten on the next PUT | `notFound` (never created) |
| PUT `plans` | `putPlanSchema` { trainingWeekdays: [1..7, unique, 1–7 entries], workouts: [1–7 × { kind, name, exercises: [ExerciseTemplateInput] }] } — `kind` unique across the list, order kept as given | replace the whole plan, forward-only (existing sessions keep their snapshots); enforces `planMaxExercisesPerDay` (15), `planMaxSetsPerExercise` (20), `exerciseNameMaxChars` (60); `ExerciseTemplateInput.type` ∈ strength \| mobility \| cardio — mobility holds AND cardio blocks carry `holdSeconds` (seconds, A2: ≤ `holdSecondsMax` for a hold, ≤ `cardioMinutesMax` × 60 for a cardio block) | `validation` |

## Sessions — `sessions`, `sessions/[id]` (T023)

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `sessions` | `createSessionSchema` { clientId, timezone, startedAt, workoutSnapshot: { name, kind? ∈ push \| pull \| legs \| fullBodyA \| fullBodyB \| custom \| cardio, weekday? (accepted from older clients, ignored), isPlannedDay, exercises: [SessionExerciseInput] } } — `SessionExerciseInput.type` ∈ strength \| mobility \| cardio; `SetLogInput { targetReps, actualReps, weight?, holdSeconds? (≤ `holdSecondsMax` on a mobility row, ≤ `cardioMinutesMax` × 60 on a cardio row), distanceMeters? (int ≤ `cardioDistanceMaxMeters`, cardio only), isWarmup, done }` | create with the snapshot (immune to later plan edits); idempotent on `clientId`; `kind` is stored as `workoutKind` (A1: the rotation pointer reads it; a legacy session without one infers it from the name). A standalone cardio log (A2) is `{ name: <Activity>, kind: "cardio", isPlannedDay: false, exercises: [ one cardio row, one done set with holdSeconds = minutes × 60 and the optional distanceMeters ] }`, created and completed in one client flow — it never advances the rotation | `validation` |
| GET `sessions` | ?from=&to= (dayKeys) | the user's sessions in range, newest first (Progress/Journal; a fresh phone's hydration — `ServerHydrate`) | — |
| GET `sessions/[id]` | — | one session with its set logs — `{ session: { id, clientId, dayKey, status, workoutName, workoutKind, isPlannedDay, startedAt, completedAt, timezone, exercises, setsDone, setsPlanned, setsAsPlanned, updatedAt } }` | `notFound` |
| PATCH `sessions/[id]` (`id` = the server id, or the session's `clientId` for a session an iPhone created offline) | `patchSessionSchema` { exercises?: [SessionExerciseInput], status?: "inProgress" \| "completed" \| "discarded", completedAt?, timezone, post?: { clientId, shareToCrew, caption?, photoKey? } } — `weight`/`holdSeconds`/`distanceMeters` may be null or absent (Swift's Codable omits a nil) | replace the exercise/set logs (warm-ups excluded from x/y, holds by seconds, `done`/`asPlanned` per V33), completion applies V32 (a done cardio set is a work set — V51); completion creates the workout Post (`post ≠ log`) with its `summary` line (A6: strength `"{workoutName} · {setsDone}/{setsPlanned} sets · {minutes} min"`, cardio `"{name} · {minutes} min[ · {distance} km\|mi]"` in the poster's units, one decimal) and recomputes; replies `{ session, gamification }` | `notFound`, `validation` |

## Posts — `posts`, `posts/[id]`, `posts/[id]/reactions` (T026–T027, T030)

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `posts` | `createPostSchema` { clientId, type: workout \| meal \| text, sessionId?, photoKey?, caption? (≤ `captionMaxChars`), mealTag?, shareToCrew, timezone, isPlannedDay, workoutCompleted?, earlierToday?, createdAt? } | create (server dayKey; same-day backfill only — `backfillMaxDaysBack` = 0), idempotent on `clientId`; `recomputeAndStore`; rate-limited | `validation`, `rateLimited` |
| GET `posts` | ?from=&to= | the user's journal (forever); every post carries its `clientId` — a phone addresses its journal by it (hydration, `deletePost`). Post shape: `{ id, clientId, type, sessionId, photoKey, caption, mealTag, crewId, dayKey, isPlannedDay, workoutCompleted, earlierToday, summary, createdAt }` — `summary` (A6) is the server-written line of a workout post (`"Push day · 12/12 sets · 44 min"`, `"Walk · 25 min · 2.1 km"`), null on meals and on posts made before A6; clients never send it | — |
| GET `posts/[id]` | — | one post (own, or a crew-mate's within the stream window) | `notFound` |
| PATCH `posts/[id]` | `patchPostSchema` { caption } | edit the caption; photos are never editable (E3) | `notFound`, `validation` |
| DELETE `posts/[id]` | — | delete the post; sets and streak untouched (E3; same-day gamification per V34 is the CLIENT's optimistic undo — the server recompute is the truth) | `notFound` |
| POST `posts/[id]/reactions` | `reactionSchema` { emoji ∈ `reactionEmojis` } | react (UNIQUE per user-target; a second emoji replaces the first); `reactionXpDailyCap` server-enforced | `notFound`, `validation`, `notInCrew` 403 |
| DELETE `posts/[id]/reactions` | — | un-react (tap again, E20) | `notFound` |

## Crews — `crews`, `crews/join`, `crews/[id]/{members,invite,messages,stream}` (T029–T030)

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `crews` | `createCrewSchema` { name (≤ `crewNameMaxChars`), emoji } | create; caller = Captain; one crew per user (`crewsPerUserMax`) | `validation`, `alreadyInCrew` 409 |
| GET `crews` | — | the caller's crew (or `{ crew: null }`) with members + pulse | — |
| GET `crews/join` (**public**) | ?token= | invite preview `{ name, emoji, memberCount, full }` for the landing page and the invite-aware hero (1A) | `inviteInvalid` 404 (revoked/unknown) |
| POST `crews/join` | `joinCrewSchema` { token } | join via link; `crewMaxMembers` (10) enforced; system line "X joined the crew" | `inviteInvalid` 404, `crewFull` 409, `alreadyInCrew` 409, `blocked` 403 (a block in either direction) |
| GET `crews/[id]/members` | — | members with streak, today-dot, pause ⏸ | `notFound` |
| DELETE `crews/[id]/members` | `leaveOrRemoveSchema` { userId? } | own userId (or absent) = leave; another userId = Captain removes; captaincy auto-passes to the longest-tenured; last one out archives silently (E2) | `notFound`, `forbidden` |
| POST `crews/[id]/invite` | — | Captain regenerates the invite token (the old link dies) | `forbidden` |
| PATCH `crews/[id]` | `renameCrewSchema` { name?, emoji? } | Captain renames | `forbidden`, `validation` |
| GET `crews/[id]/stream` | ?since= | the ONE unified stream: posts (shared — each `post` is the Post shape above, `summary` included, A5/A6), messages, system lines, time-merged, `feedWindowDays` (7) window, join-forward for joiners, blocked users filtered both ways, own reactions marked; comeback banners per V39 | `notFound` |
| POST `crews/[id]/messages` | `sendMessageSchema` { clientId, body (≤ `chatMessageMaxChars`) } | send; idempotent on `clientId` | `validation`, `notFound` |
| DELETE `crews/[id]/messages/[messageId]` | — | own message → tombstone (`deletedAt`); Captain may delete any | `notFound`, `forbidden` |
| PATCH `crews/[id]/mute` | `muteSchema` { muted: boolean } | per-crew mute (E2, S17) | `notFound` |

## Sync — `sync` (T023)

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `sync` | `syncSchema` { timezone, ops: [ { opId, kind ∈ OpKind, payload } ] } — `payload` is the op's JSON object (never a string); `patchSession` names the session by `sessionId` = its clientId; `deletePost` = { clientId } | replay the offline queue IN ORDER (createSession · patchSession · createPost · deletePost · sendMessage · react · unreact · putPlan · pause · pushToken), each idempotent; returns per-op results + the server `gamification` state, which REPLACES the client's (5.6.3 reconcile); device-clock skew reconciled to server time | per-op errors in the result array, never a failed batch |

## Pause — `pause` (T041)

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| GET `pause` | — | the active/scheduled pause or `{ pause: null }` | — |
| POST `pause` | `createPauseSchema` { startDay, endDay, timezone } | validate per V22/V23/V44 (`validatePauseRequest`), create | `pauseRetroactive` 400, `pauseTooLong` 400, `alreadyPaused` 409 |
| DELETE `pause` | — | end the pause early (endDay = today) | `notFound` |

## Safety — `reports`, `blocks` (T034)

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `reports` | `createReportSchema` { targetType ∈ post \| message \| crewName \| user, targetId, reason (≤ 500) } | store the Report and email the moderation inbox via Resend (this IS the manual queue, no AI scanning) | `validation`, `notFound` |
| GET `blocks` | — | `{ blocked: [{ userId, displayName }] }` — the people the caller blocked, oldest first (Settings › Blocked people, A7) | — |
| POST `blocks` | `blockSchema` { userId } | block; hides content both ways, no notification; idempotent | `validation` |
| DELETE `blocks` | `blockSchema` { userId } | unblock (Settings › Blocked people › Unblock, A7) | `notFound` |

## Notifications — `push-token` (T033) · cron `api/cron/notifications`

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `push-token` | `pushTokenSchema` { token, platform: "ios" } | register/refresh the APNs device token | `validation` |
| DELETE `push-token` | `pushTokenSchema` { token } | unregister (logout, notifications off) | — |
| GET `api/cron/notifications` (`Authorization: Bearer $CRON_SECRET`, not a user route) | — | evaluates the pure eligibility functions per user with a push token: the workout reminder names today's ROTATION workout (`"Pull day is ready 💪"` / `"{n} exercises + mobility[ + cardio]"`, A1) and needs `notificationPrefs.workoutReminder`; the streak-risk nudge needs `notificationPrefs.streakRisk`; crew activity needs `notificationPrefs.crewActivity` and no mute (A7); each send is logged once per day | `unauthorized` |

## Analytics — `events` (T008/T045) — tree addition, see ratification R-004

| Method + path | Schema | Does | Errors |
|---|---|---|---|
| POST `events` | `clientEventsSchema` { events: [ { name, at, props? } ] } (auth) | first-party funnel events from clients (web: `onboarding_hero` · `onboarding_days` · `onboarding_experience` · `onboarding_plan_built` · `onboarding_saved`, queued pre-auth by `lib/funnel.ts` and flushed after sign-up with their original `at`; the 1C hero → Home reading is `onboarding_saved.at − onboarding_hero.at`); stored with `source` ios/web and the server's `receivedAt` (E15); replies `{ accepted: n }` 201; server-side events are inserted by `lib/events.ts` directly (`account_created`, `post_created` give the 1D bridge → first-post step) | `validation` |

## Standing checks (8.2 ①–④, T015)

`tests/api/standing-checks.gen.test.ts` discovers every `route.ts` under `app/api/v1` and, for each exported
method, asserts: ① a foreign user's resource → 404/403 · ② an expired access token → 401, and `auth/refresh`
recovers · ③ a malformed body → 400 in the standard error shape · ④ where the schema has `clientId`, a retried
create returns the same document. Public routes are listed in the test's `PUBLIC` allowlist; a route not
covered fails the suite forever after.
