// The one file that names geometry constants for inline SVG (the weekly ring, the heat map). Not spec numbers, so not in
// spec-constants.json; exempt from the magic-number rule by name in eslint.config.mjs.
export const Geometry = {
  half: 0.5,
  tau: 2 * Math.PI,
  svgViewBox: 100,
  ringRadius: 42,
  ringStroke: 8,
  quarterTurnDegrees: -90,
} as const;
