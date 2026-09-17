# Nutrition addendum — DRAFT for owner ratification (A21.5)

Status: PROPOSAL, NOT RATIFIED. Written 2026-09-17 from the owner's A21.5 ruling (Appendix A). On ratification this document becomes
the A21.5 contract and W8 begins; until then nothing in it is built or stubbed for (Appendix C). It replaces A16's MODEL
(`docs/ux-plan-2026-09-09.md` §7.2–7.3: the "Your usual day" outline seed, Flex, the 50% framing flip). It keeps, unchanged: the
seven no-grade clauses (spec:240) and their enforcement mechanisms, the macro palette with its five redundant encoders (§7.4),
Ember law ⑥'s bounded exception, E1's single-current-bodyweight exception, A16.a (methodology screen), A16.b (age questionnaire —
an owner task recorded before W8 starts), A16.c (18+ gate). A21.5's Not Building list (food search, barcode, food recognition,
third-party nutrition API, calorie coaching copy) governs every line below.

## 1. Scope — Stage 1, as ruled

Daily protein / carb / fat targets derived from body weight and goal, editable in Settings · saved meals entered manually · a daily
meal template (1–6 slots) · one-tap logging from the template · quick-add grams · a Today view with remaining macros · a curated
fast-food seed (~10 chains × ~15 items from the chains' published nutrition facts; chain name and a neutral icon only — no logos, no
food photos). Private and ungamified: never in the feed, the pulse or a profile (clauses ③ ④). Built as the final block before public
launch (W8, after W7), on both platforms (Part IV parity).

## 2. Data model (server collections; the iOS SwiftData twins carry the same fields plus sync bookkeeping)

| Collection | Fields | Invariants |
|---|---|---|
| nutritionTargets | userId UNIQUE · bodyweightValue · bodyweightUnit (lb \| kg — the account's weightUnit at entry) · goal (§3) · proteinG · carbsG · fatG · source (derived \| manual) · updatedAt | one document per user; the only body stat in the system (E1's exception); deleting it deletes the bodyweight with it, one tap; never joined into any social query |
| savedMeals | _id · userId · name ≤ savedMealNameMaxChars · proteinG · carbsG · fatG · source (manual \| seed{chainId, itemId}) · createdAt · deletedAt? | grams are integers within bounds and nothing else is checked (clause ⑤); a seed-sourced meal COPIES the grams at save time, so a later seed edit never rewrites a user's history |
| dayTemplate | userId UNIQUE · slots[] (1 … dayTemplateMaxSlots) of {savedMealId, label} · updatedAt | a slot references a saved meal; deleting the meal removes the slot; the template is a checklist, never a requirement |
| mealLogs | clientId UNIQUE · userId · dayKey (3 AM boundary, device timezone) · savedMealId? · name · proteinG · carbsG · fatG · quickAdd (bool) · createdAt · deletedAt? | idempotent on clientId (8.2 ④); a log is its own object — deleting a photo post never touches it and vice versa (E3's shape); no XP, no streak, no shield, no achievement (V63) |

Cross-cutting: all four are in the JSON export and in the delete cascade (E9); none is ever joined into a stream, pulse or profile
query — asserted by a route test (clause ④); every route is requireUser plus the auto-generated standing checks ①–④. Routes, all under
/api/v1/nutrition: targets GET / PUT / DELETE · saved-meals GET / POST · saved-meals/[id] PATCH / DELETE · template GET / PUT ·
logs GET ?dayKey / POST · logs/[id] DELETE. iOS OpKinds: putNutritionTargets · upsertSavedMeal · deleteSavedMeal · putDayTemplate ·
createMealLog · deleteMealLog — a 5.6.3 map change, carried as a plan note in the W8b commit; the optimistic-write pattern is written
out at each site (C5), no wrapper.

## 3. Target formula — inputs and proposal (every number named in shared/spec-constants.json; every output editable)

Inputs: bodyweight, entered in the account's weightUnit and normalised to kg with the A9 constants · goal. Proposal, maintenance:

| Step | Rule | Proposed constant | Note |
|---|---|---|---|
| energy | kg × kcalPerKgMaintenance | 33 kcal/kg | an intermediate that sizes carbs; shown on the A16.a screen; on Today only if Q2 says so |
| protein | kg × proteinGramsPerKg | 1.8 g/kg | the protein-first rule A16 ratified |
| fat | max(fatFloorFractionOfEnergy × energy ÷ kcalPerGramFat, fatFloorGramsPerKg × kg) | 0.20 · 9 · 0.5 g/kg | A16's floor, verbatim |
| carbs | (energy − protein × kcalPerGramProtein − fat × kcalPerGramFat) ÷ kcalPerGramCarbs, floored at 0 | 4 · 9 · 4 | never negative; a floor hit is a measurement on its own line, never a warning |
| goal | a stored preference {maintain \| lose \| gain} with NO effect on the numbers until Q1 is answered | — | A16 was ratified maintenance-only; a deficit is the owner's call, not the agent's |

Rounding: grams to the nearest macroGramsRoundTo (5), integer arithmetic on both engines (the distanceDecimalScale precedent), so
Swift and TypeScript print the same digit. The user may overwrite any of the three grams; source flips to manual and the derivation
is offered again only from Settings ("Recalculate"). The two factors are proposed as common resistance-training rules of thumb; the
owner picks or replaces them before W8a, and the A16.a methodology screen names them, their sources and the estimate-and-clinician
line — every source linkable.

## 4. The two screens (both platforms; ink acts, macro colours are identity only, state is never colour)

**Today.** Nav title "Today". Three rows P / C / F, each: the letter in ink, `logged / target g`, `N to go` — or `N over` in ordinary
ink on its own line (clause ②) — and a bar in the macro token with the target marker as an ink hairline. Then "Your template": one row
per slot, one tap logs it (✓, undo in place, a skipped slot is simply unlogged). Then "Quick add": three gram steppers (P, C, F) and
Add. Then today's log list, swipe-to-delete with the visible button (6.3). One ink-filled primary, "Log a meal", opens Saved meals.
Five states designed (6.1); the empty state is the template invitation. No ember element and no semantic token ever renders here
(law ⑥'s exception, clause ②). The screen must read fully correctly with every macro token forced to plain ink (§7.4).

**Saved meals & template.** A two-way segment [Saved meals | Template]. Saved meals: the list; "Add a meal" (name + P / C / F grams,
manual); "Add from a chain" (chain list → item list — chain name and neutral glyph, the item's serving label and grams — copied into a
new saved meal, editable). Template: 1–6 slots, add from saved meals, reorder, remove. Settings gains three rows: Nutrition targets
(bodyweight, goal, the three grams, Recalculate), How targets are estimated (A16.a), Delete my nutrition data (two-step, "can't be
undone" — deletes targets + bodyweight + saved meals + template + logs in one cascade). No calorie coaching copy anywhere.

## 5. Fast-food seed schema — `shared/seed/fast-food.json`

```
{ "chains": [{ "id": "chain-id", "name": "Chain Name", "icon": "fork.knife", "sourceUrl": "https://…/nutrition", "retrievedOn": "2026-MM-DD" }],
  "items":  [{ "id": "chain-id/item-id", "chainId": "chain-id", "name": "Item name", "servingLabel": "1 sandwich", "proteinG": 0, "carbsG": 0, "fatG": 0 }] }
```

check-seeds assertions (clause ①'s mechanism moves here from meal-outlines.json): no quality word in any name or label (healthy, clean,
junk, lite, guilt-free, …) · no field beyond the schema — no logo, no image, no rating, no rank · icon from a fixed neutral set
(fork.knife, cup.and.saucer, takeoutbag.and.cup.and.straw, …) · grams are integers within bounds · items sorted by chain then name (a
sort is not a ranking) · fastFoodChainCount and fastFoodItemsPerChainMin met · every item's chain exists · every chain has a sourceUrl
and a retrievedOn date. Proposed chains, strikeable by the owner: McDonald's · Chick-fil-A · Chipotle · Subway · Taco Bell · Wendy's ·
Starbucks · Panera Bread · Burger King · Five Guys. Names appear nominatively as plain text; no marks, logos or photos are shipped.

## 6. Age gate behaviour (A16.c, applied per A21.5)

The Nutrition entry point renders only when currentYear − birthYear ≥ nutritionAdultAgeYears (18) — the arithmetic requireSignupGates
already uses. Birth year ABSENT (a Sign in with Apple account): tapping the entry point asks for the birth year once, with the signup
validators (birthYearMin, the 13+ floor), and stores it on the user — never at launch, never retroactively. Under 18: the entry point
and the Settings rows are absent, with no copy, no upsell, no "unlock at 18" (A16.c). V65 (the surface is unreachable for a
17-year-old fixture) stands on both engines; the app stays 13+ unless the A16.b questionnaire says otherwise.

## 7. Engine twins and vectors (pure functions, identical names; V57–V65 as reserved by A16)

NutritionTargets.swift ⇄ nutrition-targets.ts — deriveTargets(bodyweight, unit) → {proteinG, carbsG, fatG, energyKcal};
MacroDay.swift ⇄ macro-day.ts — remaining(targets, logs) → per macro {logged, target, toGo, over}. Vectors, kind `nutrition`
(README contract extended): V57 derive at 80 kg · V58 derive from 176 lb equals V57 · V59 the fat floor engages at a light bodyweight ·
V60 carbs floor at zero with the overage stated · V61 remaining = target − logged, floored at zero · V62 a template slot logs the saved
meal's grams once (idempotent clientId) · V63 a meal log awards zero XP and does not increment day.meals (load-bearing, clause ③) ·
V64 deleting targets deletes the bodyweight · V65 unreachable for a 17-year-old. `npm run vectors` 56 → 65 on both engines.

## 8. Not Building (this feature)

Food search · barcode · food recognition · third-party nutrition API · calorie coaching copy · any score, grade, colour, rank or label
on a food, a meal or a day · a deficit or weight goal unless Q1 ratifies one, with its own compliance checklist · weight history, trend
or chart · sex, height or age fields beyond the birth year · notifications about macros · macros in the feed, the pulse, a profile or a
share · XP, streak or achievements for entries · photos inside Nutrition (photos stay in the plate journal) · logos or food photos in the
seed · HealthKit or any export beyond the user's own JSON · search or filtering of the seed beyond chain → item.

## 9. Three questions only the owner can answer

1. **Goal.** A16 was ratified maintenance-only ("never a prescribed deficit, never a weight goal"). A21.5 names "goal" as an input. Does
   goal admit lose / gain — a deficit or surplus applied to the energy estimate — and if so by what fixed percentage, with what
   compliance checklist (the A16 ratification required one), and does the 13+ rating survive the A16.b questionnaire with a deficit in it?
2. **Calories.** Does Today show a daily calorie total (in / to go) beside the three macros, or macros only — with energy living solely
   on the methodology screen as the intermediate that sizes carbs?
3. **Entry point.** The five-tab set is ratified and a sixth tab was rejected (A19.4). Where does Nutrition live — a fourth full-width
   verb row on Home ("Track macros"), a third segment on Progress (Charts | Journal | Nutrition), or a Settings row only?
