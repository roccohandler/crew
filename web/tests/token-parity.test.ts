// SPEC: 6.8 (Ember tokens generated from shared/design-tokens.json → Swift + CSS, drift-proof, snapshot-tested) · T039 token
// parity: every color, spacing and size value in design-tokens.json appears verbatim in ember.css AND in EmberColors/EmberTokens.swift.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const root = join(process.cwd(), "..");
const tokens = JSON.parse(readFileSync(join(root, "shared", "design-tokens.json"), "utf8")) as { colors: Record<string, { light: string; dark: string }>; spacing: { scale: Record<string, number> }; sizes: { scale: Record<string, number> } };
const css = readFileSync(join(root, "web", "src", "generated", "ember.css"), "utf8");
const swiftColors = readFileSync(join(root, "ios", "Crew", "Generated", "EmberColors.swift"), "utf8");
const swiftTokens = readFileSync(join(root, "ios", "Crew", "Generated", "EmberTokens.swift"), "utf8");
const kebab = (name: string) => name.replace(/[A-Z]/g, (upper) => `-${upper.toLowerCase()}`).replace(/([a-z])(\d)/g, "$1-$2");

describe("token parity — web CSS and Swift carry the same Ember values", () => {
  it("every color's light and dark hex is in ember.css and EmberColors.swift", () => {
    for (const [name, color] of Object.entries(tokens.colors)) {
      expect(css, `${name} light`).toContain(`--ember-${kebab(name)}: ${color.light};`);
      expect(css, `${name} dark`).toContain(`--ember-${kebab(name)}: ${color.dark};`);
      expect(swiftColors, `${name} swift`).toContain(`static let ${name} = emberColor(light: 0x${color.light.slice(1)}, dark: 0x${color.dark.slice(1)})`);
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
