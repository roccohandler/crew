// The one file that names geometry constants for inline SVG (the weekly ring, the heat map). Not spec numbers, so not in
// spec-constants.json; exempt from the magic-number rule by name in eslint.config.mjs.
//
// A18 / J027 — the ring's geometry DIVERGED FROM iOS BY A THIRD and nothing could catch it. iOS draws a 64 pt ring
// with an 8 pt stroke (1:8); this file drew radius 42 with stroke 8 in a 100-unit viewBox scaled into a 64 px box,
// which renders as 1:11.5 — a visibly thinner ring — and set its label in `em` against an unset body font-size while
// iOS used `.headline`. No screenshot comparison of Home's header could ever have agreed.
//
// The viewBox is now the ring's own diameter, so ONE VIEWBOX UNIT IS ONE PIXEL: the radius and the stroke are the
// same numbers both engines use, and the label is set in px. `ringRadius` is (diameter − stroke) / 2, which puts the
// stroke's outer edge exactly on the box — the reason iOS insets its circle by half the line width for the same ring.
// web/tests/token-parity.test.ts pins all three against `shared/design-tokens.json`.
export const Geometry = {
  half: 0.5,
  tau: 2 * Math.PI,
  svgViewBox: 64, // = design-tokens sizes.ringDiameter
  ringRadius: 28, // = (ringDiameter − ringStroke) / 2
  ringStroke: 8, // = design-tokens spacing.space8, the stroke iOS passes to Circle().stroke
  quarterTurnDegrees: -90,
} as const;
