// Renders shared/design-tokens.json as EmberColors.swift, EmberTokens.swift and ember.css.
// SPEC: Part III (Ember, six laws) · 6.4 (one spring, haptic language) · 6.8 (tokens generated → Swift + CSS)

const swiftHeader = `// GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs
// Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts.`;

const cssHeader = `/* GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs */
/* Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts. */`;

function cssName(name) {
  return `--ember-${name.replace(/[A-Z]/g, (upper) => `-${upper.toLowerCase()}`).replace(/([a-z])(\d)/g, "$1-$2")}`;
}

export function renderEmberColorsSwift(tokens) {
  const lines = [swiftHeader, "// SPEC: Part III — the Ember color system. Ink acts, Ember rewards.", "", "import SwiftUI", "import UIKit", "", "enum EmberColors {"];
  for (const [name, color] of Object.entries(tokens.colors)) {
    lines.push(`    /// ${color.role} · light ${color.light} · dark ${color.dark}`);
    lines.push(`    static let ${name} = emberColor(light: 0x${color.light.slice(1)}, dark: 0x${color.dark.slice(1)})`);
  }
  lines.push("}", "",
    "/// One adaptive color from the light and dark hex values; follows the system appearance.",
    "private func emberColor(light: UInt32, dark: UInt32) -> Color {",
    "    Color(uiColor: UIColor { traits in",
    "        traits.userInterfaceStyle == .dark ? uiColor(hex: dark) : uiColor(hex: light)",
    "    })",
    "}", "",
    "private func uiColor(hex: UInt32) -> UIColor {",
    "    UIColor(",
    "        red: CGFloat((hex >> 16) & 0xFF) / 255,",
    "        green: CGFloat((hex >> 8) & 0xFF) / 255,",
    "        blue: CGFloat(hex & 0xFF) / 255,",
    "        alpha: 1",
    "    )",
    "}", "");
  return lines.join("\n");
}

export function renderEmberTokensSwift(tokens) {
  const lines = [swiftHeader, "// SPEC: 6.4 — spacing scale, the one spring curve, the haptic language (Decision Registry G5/G8 2026-09-04).", "", "import SwiftUI", "", "enum EmberTokens {"];
  lines.push(`    /// ${tokens.spacing.spec}`, "    enum Spacing {");
  for (const [name, value] of Object.entries(tokens.spacing.scale)) lines.push(`        static let ${name}: CGFloat = ${value}`);
  lines.push("    }", "", `    /// ${tokens.motion.spec}`, "    enum Motion {");
  lines.push(`        static let springResponse: Double = ${tokens.motion.spring.response}`);
  lines.push(`        static let springDampingFraction: Double = ${tokens.motion.spring.dampingFraction}`);
  lines.push("    }", "", "    /// Flow 3 + 6.4 — the fixed haptic language; Shared/Haptics.swift plays exactly these.", "    enum Haptic: String, CaseIterable {");
  for (const [name, haptic] of Object.entries(tokens.haptics)) lines.push(`        /// ${haptic.meaning} — SPEC: ${haptic.spec}`, `        case ${name}`);
  lines.push("    }", "}", "");
  return lines.join("\n");
}

export function renderEmberCss(tokens) {
  const lines = [cssHeader, "/* SPEC: Part III — the Ember color system. Ink acts, Ember rewards. 6.4 — spacing + the one spring. */", "", ":root {", "  color-scheme: light dark;"];
  for (const [name, color] of Object.entries(tokens.colors)) lines.push(`  /* ${color.role} */`, `  ${cssName(name)}: ${color.light};`);
  lines.push(`  /* ${tokens.spacing.spec} */`);
  for (const [name, value] of Object.entries(tokens.spacing.scale)) lines.push(`  ${cssName(name)}: ${value}px;`);
  lines.push(`  /* ${tokens.motion.spec} */`);
  lines.push(`  --ember-spring-response: ${tokens.motion.spring.response};`);
  lines.push(`  --ember-spring-damping-fraction: ${tokens.motion.spring.dampingFraction};`);
  lines.push("}", "", "@media (prefers-color-scheme: dark) {", "  :root {");
  for (const [name, color] of Object.entries(tokens.colors)) lines.push(`    ${cssName(name)}: ${color.dark};`);
  lines.push("  }", "}", "");
  return lines.join("\n");
}
