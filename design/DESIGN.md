# Crew — DESIGN.md

The single place design rules are READ from. It is a **cited digest** of `docs/crew-mvp-spec.md` and its Decision Registry
(Appendix A): every rule below names the section it comes from, and **the spec wins any conflict** (Appendix C). Nothing here is
new. To change a rule, change the spec through a registry entry, then this file. `ui-reviewer` judges screenshots against this
file and the mockups in `design/targets/`. Values live in `shared/design-tokens.json` → `EmberColors` / `EmberTokens`; never type
one inline (C7).

## 1. Colour — 70 / 20 / 10: ink acts, ember rewards (Part III)

| Share | Job | Light tokens |
|---|---|---|
| 70% Canvas | every background | `canvas` #FAF8F5 · `card` #FFFFFF · `hairline` #E9E4DD |
| 20% Ink | ALL text, structure and ALL buttons / CTAs / controls | `inkText` #211D19 · primary = #211D19 fill, #FAF8F5 label · secondary = `controlOutline` #938C83, ink label · `secondaryText` #6F6860 · `missedGray` #A8A29A |
| ≤10% Ember | the reward layer ONLY | `ember` #DF5908 shapes · `emberText` #B84D00 words · `emberTint` #FFEFE3 tints and ring tracks |

- **1.1 Ember is reward-only.** Streak flame, XP count-ups, ring and heat-map fills, PR / comeback / celebration accents — nothing
  else. No button, CTA, link, toggle, tab or any interactive control ever wears orange; navigation and chrome are monochrome
  (Part III law ①).
- **1.2 Scarcity.** Ember appears only when progress is the message. Most screens show ZERO ember at rest (law ④). Onboarding is
  pure ink-on-bone; the first orange a user ever sees is the flame on Home (Part III, Onboarding).
- **1.3 Orange is a shape colour, not a text colour.** Orange words use `emberText` #B84D00 (law ③). The ember shape value is
  #DF5908: the original #FF6600 measured 2.77:1 on the canvas and failed the 3:1 non-text gate (A17.4). #FF6600 is not a token.
- **1.4 Warm neutrals only; no second hue** (laws ②, ⑥). One bounded exception: the three macro identity tokens, nutrition
  surfaces only, never status, and no surface shows an ember element and a macro fill together (A16).
- **1.5 Semantics.** `success` #3E8E5A · `danger` #D64550 (berry, never near orange) · missed = warm gray, never red (Part III).
- **1.6 A control's boundary is `controlOutline`, never `hairline`.** Hairline (1.26:1) is the seam between two surfaces;
  a mark that says "this is a control" must clear 3:1 (A18.11, 6.5).

## 2. Light is the app's face (A21.10 as amended 2026-09-18)

Crew renders LIGHT ALWAYS, whatever the phone is set to. Dark tokens exist in the pipeline (dark lifts ember to #FF7A1F, never
inverts — law ⑤) but no screen is reviewed in dark, and a dark screenshot is a defect.

## 3. Density — screens stay simple (6.9, A25)

> Screens stay simple. No screen overloaded with information; prefer clear, well-sized buttons that navigate to the screen
> holding the information or action. (v1 failure mode.)

- **3.1** A screen has one job and at most one filled (ink) primary button.
- **3.2** Secondary information lives one tap away behind a labelled control, never stacked on the screen that links to it.
- **3.3** When a screen needs a second scroll-length of content to do its job, the content becomes a destination screen — never
  compressed to fit.
- **3.4** Density is never bought by shrinking targets or type (6.3).

## 4. Layout, touch and rhythm (6.3, 6.7, G5, A14)

- **4.1 Spacing scale** 4 / 8 / 12 / 16 / 24 / 32, nothing off-scale (G5). `sectionGap` 24 BETWEEN groups, `rowGap` 8 WITHIN one —
  uniform spacing reads as empty, not composed (A14). Corner radius 16; hairline 1 (design-tokens `sizes`).
- **4.2 Touch targets ≥ 44×44 pt** · primaries in the thumb zone, bottom-anchored even at Pro Max · destructive never adjacent to
  primary · the session screen fully one-handed · every swipe has a visible-button equivalent (6.3, 6.7).
- **4.3** Portrait only. Safe-area-relative, zero hardcoded frames; content that can grow lives in a ScrollView; bottom CTAs sit
  above the home indicator; no truncated CTA label anywhere; nothing scrolls sideways (6.7).
- **4.4 The tab bar is hidden during a workout session** (A21.11). The five-tab bar — Home · Plan · Crew · Progress · Settings —
  is fixed; a sixth tab was considered and rejected (Part VII; Appendix A).

## 5. Feedback and motion (Part III Voice, 6.4)

- **5.1 Haptics only — no sound effects, ever.** The fixed language: `tick` set done · `double` exercise done · `thump` workout
  complete · `softTap` reaction received (6.4, G8).
- **5.2** One spring curve app-wide: response 0.35, damping 0.8 (G5). Celebrations ≤ 2.5 s, skippable on first tap. Reduce Motion
  gets static equivalents with identical information; no meaning by motion alone (6.4).

## 6. States (6.1)

- **6.1** Every screen ships Loading → Success → Empty → Error → Offline, designed, not defaulted.
- **6.2 Loading is never a full-screen skeleton:** the real chrome at once, and the one thing still arriving says so in place
  (owner ruling 2026-09-18, "launch: real UI first").
- **6.3 Empty is an invitation, never an apology,** with exactly one CTA. **Error** = what happened + what to do, one sentence,
  always a retry. **Offline:** the core loop is unaffected; social shows last-synced and one thin banner.

## 7. Accessibility gate (6.5, release-blocking)

Text ≥ 4.5:1 · components ≥ 3:1 · primary CTAs ink-fill (≈15:1) · usable at accessibility-XXL Dynamic Type with no critical action
truncated · VoiceOver 100% labelled · Reduce Motion / Transparency honoured.

## 8. Copy (6.6, Part III Voice)

Warm gym buddy: casual, lightly funny, zero drill-sergeant, zero corporate wellness. Sentence case · contractions · verb-first
CTAs of 1–3 words · no "please" / "successfully" / "!" in system copy · never guilt framing, never red for missed · every
notification names its subject.

---

The four sections below are the OWNER'S, filled after a direction is picked in Claude Design. Until they have content they
carry no rules, and `ui-reviewer` invents none.

## Direction

## Component kit (use X for Y)

## Banned patterns

## Screen jobs

Ratified by the owner 2026-09-18 (Appendix A, A27) as the test `ui-reviewer` applies: the one job each screen exists to do.

**Onboarding**

- Intro: Say what Crew is and let me start, join, or log back in.
- Invite code: Take my friend's code and show me the crew it belongs to.
- Log in: Get me back into my account.
- Days question: Ask which days I train.
- Experience question: Ask how experienced I am.
- Plan reveal: Show me the week you built and let me change exercises I don't want.
- Save / sign up: Keep this plan by making me an account.

**Home**

- First day (bridge): Get me into my first workout.
- No plan: Get me to build a plan.
- Training day: Tell me what I'm training today and start it.
- Rest day: Tell me today is rest and keep my streak safe.
- Done: Confirm today is finished and show what I did.
- Paused: Remind me the plan is paused and let me end it.
- Rebuild sheet: Ask which days I train now.
- Bonus sheet: Let me pick a workout that isn't today's.
- Cardio log: Log the cardio I just did in a few taps.
- Reminder opt-in: Ask whether I want a nudge on workout days, and when.

**Plan**

- Week map: Show my week at a glance and let me change it.
- Change days: Ask which days I train from now on.
- Workout editor: Let me change one day's exercises, sets and order.
- Exercise sheet: Let me adjust, swap, move or remove this one exercise.
- Swap / Add exercise sheet: Let me pick a different exercise for this slot.

**Crew**

- Crew, solo: Explain what a crew does and get me to start or join one.
- Create crew: Name my crew and start it.
- Join by code: Take my friend's code and put me in their crew.
- Crew stream: Show me who showed up today and let me react.
- Invite sheet: Get the invite to my friends.
- Manage crew (new, per ruling b): Let me rename the crew, replace the link, remove a member, or leave.

**Progress**

- Charts: Show me whether I've been showing up, and whether I'm getting stronger.
- Journal: Let me look back at what I actually did, day by day.

**Session**

- Logger: Log each set as I do it, with as few taps as possible.
- Weight alert: Let me type an exact weight.
- Discard dialog: Confirm I'm throwing this workout away.
- Celebration: Show me what I just did and let me choose whether the crew sees it.

**Settings**

- Settings list: Let me find and change anything about my account, plan or privacy.
- Blocked people: Show who I've blocked and let me unblock them.
- Profile: Let me set my name and photo.
- Pause: Pause my plan until a date I pick.

**Nutrition (18+)**

- Today, first run: Turn my bodyweight into daily macro targets.
- Today: Show what's left to eat today and log a meal in one tap.
- Quick add: Log grams for something not in my saved meals.
- Logged today: Show everything I logged today and let me remove a mistake.
- Saved meals: Keep the meals I eat over and over.
- Template: Set the meals I eat on a normal day.
- Meal form: Enter or edit one meal's macros.
- Chain picker: Find a fast-food item and save it as a meal.
- Nutrition targets: Show and adjust my daily targets.
- How targets are estimated / How Crew works: Explain the reasoning and show the sources.

A control that does not serve its screen's job is a candidate for removal. A job with two homes has one too many.
