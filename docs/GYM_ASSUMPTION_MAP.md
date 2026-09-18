# Gym-assumption map

STATUS: EXECUTED in W2 (2026-09-17, commit `feat(gym): A21.1 …`) — every row below was applied on both engines and both clients; the
file stays as the record of what changed and why. Three ids kept their old objects only in the id (couch-stretch, doorway-pec-stretch,
doorframe-row) so saved plans and sessions keep resolving; check-seeds now asserts the gym-only catalog.

Owner decision (2026-09-17): every user has full commercial gym access; home and dumbbell-only training are no longer
supported. This map lists every place the code, seeds, tests or spec assume the old three-tier model
(`fullGym` / `dumbbells` / `bodyweight` "equipment access"), with the change each place needs. Read-only audit at
commit `7fa7e52`; nothing here has been changed. Method: `grep -rn -i "dumbbell|bodyweight|fullGym|full gym|equipmentAccess|
accessFor|access:"` over `ios/`, `web/`, `shared/`, plus a node walk of the two seed files and a grep of the spec.

Two distinctions the map relies on:

- **Access tier vs. equipment tag.** The *tier* (`equipmentAccess`) is the home/dumbbell assumption and goes. The per-exercise
  *tag* (`equipment ∈ barbell|dumbbell|machine|cable|bodyweight`) describes what an exercise uses inside a gym and stays: a
  commercial gym has dumbbells and floor space, so push-ups and dumbbell presses remain valid gym exercises. `fullGym` already
  admits all five tags (`shared/seed/exercises.json:8`), so **no exercise entry needs deleting** — 110 of 110 are usable.
- **Actions.** *delete* = remove outright · *rewrite* = keep the feature, remove the tier/branch · *no-op* = mentions equipment
  but assumes nothing about home training (listed so the sweep is complete).

Counts: 30 of the 45 plan-template lists exist only for the `dumbbells`/`bodyweight` tiers (`node` walk of
`plan-templates.json`: `{ fullGym: 15, dumbbells: 15, bodyweight: 15 }`); the onboarding drops from 3 questions to 2 and the
organic decision count from 5 to 4 (`spec-constants.json:142,148`).

## Seeds and generated files

| file:line | What it assumes | Action |
|---|---|---|
| `shared/seed/exercises.json:8` | `enums.equipmentAccess` defines three tiers; `dumbbells` = dumbbell+bodyweight, `bodyweight` = bodyweight only | rewrite — collapse to the single `fullGym` list or drop the map (every consumer below reads it) |
| `shared/seed/exercises.json:13-…` (110 entries, e.g. `:13` barbell, `:14` dumbbell, `:17` bodyweight) | each exercise carries an `equipment` tag; 26 dumbbell + 53 bodyweight rows were the home-tier pool | no-op — tags stay for chips (S04), swaps and the bodyweight-has-no-weight rule (E7) |
| `shared/seed/exercises.json` `swapRule` text | "candidates with the user's equipment access" | rewrite — wording only |
| `shared/seed/plan-templates.json:23-24` and every `"dumbbells"`/`"bodyweight"` key (30 lists, 45 tier keys in the file) | one exercise list per kind × level × **tier**; the two home tiers are separate lists (e.g. push/brandNew/bodyweight = incline-push-up, push-up, close-grip-push-up, bench-dip) | delete the 30 home-tier lists; keep the 15 `fullGym` lists (rewrite the nesting to `kind.level` or leave `fullGym` as the only key) |
| `shared/seed/plan-templates.json` `gapNotes`, `targets`, `split`, `mobilityBlocks` | days/level/mobility — nothing about equipment | no-op |
| `shared/scripts/check-seeds.mjs:37-41` | `alternativesFor(exercise, access)` counts swap alternatives *per tier* | rewrite — one tier |
| `shared/scripts/check-seeds.mjs:57-70` | walks `templates.kind.level.access`; fails on an exercise "not available with {access}" and on fewer than `swapCandidatesMin` alternatives per tier | rewrite |
| `shared/scripts/check-seeds.mjs:112` | prints "× 3 equipment access = 45 lists" | rewrite |
| `shared/scripts/render-seed.mjs:32-33` | emits `type Equipment` (keep) and `type EquipmentAccess = "fullGym" \| "dumbbells" \| "bodyweight"` | rewrite — drop `EquipmentAccess` |
| `shared/scripts/render-seed.mjs:47` | `templates: Record<WorkoutKind, Record<Experience, Record<EquipmentAccess, string[]>>>` | rewrite |
| `shared/scripts/render-seed.mjs:56` | exports `equipmentAccess` const into `web/src/generated/seed.ts` | rewrite/delete |
| `web/src/generated/seed.ts`, `ios/Crew/Generated/SeedData.swift` | carry the map and the tiered templates verbatim | no-op by hand — regenerate (`npm run generate`; never edited) |
| `shared/spec-constants.json:142` | `onboardingQuestionCount = 3` ("the '1 of 3' whisper") | rewrite → 2 |
| `shared/spec-constants.json:148` | `decisionsBeforeHomeOrganic = 5` "hero, days-confirm, experience, equipment, auth" | rewrite → 4 and the note |
| `shared/spec-constants.json:80` | `swapCandidatesMin = 3` | no-op |

## Engines (twins)

| file:line | What it assumes | Action |
|---|---|---|
| `ios/Crew/Engine/SeedCatalog.swift:52,57,77` | decodes `equipmentAccess: [String: [String]]` from the seed | rewrite/delete |
| `ios/Crew/Engine/PlanGenerator.swift:53` | `workout(kind:experience:access:seed:)` picks `templates[kind][experience][access]` | rewrite — drop `access` (fixed `fullGym`) |
| `ios/Crew/Engine/PlanGenerator.swift:62` | `generatePlan(days:experience:access:seed:)` | rewrite — drop the parameter |
| `ios/Crew/Engine/SwapFinder.swift:11-12` | `swapCandidates(for:access:experience:seed:)` filters by `seed.equipmentAccess[access]` | rewrite — no tier filter (all five tags available) |
| `web/src/lib/engine/plan-generator.ts:66,76` | `workoutFor(kind, experience, access, seed)`, `generatePlan(days, experience, access, seed)` | rewrite — same as Swift |
| `web/src/lib/engine/swap-finder.ts:20-21` | `swapCandidates(incumbent, access, …)`; `available = equipmentAccess[access]` | rewrite |
| `ios/Crew/Engine/SetPrefill.swift:33`, `web/src/lib/engine/set-prefill.ts:28` | comment: a bodyweight exercise has no weight, so reps carry forward | no-op (exercise tag) |

## iOS app

| file:line | What it assumes | Action |
|---|---|---|
| `ios/Crew/Features/Onboarding/PlanQuestionsScreen.swift:95-109` | `EquipmentQuestionScreen` — "What do you have access to?" · Full gym (`building.2`) · Dumbbells (`dumbbell`) · Bodyweight (`house`) | delete |
| `ios/Crew/Features/Onboarding/PlanQuestionsScreen.swift:9-11` | `enum OnboardingQuestion { days = 1, experience, equipment }` | rewrite — two cases |
| `ios/Crew/Features/Onboarding/PlanQuestionsScreen.swift:87` | "Experienced" option uses the `dumbbell` SF Symbol | no-op (an icon, not an assumption) |
| `ios/Crew/Features/Onboarding/PlanQuestionsScreen.swift:171` | "N of `onboardingQuestionCount`" | no-op (constant-driven; the constant changes) |
| `ios/Crew/Features/Onboarding/OnboardingFlow.swift:26-27` | `.experience → .equipment → .reveal` navigation | rewrite — experience advances to reveal |
| `ios/Crew/Features/Onboarding/OnboardingModel.swift:12` | `OnboardingStep.equipment` | delete the case |
| `ios/Crew/Features/Onboarding/OnboardingModel.swift:26` | `var equipment: String?` state | delete |
| `ios/Crew/Features/Onboarding/OnboardingModel.swift:81-84` | `choose(experience:)` sets `step = .equipment` | rewrite — regenerate and go to `.reveal` |
| `ios/Crew/Features/Onboarding/OnboardingModel.swift:86-90` | `choose(equipment:)` regenerates the draft | delete |
| `ios/Crew/Features/Onboarding/OnboardingModel.swift:92-96` | `regenerate()` guards on `equipment` and passes `access:` | rewrite |
| `ios/Crew/Features/Onboarding/OnboardingModel.swift:113-116` | `swapCandidates` guards on `equipment` and passes `access:` | rewrite |
| `ios/Crew/Features/Onboarding/OnboardingModel.swift:139` | `persistDraft` stores `equipment` | rewrite |
| `ios/Crew/Features/Onboarding/DraftStore.swift:10` | `OnboardingDraft.equipment: String?` | rewrite — drop the field (optional, so an old on-disk draft still decodes) |
| `ios/Crew/Features/Plan/WorkoutDraft.swift:38-43` | `access` infers a tier from the gear in the workout ("barbell/machine/cable → fullGym; dumbbell → dumbbells; else bodyweight") — a home-tier plan is assumed possible | rewrite — constant `fullGym` or delete the property |
| `ios/Crew/Features/Plan/WorkoutDraft.swift:146-151` | `swapCandidates` passes `access:` to SwapFinder | rewrite |
| `ios/Crew/Features/Plan/WorkoutDraft.swift:153-157` | `addCandidates` filters the catalog by `seed.equipmentAccess[access]` | rewrite — whole strength catalog |
| `ios/Crew/Features/Session/SessionSwap.swift:15-19` | `access(for:)` — the same tier inference for mid-workout swaps (E7) | rewrite/delete |
| `ios/Crew/Features/Session/SessionSwap.swift:22-24` | passes the inferred access to SwapFinder | rewrite |
| `ios/Crew/Features/Session/SetRow.swift:94,108` | `equipment != "bodyweight"` hides the weight stepper/tape | no-op (E7 "bodyweight = no weight chip", exercise tag) |
| `ios/Crew/Features/Onboarding/SwapSheet.swift`, `Plan/ExerciseSheet.swift:92-103` (`EquipmentChip`) | show the equipment tag | no-op |

## Web app

| file:line | What it assumes | Action |
|---|---|---|
| `web/src/components/onboarding/OnboardingFlow.tsx:22` | `type Step` includes `"equipment"` | rewrite |
| `web/src/components/onboarding/OnboardingFlow.tsx:23` | `Draft.equipment: EquipmentAccess \| null` | delete the field |
| `web/src/components/onboarding/OnboardingFlow.tsx:52-58` | `chooseEquipment` builds the plan and logs funnel prop `equipment` | rewrite — build the plan from the experience answer |
| `web/src/components/onboarding/OnboardingFlow.tsx:64` | `draft.equipment ?? "fullGym"` when re-deriving a swapped row | rewrite |
| `web/src/components/onboarding/OnboardingFlow.tsx:88` | experience answer advances to the `"equipment"` step | rewrite → `"reveal"` |
| `web/src/components/onboarding/OnboardingFlow.tsx:89` | the equipment question: "What do you have access to?" · Full gym 🏢 · Dumbbells 🏋️ · Bodyweight 🏠 | delete |
| `web/src/components/onboarding/OnboardingFlow.tsx:90` | `draft.equipment ?? "fullGym"` for swap candidates | rewrite |
| `web/src/components/onboarding/OnboardingFlow.tsx:94` | `QUESTION = { days: 1, experience: 2, equipment: onboardingQuestionCount }` | rewrite |
| `web/src/components/onboarding/DaysQuestion.tsx:36`, `SingleSelect.tsx:19` | "n of `onboardingQuestionCount`" | no-op (constant-driven) |
| `web/src/lib/plan-draft.ts:38-41` | `accessFor(rows)` tier inference from gear | rewrite/delete |
| `web/src/lib/plan-draft.ts:112` | add-exercise candidates limited to `equipmentAccess[accessFor(...)]` | rewrite — whole strength catalog |
| `web/src/components/SessionSwap.tsx:13-17` | `accessFor` twin | rewrite/delete |
| `web/src/components/SessionSwap.tsx:34,37` | `access` prop → `swapCandidates(incumbent, access, …)` | rewrite |
| `web/src/components/SessionSwap.tsx:52`, `ExerciseSheet.tsx:23` | "Nothing else does this job with your gear." — copy assumes limited gear | rewrite — e.g. "Nothing else does this job." |
| `web/src/components/SessionLogger.tsx:10,100` | passes `accessFor(exercises)` into `SessionSwap` | rewrite |
| `web/src/components/ExerciseSheet.tsx:8,78` | `accessFor(rows)` for editor swaps | rewrite |
| `web/src/components/SetRow.tsx:29` | bodyweight rows render no weight control | no-op |

## Tests

| file:line | What it assumes | Action |
|---|---|---|
| `web/tests/engine/plan-generator.test.ts:11,49` | property test over `accesses = [fullGym, dumbbells, bodyweight]`; asserts every row's equipment ∈ tier | rewrite — one tier |
| `web/tests/engine/plan-generator.test.ts:62,71` | generates `bodyweight` / `dumbbells` plans | rewrite |
| `web/tests/engine/plan-generator.test.ts:68-73` | "experienced = 6 with barbell lifts in a full gym" | rewrite (title only once the parameter goes) |
| `web/tests/engine/swap-finder.test.ts:10,25,36,39` | tier loop; `swapCandidates(bench, "fullGym", …)`, `(couch-stretch, "bodyweight", …)` | rewrite |
| `web/tests/api/plans-sessions.ts:8` | `generatePlan(days, "brandNew", "fullGym", …)` | rewrite — signature |
| `web/tests/e2e/helpers.ts:28` | journey helper clicks "Full gym" | rewrite — the step disappears |
| `web/tests/e2e/journey3-invite.spec.ts:27` | the joiner clicks "Dumbbells" | rewrite |
| `ios/CrewTests/PlanGeneratorTests.swift:12,41,52-54,61-65` | `accesses` loop, per-tier equipment assertion, `access:` arguments | rewrite |
| `ios/CrewTests/SwapFinderTests.swift:22,33` | tier assertion; `access: "fullGym"` | rewrite |
| `ios/CrewTests/OnboardingModelTests.swift:35,59,105` | `model.choose(equipment: …)` incl. `"bodyweight"`, `"dumbbells"` | rewrite |
| `ios/CrewTests/AchievementsLocalTests.swift:14`, `HomeTestFixtures.swift:22`, `SessionModelTests.swift:24` | `access: "fullGym"` argument | rewrite — signature |
| `ios/CrewUITests/Journey1_NewUserTests.swift:36`, `CameraDeniedTests.swift:31`, `OfflineSessionTests.swift:27` | tap `app.buttons["Full gym"]` | rewrite — remove the tap |
| `ios/CrewUITests/SeedClient.swift:43-72` | seeds a bodyweight-only plan (push-up, inverted row, bodyweight squat) | no-op (valid in a gym; optionally rewrite to gym lifts) |
| `web/tests/api/plans-sessions.ts:21,27,48`, `ios/CrewTests/ServerHydrateTests.swift:55,72`, `validators.test.ts:79`, `set-prefill.test.ts:31`, `SetPrefillTests.swift:38` | fixtures with `equipment: "bodyweight"` rows or "bodyweight exercise" prefill cases | no-op (tag semantics unchanged) |

## Spec sections (`docs/crew-mvp-spec.md`)

| line | What it assumes | Action |
|---|---|---|
| 43 | Flow 1 step 2 ③ "What do you have access to?" [Full gym / Dumbbells / Bodyweight] | delete the third question |
| 47 | step 3 "every exercise with equipment tag + sets×reps" | no-op |
| 80 | 1B "Single-select answers (experience, equipment) AUTO-ADVANCE" | rewrite |
| 83 | 1B "Question cards use SF Symbols (dumbbell, figure.strengthtraining, house)" | rewrite |
| 90 | 1C "total decisions before Home: organic 5 (hero, days-confirm, experience, equipment, auth)" | rewrite → 4 |
| 152 | Flow 3 diagram "Incline DB Press [Dumbbells]" | no-op (a gym dumbbell) |
| 360 | E7 "bodyweight = no weight chip" | no-op |
| 550 | 5.2 tree: exercises.json "(… equipment …)" | no-op |
| 552 | 5.2 tree: plan-templates.json "(PPL × experience × equipment + Full-Body A/B)" | rewrite |
| 588 | 5.2 tree: SwapFinder "(pattern+equipment candidates)" | rewrite |
| 802 | 5.6.1 `generatePlan(days:, exp:, equip:, seed:)` | rewrite |
| 808 | 5.6.1 `swapCandidates(for:, equip:, seed:)` | rewrite |
| 812-814 | 5.6.2 OnboardingModel state `equipment?` · action `choose(equipment)` | rewrite |
| 996-999 | S03 "3 questions, all tappable … single-selects auto-advance" | rewrite → 2 questions |
| 1003 | S04 "every exercise shows equipment chip" | no-op |
| 1112 | 8.3 "every days × experience × equipment combo yields a valid plan" | rewrite |
| 1131 | Part IX ExerciseTemplate `equipment` field | no-op |
| 1216-1217, 1238 | T004/T005 seed tasks "(… equipment …)", T020 property test | rewrite (ledger wording) |
| 1498 | Appendix A "equipment asked in onboarding" | rewrite — needs a registry entry recording the overturn (owner) |
| 1506 (A15) | "what-do-you-have-today (Nothing · Dumbbells · Full gym → today's workout rebuilt at that equipmentAccess …)" | rewrite/delete — the first escape hatch loses its meaning; A15 is unbuilt |
| 1554-1555 | Appendix B "pattern + equipment" seed list, "PPL variants × experience × equipment" templates | rewrite |

Not affected (checked): `docs/api.md` (no equipment mentions), the cardio activities (tagged `bodyweight`, walk/run/etc. —
no-op), the mobility blocks, the Full-Body A/B templates (a *days* fallback, already ungenerated per A1), Home, Progress,
Crew, Settings and every route/validator (`validate-plans.ts:16` and `validate-sessions.ts:28` accept any equipment string).
