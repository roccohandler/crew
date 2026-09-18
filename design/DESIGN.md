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
