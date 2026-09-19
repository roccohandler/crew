// Renders shared/design-tokens.json as EmberColors.swift, EmberTokens.swift and ember.css.
// SPEC: A28 (the Focus Card system: the colour table, the type scale) · Part III (Ember laws, ④ narrowed by A28 (b)) · 6.4 (one
// spring, haptic language) · 6.8 (tokens generated → Swift + CSS)

const swiftHeader = `// GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs
// Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts.`;

const cssHeader = `/* GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs */
/* Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts. */`;

// SwiftUI Font.Weight case and CSS font-weight for each weight the type scale names
const TYPE_WEIGHTS ={ medium: 500, semibold: 600, bold: 700, heavy: 800 };

function kebab(name) {
  return name.replace(/[A-Z]/g, (upper) => `-${upper.toLowerCase()}`).replace(/([a-z])(\d)/g, "$1-$2");
}

function cssName(name) {
  return `--ember-${kebab(name)}`;
}

// A colour's value for one mode: the hex, or rgba() when the table gives it an opacity (the sheet scrim)
function cssColor(color, mode) {
  const opacity = color[`${mode}Opacity`];
  if (opacity === undefined) return color[mode];
  const n = Number.parseInt(color[mode].slice(1), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${opacity})`;
}

export function renderEmberColorsSwift(tokens) {
  const lines = [swiftHeader, "// SPEC: A28 (a) — the Focus Card colour table: nothing in the UI uses a colour that is not on it. Ink acts; orange is a point.", "", "import SwiftUI", "import UIKit", "", "enum EmberColors {"];
  // the table, then A16's macro colours under their own comment — one loop, so every colour is written one way
  for (const [comment, colors] of [[null, tokens.colors], [tokens.macroColors.spec, tokens.macroColors.colors]]) {
    if (comment !== null) lines.push("", `    // ${comment}`);
    for (const [name, color] of Object.entries(colors)) {
      const opacity = color.lightOpacity === undefined ? "" : `, lightOpacity: ${color.lightOpacity}, darkOpacity: ${color.darkOpacity}`;
      const shown = (mode) => (color[`${mode}Opacity`] === undefined ? color[mode] : `${color[mode]} at ${color[`${mode}Opacity`]}`);
      lines.push(`    /// ${color.role} · light ${shown("light")} · dark ${shown("dark")}`);
      lines.push(`    static let ${name} = emberColor(light: 0x${color.light.slice(1)}, dark: 0x${color.dark.slice(1)}${opacity})`);
    }
  }
  lines.push("", `    // ${tokens.colorAliases.spec}`);
  for (const [name, alias] of Object.entries(tokens.colorAliases.aliases)) {
    lines.push(`    /// ${alias.why} — the table's \`${alias.token}\``);
    lines.push(`    static let ${name} = EmberColors.${alias.token}`);
  }
  lines.push("}", "",
    "/// One adaptive color from the light and dark values; follows the system appearance (A28 (a): light is the default, dark is",
    "/// supported — while the light lock of A21.10 as amended 2026-09-18 stands, the dark branch is never taken).",
    "private func emberColor(light: UInt32, dark: UInt32, lightOpacity: CGFloat = 1, darkOpacity: CGFloat = 1) -> Color {",
    "    Color(uiColor: UIColor { traits in",
    "        traits.userInterfaceStyle == .dark ? uiColor(hex: dark, alpha: darkOpacity) : uiColor(hex: light, alpha: lightOpacity)",
    "    })",
    "}", "",
    "private func uiColor(hex: UInt32, alpha: CGFloat) -> UIColor {",
    "    UIColor(",
    "        red: CGFloat((hex >> 16) & 0xFF) / 255,",
    "        green: CGFloat((hex >> 8) & 0xFF) / 255,",
    "        blue: CGFloat(hex & 0xFF) / 255,",
    "        alpha: alpha",
    "    )",
    "}", "");
  return lines.join("\n");
}

export function renderEmberTokensSwift(tokens) {
  const lines = [swiftHeader, "// SPEC: A28 — the type scale · 6.4 — spacing scale, the one spring curve, the haptic language (Decision Registry G5/G8 2026-09-04).", "", "import SwiftUI", "", "enum EmberTokens {"];
  lines.push(`    /// ${tokens.typography.spec}`, "    enum Typography {");
  for (const [name, role] of Object.entries(tokens.typography.roles)) {
    lines.push(`        /// ${role.role} — ${role.size} pt ${role.weight}${role.tracking === 0 ? "" : `, tracking ${role.tracking}`}${role.rounded ? ", rounded" : ""}${role.uppercase ? ", uppercase" : ""}`);
    lines.push(`        static let ${name} = TypeRole(size: ${role.size}, weight: .${role.weight}, tracking: ${role.tracking}, rounded: ${role.rounded}, uppercase: ${role.uppercase}, relativeTo: .${role.relativeTo})`);
  }
  lines.push("    }", "",
    "    /// One row of the type scale. `tracking` is a fraction of the size: SwiftUI's .tracking takes points, so a view passes",
    "    /// size × tracking. `rounded` = SF Pro Rounded (every numeral); `uppercase` = the string renders uppercase; `relativeTo` =",
    "    /// the text style whose Dynamic Type curve the size follows (Shared/TypeRoleStyle.swift applies all five).",
    "    struct TypeRole {",
    "        let size: CGFloat",
    "        let weight: Font.Weight",
    "        let tracking: CGFloat",
    "        let rounded: Bool",
    "        let uppercase: Bool",
    "        let relativeTo: Font.TextStyle",
    "    }", "");
  lines.push(`    /// ${tokens.focus.spec}`, "    enum Focus {");
  for (const [name, value] of Object.entries(tokens.focus.scale)) lines.push(`        static let ${name}: CGFloat = ${value}`);
  lines.push("    }", "", `    /// ${tokens.elevation.spec}`, "    enum Elevation {");
  for (const name of ["nearY", "nearBlur", "farY", "farBlur"]) lines.push(`        static let ${name}: CGFloat = ${tokens.elevation[name]}`);
  for (const name of ["nearOpacity", "farOpacity"]) lines.push(`        static let ${name}: Double = ${tokens.elevation[name]}`);
  // SwiftUI's shadow radius is a Gaussian's deviation, half the CSS blur length the system states
  lines.push("        /// SwiftUI's `radius` — half the CSS blur (a blur length is twice the Gaussian's deviation)");
  lines.push(`        static let nearRadius: CGFloat = ${tokens.elevation.nearBlur / 2}`, `        static let farRadius: CGFloat = ${tokens.elevation.farBlur / 2}`);
  lines.push("    }", "");
  lines.push(`    /// ${tokens.spacing.spec}`, "    enum Spacing {");
  for (const [name, value] of Object.entries(tokens.spacing.scale)) lines.push(`        static let ${name}: CGFloat = ${value}`);
  lines.push("    }", "", `    /// ${tokens.sizes.spec}`, "    enum Size {");
  for (const [name, value] of Object.entries(tokens.sizes.scale)) lines.push(`        static let ${name}: CGFloat = ${value}`);
  lines.push("    }", "", `    /// ${tokens.opacity.spec}`, "    enum Opacity {");
  for (const [name, value] of Object.entries(tokens.opacity.scale)) lines.push(`        static let ${name}: Double = ${value}`);
  lines.push("    }", "", `    /// ${tokens.motion.spec}`, "    enum Motion {");
  lines.push(`        static let springResponse: Double = ${tokens.motion.spring.response}`);
  lines.push(`        static let springDampingFraction: Double = ${tokens.motion.spring.dampingFraction}`);
  lines.push("    }", "", "    /// Flow 3 + 6.4 — the fixed haptic language; Shared/Haptics.swift plays exactly these.", "    enum Haptic: String, CaseIterable {");
  for (const [name, haptic] of Object.entries(tokens.haptics)) lines.push(`        /// ${haptic.meaning} — SPEC: ${haptic.spec}`, `        case ${name}`);
  lines.push("    }", "}", "");
  return lines.join("\n");
}

export function renderEmberCss(tokens, sections) {
  // A28 (a) makes dark SUPPORTED; until the light lock of A21.10 (as amended 2026-09-18) lifts with the Home session
  // (docs/mvp-definition.md), the browser is still told `light`, and the dark values below sit under a selector nothing sets —
  // defined (token parity) and unreachable. Lifting the lock is this line and the one at the block.
  const lines = [cssHeader, "/* SPEC: A28 — the Focus Card colour table and type scale. Ink acts; orange is a point. 6.4 — spacing + the one spring. A21.10 (amended 2026-09-18): light lock, lifted by A28 (a) in the Home session. */", "", ":root {", "  color-scheme: light;"];
  for (const [name, color] of Object.entries(tokens.colors)) lines.push(`  /* ${color.role} */`, `  ${cssName(name)}: ${cssColor(color, "light")};`);
  lines.push(`  /* ${tokens.macroColors.spec} */`);
  for (const [name, color] of Object.entries(tokens.macroColors.colors)) lines.push(`  /* ${color.role} */`, `  ${cssName(name)}: ${cssColor(color, "light")};`);
  lines.push(`  /* ${tokens.colorAliases.spec} */`);
  for (const [name, alias] of Object.entries(tokens.colorAliases.aliases)) lines.push(`  ${cssName(name)}: var(${cssName(alias.token)});`);
  lines.push(`  /* ${tokens.typography.spec} */`);
  lines.push(`  --ember-font-text: ${tokens.typography.web.text};`);
  lines.push(`  --ember-font-rounded: ${tokens.typography.web.rounded};`);
  for (const [name, role] of Object.entries(tokens.typography.roles)) {
    const base = `--ember-type-${kebab(name)}`;
    lines.push(`  ${base}-size: ${role.size}px;`);
    lines.push(`  ${base}-weight: ${TYPE_WEIGHTS[role.weight]};`);
    lines.push(`  ${base}-tracking: ${role.tracking}em;`);
    lines.push(`  ${base}-family: var(${role.rounded ? "--ember-font-rounded" : "--ember-font-text"});`);
    lines.push(`  ${base}-transform: ${role.uppercase ? "uppercase" : "none"};`);
  }
  lines.push(`  /* ${tokens.focus.spec} */`);
  for (const [name, value] of Object.entries(tokens.focus.scale)) lines.push(`  --ember-focus-${kebab(name)}: ${value}px;`);
  lines.push(`  /* ${tokens.elevation.spec} */`);
  // the shadow is the light ink at two opacities (system §6)
  const shadow = (opacity) => cssColor({ light: tokens.colors.ink.light, lightOpacity: opacity }, "light");
  lines.push(`  --ember-elevation-light: 0 ${tokens.elevation.nearY}px ${tokens.elevation.nearBlur}px ${shadow(tokens.elevation.nearOpacity)}, 0 ${tokens.elevation.farY}px ${tokens.elevation.farBlur}px ${shadow(tokens.elevation.farOpacity)};`);
  lines.push(`  /* ${tokens.spacing.spec} */`);
  for (const [name, value] of Object.entries(tokens.spacing.scale)) lines.push(`  ${cssName(name)}: ${value}px;`);
  lines.push(`  /* ${tokens.sizes.spec} */`);
  for (const [name, value] of Object.entries(tokens.sizes.scale)) lines.push(`  --ember-size-${name.replace(/[A-Z]/g, (upper) => `-${upper.toLowerCase()}`)}: ${value}px;`);
  lines.push(`  /* ${tokens.opacity.spec} */`);
  for (const [name, value] of Object.entries(tokens.opacity.scale)) lines.push(`  --ember-opacity-${name}: ${value};`);
  lines.push(`  /* ${tokens.motion.spec} */`);
  lines.push(`  --ember-spring-response: ${tokens.motion.spring.response};`);
  lines.push(`  --ember-spring-damping-fraction: ${tokens.motion.spring.dampingFraction};`);
  lines.push("  /* layout constants — from shared/spec-constants.json (6.7, 6.3) */");
  lines.push(`  --crew-app-max-width: ${sections.touchAndLayout.webAppMaxWidthPx.value}px;`);
  lines.push(`  --crew-progress-max-width: ${sections.touchAndLayout.webProgressMaxWidthPx.value}px;`);
  lines.push(`  --crew-min-touch-target: ${sections.touchAndLayout.webMinTouchTargetPx.value}px;`);
  lines.push(`  --crew-touch-target-breakpoint: ${sections.touchAndLayout.webTouchTargetBreakpointPx.value}px;`);
  lines.push("}", "", "/* The dark values (A28 (a), Midnight). No element carries data-theme=\"dark\" until the light lock lifts; an alias needs no dark line — its var() resolves to the row below */", ':root[data-theme="dark"] {');
  for (const [name, color] of Object.entries(tokens.colors)) lines.push(`    ${cssName(name)}: ${cssColor(color, "dark")};`);
  for (const [name, color] of Object.entries(tokens.macroColors.colors)) lines.push(`    ${cssName(name)}: ${cssColor(color, "dark")};`);
  lines.push("}", "");
  return lines.join("\n");
}
