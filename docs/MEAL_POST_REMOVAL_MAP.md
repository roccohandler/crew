# Meal-post removal map (the plate journal)

**EXECUTED 2026-09-18** (the owner's order of 2026-09-18, item 2; commits a70a401 · 8695e1d · 3eb3042 and the constants/seeds/spec-markers
commit): every row below has been applied — the engines under G1 (a) (rest days exempt; 23 vectors retired by marker, V66–V84 added), the
web platform (POST posts removed, photos profile-only, Home asks nothing of a rest day, the composer and the meal row deleted), the phone
(the Post folder deleted except the profile camera, the sync queue without photos, CameraDenied → ProfilePhotoDeniedTests), the constants
(the four G10 minutes, textOnlyPostMaxTaps, nutritionPostTargetSeconds, photoPostOptimisticMaxMs, captionComposerMaxLines deleted;
xpMealPost / mealXpDailyCap stay vector-bound), the seeds (first-flame and perfect-week re-copied) and the spec markers. The line
numbers below are those of master `1d94692`, when the map was drawn; the readings the execution took are R-068 to R-072.

Owner ruling (2026-09-17, recorded as Appendix A **A22 — OWNER-DIRECTED, PENDING** the four GAPs below): nutrition is macro logging
ONLY, in the MyMacros+ shape. Meal photo/text posts — the plate journal — are REMOVED from the product: no meal photo capture, no
meal captions, no meal posts in the crew stream, no meal tags, no "same as yesterday", no 3-meal XP cap. A meal is a macro entry
(saved meal, template slot, quick-add, fast-food seed item) and nothing else, private per A16 clause ④. Workout posts and the crew
stream are unaffected except that meal cards no longer exist. This map lists every place the plate journal exists, in the shape of
`docs/GYM_ASSUMPTION_MAP.md`, with the change each place needs. **Read-only at master `1d94692`; nothing here has been changed,
no vector edited, no constant edited.** Method: `grep -rn -iE "meal|plate|snap|camera|photo|caption|mealTag|purpose"` over `docs/`,
`shared/`, `ios/`, `web/`, then hand-sorted from barbell plate math and profile photos, which are not the plate journal.

Three distinctions the map relies on:

- **Action.** *delete* = remove outright · *rewrite* = keep the surface, take the meal out of it · *no-op* = mentions meals but changes
  nothing · **no-op (vector-bound)** = code that MUST stay because an append-only vector exercises it (below).
- **GAP.** Which of A22's four open rulings the row waits on — G1 streak on rest days · G2 photos on workout posts · G3 under-18 users ·
  G4 Home's log rows — or `—` when the row follows from the ruling itself.
- **The vector constraint.** 21 vectors carry a `meal` (or `text`) post in their fixture (§ Vectors). Vectors are append-only and a red
  vector blocks every merge, so the ENGINE's `meal`/`text` post kinds, `day.meals`, `xpMealPost` and `mealXpDailyCap` cannot be deleted
  by this removal — they stay as a fixture-only branch that no route accepts and no client can reach. Removing them is a separate
  owner ruling that RETIRES vectors, which the standing orders do not permit; G1's answer adds a registry entry plus NEW vectors instead.

Counts: 21 meal-carrying vectors (V01, V03, V09–V12, V13–V15, V17, V18, V18b, V20, V21, V24, V26, V28, V29, V35, V36, V43) ·
`shared/seed/meal-outlines.json` does NOT exist (clause ① named it as a planned file; nothing to delete) · 2 constants vector-bound
(`xpMealPost`, `mealXpDailyCap`) · 4 G10 meal-tag constants deletable · 2 iOS screens and 1 web page deletable outright.

## Spec sections (`docs/crew-mvp-spec.md`) — markers under A22 once ratified; the text is never rewritten (A21's rule)

| line | What it assumes | Action | GAP |
|---|---|---|---|
| 4 | the product sentence: "log your workout or snap your meals" | rewrite (marker: the daily habit is the workout post; meals are private macros) | G1 |
| 100 | 1D bridge: rest day → "Start your streak — post a meal" (camera-first) | rewrite — the rest-day bridge CTA needs a new subject | G1, G4 |
| 132 | Flow 2, 8:30 PM: "Dinner → tap [+] → camera → snap → 🍽 pre-tagged → posted" | delete | — |
| 215–240 | Flow 4 entire: camera-first, time-smart tags, "Same as yesterday", text-only is legit, no filters, same-day backfill, 3-meal XP cap, the plate journal, rhythm reminder | delete (the section head carries "Superseded by A22") | — |
| 245 | Flow 4's permanent rejections + "the plate journal stays numberless" | rewrite — the rejections stand; the plate-journal clause is moot | — |
| 247 (clause ①) | seed-data assertion over meal outlines (already moved to the fast-food seed by A21.5) | no-op | — |
| 249 (clause ③) | a macro entry earns no XP, breaks no streak | no-op — unless G1 answer (b) narrows it | G1 |
| 252 (clause ⑥) | "the plate journal stays numberless: JournalFacts.line renders 'Dinner · 4:31 PM'" | rewrite — moot: there is no plate journal to keep numberless | — |
| 259 | Flow 5 rest day: "most people drop a 15-second meal photo" | rewrite | G1 |
| 332, 334 | Flow 9 layer 1: "tap a day → workout + plates"; "meals/week" | rewrite (plates go; meals/week becomes a macro-days count or goes) | G3 |
| 354 (E1) | profile picture via the in-app camera or the library | no-op — the camera stays for the profile picture | G2 |
| 358 (E3) | "Captions editable, photos not" | rewrite | G2 |
| 362 (E5) | "camera denied → text-first posting" | rewrite (only a workout selfie remains to deny, if G2 keeps it) | G2 |
| 372 (E9) | "photos crew-only" | rewrite | G2 |
| 376 (E16) | all-rest plans: "streak runs on meal posts" | rewrite — the whole clause depends on G1 | G1 |
| 382 (E19) | failed uploads: Retry / Post without photo / Delete | rewrite — narrows to workout photos, or deletes | G2 |
| 446 (Part IV) | web parity list: "nutrition posting (browser camera + file upload)" | delete from the list | — |
| 450 (Part IV) | Vercel Blob (photos, presigned) | no-op (profile photos) or narrow | G2 |
| 465 (Part IV table) | "+15 meals ×3" in the XP row | rewrite (the constant stays vector-bound; the promise leaves the table) | — |
| 471 (Part IV table) | "food = photos, and optionally your own numbers — never ours" | rewrite → "food = your own numbers — never ours" | — |
| 625 (5.2 tree) | Post/ NutritionPostScreen · CameraCapture · PostComposer · PostModel | rewrite (CameraCapture stays for the profile picture; the other three go) | G2 |
| 649 (5.2 tree) | CameraDeniedTests.swift | rewrite | G2 |
| 835 (5.6.2) | HomeModel TodayState `rest(posted: Bool)` | rewrite — "posted" on a rest day is G1's word | G1 |
| 851 (5.6.2) | PostModel state: mode(.camera\|.library\|.text), photo?, caption, mealTag, shareToCrew | delete | G2 |
| 869 (5.6.2) | ProgressModel select(dayKey) → DayDetail (workout + plates) | rewrite | — |
| 1030 (S07) | bridge state; rest-day CTA absorbs the meal | rewrite | G1, G4 |
| 1046 (S11) | Nutrition post screen criteria | delete (marker) | — |
| 1062 (S15) | heat-map day-tap opens workout + plates; meals/week stat | rewrite | G3 |
| 1084, 1090 (8.1) | vector descriptions V03/V12 (meal post), V24/V26 (meal XP) | no-op — the catalog is history; the fixtures stay green | G1 |
| 1113 (8.2 Posts) | fitness/meal/text-only creation; EXIF fixture; 3-meal cap server-enforced | rewrite | G2 |
| 1131 (8.4) | journey ① "… first workout … → post → celebration"; CameraDenied state probe posts a meal | rewrite | G1, G2 |
| 1136 (8.6) | offline matrix: post queued with chip; 24 h failed upload choice | rewrite | G2 |
| 1150 (Part IX) | Post (type: workout\|meal\|text, photoKey?, caption≤280, mealTag?) | rewrite — type meal/text and mealTag leave the writable shape | G2 |
| 1266 (T027), 1288 (T040) | ledger wording: nutrition posting; plate journal | no-op (complete as built; a marker says so) | — |
| 1520 (Appendix A 2026-09-04) | "Nutrition: the plate journal is photo/text only … camera + library · time-smart tags · same-day backfill · 3-meal XP cap" | marker "Superseded by A22" | — |
| 1526 (A3) | "a way to post a meal" on every non-bridge state; a camera toolbar button | marker | G4 |
| 1529 (A14) | the three-slot Workout · Cardio · Meals row; a cardio post type | marker (the row's third slot is G4) | G4 |
| 1541 (A17.3) | "Post a meal" offered three ways → the vector row is the way | marker | G4 |
| 1545–1556 (A18.4, A18.5, A18.9, A18.10) | the rest card's premise ("Rest days count too — post anything…"), "Log a meal" verb row, the all-done card's outline "Post a meal", the toolbar camera dropped where the card offers a meal | markers | G1 (A18.4), G4 (rows) |
| 1531 (A16 ratification) + 1534 (A16.c) | the 18+ gate hides the macro surface; under-18 users "get the numberless plate journal exactly as today" | marker — the under-18 fallback no longer exists | G3 |
| 1581 (A21.5) | "Stage 1 … replaces A16's scope"; the plate journal implicitly stays | rewrite by A22: nutrition is macro logging only | — |

## Other docs

| file:line | What it assumes | Action | GAP |
|---|---|---|---|
| `docs/mvp-definition.md:22` | flow 5: "rest-day Home → a meal post keeps the streak" | rewrite — marked pending G1 (this commit) | G1 |
| `docs/mvp-definition.md:32` | A21.5 row | rewrite — gains "the plate journal is removed" (this commit) | — |
| `docs/mvp-definition.md:60` | W4: "the profile-photo prompt at first crew join (1C)" — 1C also says "or first share" | no-op (profile photo) | G2 |
| `docs/mvp-definition.md:61` | W5: photos auth-checked end to end | rewrite if photos leave except profile | G2 |
| `docs/nutrition-addendum-draft.md:104` | §8 "photos inside Nutrition (photos stay in the plate journal)" | struck (this commit) | G2 |
| `docs/api.md:60–61` | POST photos purpose ∈ {post, profile}; GET photos/[key] (own photo or a crew-mate's post photo) | rewrite | G2 |
| `docs/api.md:83` | POST posts { type: workout \| meal \| text, photoKey?, caption?, mealTag?, … } | rewrite — no client creates a post through this route once meals go (workout posts ride PATCH sessions) | G2 |
| `docs/api.md:86` | PATCH posts/[id] { caption } | rewrite/delete | G2 |

## Seed

| file | What it assumes | Action | GAP |
|---|---|---|---|
| `shared/seed/meal-outlines.json` | named by clause ① as the meal-outline seed | no-op — the file was never created; A21.5 already moved clause ① to the fast-food seed | — |
| `shared/seed/achievements.json` `first-flame` (trigger `postsTotal` ≥ 1) | any post — a meal today — lights First flame | rewrite/no-op — with meals gone, `postsTotal` counts workout posts; whether a macro log counts is G1 (b) | G1 |

## Constants (`shared/spec-constants.json`) — no edit in this commit

| line | Constant | Action | GAP |
|---|---|---|---|
| 26 | `xpMealPost` 15 | **no-op (vector-bound)** — V26/V28 and the meal-carrying streak vectors need the engine's meal XP branch | G1 |
| 27 | `mealXpDailyCap` 3 | **no-op (vector-bound)** — V26 | G1 |
| 52 | `captionMaxChars` 280 | rewrite (workout captions only) or delete | G2 |
| 131–134 | `mealTagBreakfastFromMinute` · `mealTagLunchFromMinute` · `mealTagDinnerFromMinute` · `mealTagDinnerUntilMinute` (G10) | delete — only the MealTag twin reads them, and no vector does | — |
| 154 | `textOnlyPostMaxTaps` 3 (S11) | delete | — |
| 155 | `nutritionPostTargetSeconds` 15 (Flow 4 "under 15 seconds") | delete | — |
| 166 | `photoPostOptimisticMaxMs` 500 (6.2 shutter → posted) | rewrite (workout selfie) or delete | G2 |
| 174, 176–181 | `imageUploadMaxKb`, the `photos` block (edge px, JPEG quality, source MB) | no-op — the profile-picture pipeline is the same code | G2 |
| 193 | `captionComposerMaxLines` 3 (S11 caption field) | delete (S11 goes) or rewrite (workout caption) | G2 |
| 202 | `failedUploadChoiceAfterHours` 24 (E19) | rewrite/delete with E19 | G2 |

## Vectors (`shared/vectors/*.json`) — LISTED, never edited

| file | Vectors whose fixture carries a meal or text post | Action | GAP |
|---|---|---|---|
| `streak.vectors.json` | V01 first-ever post (meal) · V03 rest day + meal post → +1 · V09 west travel (meal) · V10 east travel (meal) · V11 two posts same day (meal) · V12 all-rest plan: meal posts sustain | no-op — stay green: the engine keeps `meal`; the ROUTE stops accepting it | G1 |
| `shields.vectors.json` | V13 · V14 · V15 · V17 · V18 · V18b — daily meal posts fill the week around the workouts | no-op (vector-bound) | G1 |
| `pause.vectors.json` | V20 posts during pause (meal) · V21 pause ends (meal) | no-op (vector-bound) | G1 |
| `xp.vectors.json` | V24 first post of day = 25 (kind text) · V26 4th+ meal = 0 XP (+ `day.meals`) · V28 perfect week (meals) · V29 comeback (meal) | no-op (vector-bound) | G1 |
| `completion.vectors.json` | V35 achievements survive undo (meal) · V36 editing yesterday's reps (meal) · V43 deleting a rolled-over post (meal) | no-op (vector-bound) | G1 |
| `streak.vectors.json` V04 | rest day, silence → streak 0 at 3 AM — the rule G1 pivots on | no-op; G1's answer ADDS vectors beside it | G1 |
| `shared/vectors/README.md:43` | `postCreated { kind: workout\|meal\|text, … }` in the fixture contract | no-op — the contract describes the fixtures that exist | G1 |
| reserved V57–V65 (A16/A21.5) | V63 macro entry earns no XP; V65 under-18 unreachable | no-op — G1 (b) would need V63's sibling: "a macro log sustains the streak, earns nothing" | G1, G3 |

## Engines (twins)

| file:line | What it assumes | Action | GAP |
|---|---|---|---|
| `ios/Crew/Engine/GamificationEngine.swift:16,68,79` · `web/src/lib/engine/gamification.ts:17,53,61,94` | `day.meals`, `PostKind` meal\|text, `XpReason.meal` | **no-op (vector-bound)** | G1 |
| `ios/Crew/Engine/GamificationPost.swift:86–88` · `web/src/lib/engine/gamification-post.ts:95–97` · `gamification-day.ts:41` | meal XP up to the cap; `day.meals += 1` | **no-op (vector-bound)** | G1 |
| `ios/Crew/Engine/MealTag.swift` · `web/src/lib/engine/meal-tag.ts` (+ `mealTagEmoji`) | time-smart tags from the G10 minutes | delete (with `meal-tag.test.ts` and `SessionModelTests.testPlateMathAndMealTags:122–128`) | — |
| `ios/Crew/Features/Progress/JournalFacts.swift:3,73–75` · `web/src/app/(app)/journal/rows.ts:2,11,26–35` | the journal line "Dinner · 4:31 PM (· earlier today)" | delete the meal branch (the workout/cardio lines stay) | — |
| `web/src/lib/gamification-store.ts` (cardio → workout mapping) | the boundary map, `post-types.test.ts` | no-op | — |

## Server (routes, libs, documents)

| file:line | What it assumes | Action | GAP |
|---|---|---|---|
| `web/src/app/api/v1/posts/route.ts` · `web/src/lib/posts.ts:11,15,33,46,68–70` | POST posts creates meal/text posts with photoKey, caption, mealTag, earlierToday | rewrite — no client creates a post here once meals go (workout posts ride PATCH sessions `post`); delete the route or keep GET only | G2 |
| `web/src/lib/validate-posts.ts:10,14,22` | `type` enum workout\|meal\|text; `mealTag`; "a meal needs a photo or text" refine | rewrite — the writable types shrink; the refine goes | G2 |
| `web/src/lib/validate-posts.ts:12–13,25` | photoKey, caption ≤ captionMaxChars; PATCH caption | rewrite/delete | G2 |
| `web/src/lib/sync-ops.ts:35–40` (`createPost`, `deletePost` ops) | the iPhone's queued meal posts | rewrite — the op kinds stay accepted so an older phone's queued meal is rejected per op (the W3 `chatRetired` shape), never as a batch error | — |
| `web/src/lib/documents-social.ts:14,18` | `PostDoc.type` includes meal\|text; `mealTag` | rewrite (legacy rows keep the field; nothing writes it) | G2 |
| `web/src/app/api/v1/photos/route.ts:16–21` · `web/src/lib/photos.ts:15–28` | `purpose` ∈ {post, profile}; readable by a crew-mate for a post photo | rewrite — `post` purpose survives only if G2 keeps workout photos | G2 |
| `web/src/lib/blob.ts` | the strip/resize pipeline | no-op (profile pictures) | G2 |
| `web/src/lib/home-facts.ts:14,30–45` · `web/src/lib/today-state.ts:39` | `VectorSlots.meals` = today's meal posts | rewrite — the third slot becomes G4's row | G4 |
| `web/src/lib/progress-facts.ts:1,18,34` | `WeekRecord.meals` (meals/week) | rewrite/delete | G3 |
| `web/src/lib/plans.ts:56` | comment: meal posts stamp isPlannedDay | rewrite | G1 |
| `web/src/app/api/cron/notifications/route.ts:46` | streak-risk push: "Nothing posted yet today. A plate counts." / "A meal photo keeps it alive." | rewrite — the copy names the plate journal; G1 decides what a rest day asks for | G1 |
| `web/src/lib/notification-facts.ts:34–53` | `postedToday` = any post today | rewrite per G1 | G1 |
| `web/src/lib/export.ts` · `web/src/lib/account-delete.ts` (posts, photos) | export and cascade cover meal posts and their photos | no-op (legacy rows still export and cascade) | — |
| `web/src/lib/api-client.ts` (createPost/uploadPhoto/patchPost) · `web/src/lib/api-client-crew.ts:9` (`StreamPost.mealTag`) | the web client's post calls; the stream's meal tag | delete/rewrite | G2 |

## Web client

| file:line | What it assumes | Action | GAP |
|---|---|---|---|
| `web/src/components/PostComposer.tsx` (whole) | S11: camera/file upload, tag picker, caption, "Same as yesterday", Post | delete | — |
| `web/src/app/(app)/post/page.tsx` (whole) | the /post route; yesterday's meal for the ↻ chip | delete | — |
| `web/src/app/(app)/home/page.tsx:2,122–126` | the toolbar camera "Post a meal" → /post on non-rest states (A3, A18.10) | delete | G4 |
| `web/src/app/(app)/home/TodayCard.tsx:11,37–40,51,80` | rest-day primary "Post a meal"; bridge label "Start your streak — post a meal"; the A18.4 premise/stake lines | rewrite | G1, G4 |
| `web/src/components/VectorRow.tsx:1,6,40` | "Log a meal" row → /post, status = meal count | rewrite → "Log macros" → nutrition Today (and its gated-off state) | G4 |
| `web/src/components/StreamList.tsx:25` | the meal emoji on a stream card | delete the branch (only workout cards remain) | — |
| `web/src/components/CrewView.tsx:23` | solo explainer "Post a workout or a meal photo." | rewrite | — |
| `web/src/app/(app)/journal/JournalDay.tsx:22` · `journal/page.tsx:22` | the post photo + "Your plate" alt; empty copy "Workouts and meals stack up" | rewrite | G2 |
| `web/src/app/(app)/progress/page.tsx:1–2,25,44,54` | day detail lists non-workout posts (plates); meals/week in the totals line; empty copy | rewrite | G3 |
| `web/src/components/HeatMap.tsx:1` | comment: tap a day → workout + plates | rewrite | — |
| `web/src/components/ProfileForm.tsx` · `SettingsView.tsx` | the profile photo upload (purpose profile) | no-op | G2 |

## iOS client

| file:line | What it assumes | Action | GAP |
|---|---|---|---|
| `ios/Crew/Features/Post/NutritionPostScreen.swift` (whole) | S11: camera-first, permission-denied state, library, caption, Post | delete | — |
| `ios/Crew/Features/Post/PostComposer.swift` (whole) | meal-tag chips, the ↻ chip, caption field | delete | — |
| `ios/Crew/Features/Post/PostModel.swift` (whole) | mode(.camera\|.library\|.text), photo, caption, mealTag, `yesterdaysMeal`, `submit()` (type meal/text, local photo, createPost op) | delete | G2 |
| `ios/Crew/Features/Post/CameraCapture.swift` | the camera picker; `isAvailable` | rewrite — keep for the profile picture (`EditProfileModel.swift:22,56`) and, if G2 keeps it, the workout selfie | G2 |
| `ios/Crew/Features/Home/HomeScreen.swift:3,33,96,124,143–145` | the toolbar camera "Post a meal"; `posting` sheet → NutritionPostScreen | delete | G4 |
| `ios/Crew/Features/Home/TodayCard.swift:3,12,20,80,107–121` | rest-day primary "Post a meal"; bridge label "Start your streak — post a meal"; the A18.4 premise ("Rest days count too — post anything…") and "Today counts." | rewrite | G1, G4 |
| `ios/Crew/Features/Home/VectorRow.swift:1,6,41,49` | "Log a meal" row, `onMeal`, meal count | rewrite → "Log macros" → nutrition Today | G4 |
| `ios/Crew/Features/Home/HomeModel.swift:30,90` · `HomeModel+Facts.swift:4–7,23,100–104` | `VectorSlots.meals` from today's meal posts | rewrite | G4 |
| `ios/Crew/Features/Home/TodayState.swift` (`rest(posted:)`) | "posted" on a rest day means any post | rewrite per G1 | G1 |
| `ios/Crew/Features/Crew/PostCard.swift:28` | the meal emoji on a stream card | delete the branch | — |
| `ios/Crew/Features/Crew/CrewSoloView.swift:14` · `CrewScreen.swift:64` | "Post a workout or a meal photo." · "Post a workout or a plate…" | rewrite | — |
| `ios/Crew/Features/Progress/JournalRow.swift:13` | photo label "Your plate" | rewrite/delete | G2 |
| `ios/Crew/Features/Progress/JournalScreen.swift:38` | empty copy "Workouts and meals stack up day by day." | rewrite | — |
| `ios/Crew/Features/Progress/ProgressModel.swift:2,24,41,108,151–156` | `RingRecord.meals`, `DayDetail.plates` | rewrite/delete | G3 |
| `ios/Crew/Features/Progress/ProgressScreen.swift:1–2,30,70,96–103` · `HeatMapView.swift:1` | plates in the day card; meals in the totals line; empty copy | rewrite | G3 |
| `ios/Crew/Storage/ModelsSocial.swift:12,17,28,34` | `LocalPost.type` workout\|meal\|text, `mealTag`, `localPhotoPath` | rewrite (legacy rows keep decoding; nothing writes meal) | G2 |
| `ios/Crew/Storage/ServerHydrate.swift:77` | hydrates meal posts with their tags | rewrite | — |
| `ios/Crew/Api/ApiSessions.swift:69,85,91` | DTOs carry `mealTag` | rewrite | — |
| `ios/Crew/Storage/SyncTransport.swift:1–15` · `SyncDelivery.swift:11–51` · `PostPayloadPhotoStripper.swift` · `SyncQueueHeld.swift` · `FailedUploadSheet.swift` | the two-step photo post (upload → createPost op), E19's 24 h choice "Post without photo" | rewrite/delete with E19 | G2 |
| `ios/Crew/Api/ApiPhotos.swift:25–33` | `uploadPhoto(purpose:)` | no-op (profile) | G2 |
| `ios/Crew/Features/Settings/EditProfileModel.swift:2,22,49–56` | profile picture via camera/library, purpose profile | no-op | G2 |
| `ios/Crew/Features/Session/SessionActions.swift:95–101` | the workout post created at completion (type workout/cardio) | no-op | — |

## Tests and journeys

| file:line | What it assumes | Action | GAP |
|---|---|---|---|
| `web/tests/api/posts.test.ts:1–2,14,37–50,64` | meal/text creation, the 3-meal XP cap (V26), "a meal needs a photo or text", caption limit | rewrite — the cap test moves to the vector suite it duplicates; creation via session completion | G2 |
| `web/tests/api/photos.test.ts` (16 hits) | EXIF/GPS fixture uploaded with purpose post; crew-mate read | rewrite (purpose profile, or workout photo) | G2 |
| `web/tests/api/sync.test.ts:26–31,47,72–88` | replayed meal posts and a meal delete | rewrite | — |
| `web/tests/api/today-state.test.ts:45–46,96–234` | `postMeal()` leaves the bridge; `vectors.meals` = 1 | rewrite — the bridge exit becomes a completed workout; the slot is G4's | G1, G4 |
| `web/tests/api/account.test.ts:34` · `crews.test.ts:62` · `messages.test.ts:34` (the W3 wip renames it) · `metrics.test.ts:17` · `achievements.test.ts:30–33` | a meal post as the fixture's "any post" | rewrite (a workout post) | G1 |
| `web/tests/api/post-types.test.ts:5,77–78` | `PostKind` meal at the boundary; `isRestDay` with a meal | rewrite | G1 |
| `web/tests/api/standing-registry.ts` (`posts:POST` validBody) | a meal body | rewrite | G2 |
| `web/tests/engine/validators.test.ts:26–27` | "a meal needs a photo or a line of text" | rewrite | G2 |
| `web/tests/engine/meal-tag.test.ts` | the G10 boundaries | delete | — |
| `web/tests/e2e/journey1.spec.ts:6–12` | the first flame lit by a meal post (rest-day branch) | rewrite | G1 |
| `web/tests/e2e/journey2.spec.ts:7,11` · `journey3-invite.spec.ts:14,37` | meal posts light the flame / fill the stream | rewrite (workout posts) | — |
| `web/tests/e2e/a11y.spec.ts:62,73` · `home-layout.spec.ts:61,138,144` | fills the caption "Say something (or don't)" and posts; asserts the "Log a meal" row | rewrite | G4 |
| `web/tests/e2e/warm-up.ts` (`posts/warm-up`, `/post` page) | warms the post page | rewrite | — |
| `ios/CrewUITests/CameraDeniedTests.swift` (whole) | the state probe posts a meal text-first | delete (or rewrite around the workout selfie if G2 keeps it) | G1, G2 |
| `ios/CrewUITests/Journey1_NewUserTests.swift:86` | the meal-post branch of journey ① | rewrite | G1 |
| `ios/CrewUITests/Journey2_FastLogTests.swift:21,38–39` | `seed.postMeal`; waits for "Post a meal" as the Home landmark | rewrite | G4 |
| `ios/CrewUITests/HomeStatesTests.swift:6,26,33,50,61–75` | `seed.postMeal` leaves the bridge; the "Log a meal" verb; the toolbar-camera absence | rewrite | G1, G4 |
| `ios/CrewUITests/SeedClient.swift` (`postMeal`) | seeds a meal post through the API | rewrite (a completed workout) | G1 |
| `ios/CrewTests/HomeVectorSlotsTests.swift:2,38,147–155` | meals count meal posts | rewrite | G4 |
| `ios/CrewTests/HomeModelEdgeTests.swift:29` · `SyncDeliveryTests.swift:23` | a meal `LocalPost` fixture | rewrite | G2 |
| `ios/CrewTests/SessionModelTests.swift:2,122–128` | MealTag boundaries | delete the meal half | — |
| `ios/CrewUITests/Screenshots.swift` · `JourneySteps.swift:10,39` | "S11 post — camera off" screenshot; CameraDenied in the wait-tuning note | rewrite | — |

## Not affected (checked)

Workout posts and their creation at session completion · the crew stream's post cards, reactions and system lines · the pulse · the
gamification engine's workout/bonus/comeback/shield/pause rules and every vector that carries no meal · profile pictures (E1, A7) and
the photo pipeline they use · plate MATH (barbell plates, `PlateMath.swift` / `plate-math.ts`) — a different plate.
