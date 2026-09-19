// SPEC: 6.8 (Ember tokens generated from shared/design-tokens.json → Swift + CSS, drift-proof, snapshot-tested) · T039 token
// parity: every color, spacing and size value in design-tokens.json appears verbatim in ember.css AND in EmberColors/EmberTokens.swift.
// A28 (2026-09-19): the colour table, A16's macro colours, the legacy aliases (each ONE table row) and the type scale are pinned too.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

type Color = { light: string; dark: string; lightOpacity?: number; darkOpacity?: number };
type TypeRole = { size: number; weight: string; tracking: number; rounded: boolean; uppercase: boolean };
const root = join(process.cwd(), "..");
const tokens = JSON.parse(readFileSync(join(root, "shared", "design-tokens.json"), "utf8")) as {
  colors: Record<string, Color>;
  macroColors: { colors: Record<string, Color> };
  colorAliases: { aliases: Record<string, { token: string }> };
  typography: { roles: Record<string, TypeRole> };
  spacing: { scale: Record<string, number> };
  sizes: { scale: Record<string, number> };
};
const css = readFileSync(join(root, "web", "src", "generated", "ember.css"), "utf8");
const swiftColors = readFileSync(join(root, "ios", "Crew", "Generated", "EmberColors.swift"), "utf8");
const swiftTokens = readFileSync(join(root, "ios", "Crew", "Generated", "EmberTokens.swift"), "utf8");
const kebab = (name: string) => name.replace(/[A-Z]/g, (upper) => `-${upper.toLowerCase()}`).replace(/([a-z])(\d)/g, "$1-$2");
const CSS_WEIGHT: Record<string, number> = { medium: 500, semibold: 600, bold: 700, heavy: 800 };

// Written out here rather than imported from the generator, so the generator is checked by something other than itself
function cssValue(color: Color, mode: "light" | "dark"): string {
  const opacity = mode === "light" ? color.lightOpacity : color.darkOpacity;
  if (opacity === undefined) return color[mode];
  const n = Number.parseInt(color[mode].slice(1), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${opacity})`;
}

function swiftCall(color: Color): string {
  const hexes = `light: 0x${color.light.slice(1)}, dark: 0x${color.dark.slice(1)}`;
  return color.lightOpacity === undefined ? `emberColor(${hexes})` : `emberColor(${hexes}, lightOpacity: ${color.lightOpacity}, darkOpacity: ${color.darkOpacity})`;
}

describe("token parity — web CSS and Swift carry the same Ember values", () => {
  it("every colour of the table and every macro colour has its light and dark value in ember.css and EmberColors.swift", () => {
    for (const [name, color] of [...Object.entries(tokens.colors), ...Object.entries(tokens.macroColors.colors)]) {
      expect(css, `${name} light`).toContain(`--ember-${kebab(name)}: ${cssValue(color, "light")};`);
      expect(css, `${name} dark`).toContain(`--ember-${kebab(name)}: ${cssValue(color, "dark")};`);
      expect(swiftColors, `${name} swift`).toContain(`static let ${name} = ${swiftCall(color)}`);
    }
  });
  it("every legacy alias is exactly one row of the table on both platforms (A28: nothing in the UI uses a colour not on it)", () => {
    for (const [name, alias] of Object.entries(tokens.colorAliases.aliases)) {
      expect(tokens.colors, `${name} → ${alias.token}`).toHaveProperty(alias.token);
      expect(css, `${name} css`).toContain(`--ember-${kebab(name)}: var(--ember-${kebab(alias.token)});`);
      expect(swiftColors, `${name} swift`).toContain(`static let ${name} = EmberColors.${alias.token}`);
    }
  });
  it("every row of the type scale is in both (A28)", () => {
    for (const [name, role] of Object.entries(tokens.typography.roles)) {
      const base = `--ember-type-${kebab(name)}`;
      expect(css).toContain(`${base}-size: ${role.size}px;`);
      expect(css).toContain(`${base}-weight: ${CSS_WEIGHT[role.weight]};`);
      expect(css).toContain(`${base}-tracking: ${role.tracking}em;`);
      expect(css).toContain(`${base}-family: var(${role.rounded ? "--ember-font-rounded" : "--ember-font-text"});`);
      expect(css).toContain(`${base}-transform: ${role.uppercase ? "uppercase" : "none"};`);
      expect(swiftTokens).toContain(`static let ${name} = TypeRole(size: ${role.size}, weight: .${role.weight}, tracking: ${role.tracking}, rounded: ${role.rounded}, uppercase: ${role.uppercase})`);
    }
  });
  it("every spacing and size value is in both", () => {
    for (const [name, value] of Object.entries(tokens.spacing.scale)) {
      expect(css).toContain(`--ember-${kebab(name)}: ${value}px;`);
      expect(swiftTokens).toContain(`static let ${name}: CGFloat = ${value}`);
    }
    for (const [name, value] of Object.entries(tokens.sizes.scale)) {
      expect(css).toContain(`--ember-size-${kebab(name)}: ${value}px;`);
      expect(swiftTokens).toContain(`static let ${name}: CGFloat = ${value}`);
    }
  });
});
