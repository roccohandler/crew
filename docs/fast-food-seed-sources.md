# Fast-food seed — sources, and the chains that are held

The nutrition addendum (§5, ratified 2026-09-18) asks for a curated seed "from the chains' published nutrition facts". Every number in
`shared/seed/fast-food.json` was read on the date shown from the chain's OWN publication — never from an aggregator, never from memory.
A chain that could not be read that way, or whose rows are not usable as they are published, is HELD here with its reason and its verified
rows, so the owner can release it with one edit (move the rows into the seed and raise `fastFoodChainCount`).

## Shipped

| Chain | Items | Source | Read on |
|---|---|---|---|
| Chick-fil-A | 15 | https://www.chick-fil-a.com/nutrition-allergens | 2026-09-18 |
| Chipotle | 15 | https://www.chipotle.com/content/dam/chipotle/menu/nutrition/US-Nutrition-Facts-Paper-Menu-3-2025.pdf | 2026-09-18 |
| Panera Bread | 15 | https://www.panerabread.com/content/dam/panerabread/documents/c8-26-nutrition-guide.pdf | 2026-09-18 |
| Starbucks | 15 | https://www.starbucks.com/menu | 2026-09-18 |
| Subway | 15 | https://media.subway.com/dam/urn:aaid:aem:2278372c-147b-42f2-8edc-7d8d94d1f07e/original/as/us-nutrition-en.pdf | 2026-09-18 |
| Wendy's | 15 | https://order.wendys.com/us/en/national/menu | 2026-09-18 |

## Held (not in the app)

### Burger King — held

The only readable official document is Burger King's USA nutrition PDF dated NOVEMBER 2022; the current publication (the BK Nutrition Explorer) is a JavaScript-only app that could not be read, so the rows could not be confirmed against what BK publishes today. Held for the owner.

Source: https://bk-use1-prod.sites.rbictg.com/nutrition/nutrition.pdf · read 2026-09-18

| Item | Serving | P | C | F |
|---|---|---|---|---|
| Whopper | 1 sandwich | 31 | 54 | 39 |
| Whopper with Cheese | 1 sandwich | 36 | 56 | 46 |
| Double Whopper | 1 sandwich | 52 | 54 | 58 |
| Whopper Jr. | 1 sandwich | 15 | 30 | 18 |
| Hamburger | 1 sandwich | 13 | 29 | 10 |
| Cheeseburger | 1 sandwich | 15 | 30 | 13 |
| Double Cheeseburger | 1 sandwich | 24 | 30 | 21 |
| Bacon Cheeseburger | 1 sandwich | 18 | 30 | 16 |
| Original Chicken Sandwich | 1 sandwich | 23 | 63 | 39 |
| Chicken Jr. | 1 sandwich | 13 | 39 | 27 |
| Chicken Nuggets | 10pc | 22 | 30 | 31 |
| French Fries | medium | 5 | 54 | 16 |
| Onion Rings | medium | 4 | 48 | 16 |
| Sausage, Egg & Cheese Biscuit | 1 sandwich | 20 | 32 | 39 |
| Bacon, Egg & Cheese Biscuit | 1 sandwich | 15 | 32 | 26 |

### Five Guys — held

Five Guys' current official guide (September 2026 PDF) publishes macros per COMPONENT only — there is no row for a hamburger, a cheeseburger or a hot dog as sold — and its patty row does not reconcile with its own printed calories. A burger chain without a burger is not a useful one-tap list; held for the owner.

Source: https://www.fiveguys.com/wp-content/uploads/2026/09/Five-Guys-US-Nutrition-Allergen-Guide-English-September-2026.pdf · read 2026-09-18

| Item | Serving | P | C | F |
|---|---|---|---|---|
| Hamburger Patty | 1 patty (65 g) | 16 | 0 | 17 |
| Hamburger Bun | 1 bun (77 g) | 7 | 35 | 8 |
| Cheese | 1 slice (19 g) | 3 | 1 | 6 |
| Bacon | 2 pieces (14 g) | 5 | 0 | 6 |
| Hot Dog (meat only) | 1 hot dog (90 g) | 11 | 1 | 26 |
| Hot Dog Bun | 1 bun (71 g) | 6 | 33 | 7 |
| Little Five Guys Style Fries | little (227 g) | 8 | 72 | 23 |
| Regular Five Guys Style Fries | regular (411 g) | 15 | 131 | 41 |
| Large Five Guys Style Fries | large (567 g) | 20 | 181 | 57 |
| Regular Cajun Style Fries | regular (416 g) | 15 | 134 | 41 |
| Large Cajun Style Fries | large (572 g) | 20 | 184 | 57 |
| Vanilla Shake Base | 315 g | 10 | 65 | 25 |
| Mayonnaise | 14 g | 0 | 0 | 11 |
| Peanuts | 1 oz (30 g) | 7 | 5 | 14 |
| Ketchup | 17 g | 0 | 5 | 0 |

### McDonald's — held

Verified against McDonald's own nutrition endpoints (the data its calculator and product pages load), but NOT fetchable via WebFetch: every mcdonalds.com URL timed out and the rows were read by a script presenting browser headers. The owner's rule is 'published sources fetchable via WebFetch' — held for the owner's approval.

Source: https://www.mcdonalds.com/us/en-us/about-our-food/nutrition-calculator.html · read 2026-09-18

| Item | Serving | P | C | F |
|---|---|---|---|---|
| Big Mac | 1 sandwich | 25 | 45 | 34 |
| Quarter Pounder with Cheese | 1 sandwich | 30 | 42 | 26 |
| Double Quarter Pounder with Cheese | 1 sandwich | 48 | 43 | 42 |
| Cheeseburger | 1 sandwich | 15 | 31 | 13 |
| Double Cheeseburger | 1 sandwich | 25 | 34 | 24 |
| McDouble | 1 sandwich | 22 | 32 | 20 |
| McChicken | 1 sandwich | 14 | 38 | 21 |
| McCrispy | 1 sandwich | 26 | 46 | 20 |
| Filet-O-Fish | 1 sandwich | 16 | 38 | 19 |
| Chicken McNuggets | 10 piece | 23 | 26 | 24 |
| Egg McMuffin | 1 sandwich | 17 | 30 | 13 |
| Sausage McMuffin with Egg | 1 sandwich | 20 | 30 | 31 |
| Hash Browns | 1 order | 2 | 18 | 8 |
| World Famous Fries | Medium | 5 | 43 | 15 |
| Ranch Snack Wrap | 1 wrap | 17 | 32 | 23 |

### Taco Bell — held

No protein / carbohydrate / fat number is published on any Taco Bell-owned host: every tacobell.com nutrition page is a shell around a Nutritionix-hosted table, product pages carry calories only, and no tacobell.com US nutrition PDF exists. A third-party host is not the chain's own publication, so nothing was recorded. Held for the owner: if the Nutritionix brand page that tacobell.com itself embeds counts as Taco Bell's official table, 15 items can be read there.

Source: https://www.tacobell.com/nutrition/info · read 2026-09-18

