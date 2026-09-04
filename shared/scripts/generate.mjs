// Reads shared/spec-constants.json + shared/design-tokens.json and writes the Generated files
// for both platforms. Run: node shared/scripts/generate.mjs
// SPEC: Part V 5.2 (shared/ → Generated/), C7 (every spec number lives in one file), 6.8 (token parity)

import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const specConstantsPath = join(repoRoot, "shared", "spec-constants.json");
const designTokensPath = join(repoRoot, "shared", "design-tokens.json");

const gapNote = "SPECIFICATION GAP — dark value undefined in spec; light value used until the owner decides";

function lineHeader(source) {
  return `// GENERATED FILE — DO NOT EDIT. Source: ${source} · Generator: shared/scripts/generate.mjs
// Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts.`;
}

function readSpecConstants() {
  const sections = JSON.parse(readFileSync(specConstantsPath, "utf8"));
  const seen = new Set();
  for (const [section, entries] of Object.entries(sections)) {
    for (const [name, entry] of Object.entries(entries)) {
      if (seen.has(name)) throw new Error(`spec-constants.json: duplicate constant name ${name}`);
      if (!("value" in entry) || typeof entry.spec !== "string") throw new Error(`spec-constants.json: ${section}.${name} needs value + spec`);
      seen.add(name);
    }
  }
  return sections;
}

function readDesignTokens() {
  const tokens = JSON.parse(readFileSync(designTokensPath, "utf8"));
  const hex = /^#[0-9A-F]{6}$/;
  for (const [name, color] of Object.entries(tokens.colors)) {
    if (!hex.test(color.light)) throw new Error(`design-tokens.json: colors.${name}.light must be #RRGGBB`);
    if (color.dark !== null && !hex.test(color.dark)) throw new Error(`design-tokens.json: colors.${name}.dark must be #RRGGBB or null`);
    if (typeof color.role !== "string") throw new Error(`design-tokens.json: colors.${name} needs a role`);
  }
  return tokens;
}

function swiftType(entry) {
  const scalar = Array.isArray(entry.value) ? entry.value[0] : entry.value;
  let type = "Int";
  if (typeof scalar === "string") type = "String";
  else if (entry.type === "double" || !Number.isInteger(scalar)) type = "Double";
  return Array.isArray(entry.value) ? `[${type}]` : type;
}

function literal(value) {
  if (Array.isArray(value)) return `[${value.map((item) => JSON.stringify(item)).join(", ")}]`;
  return JSON.stringify(value);
}

function renderSpecConstantsSwift(sections) {
  const lines = [lineHeader("shared/spec-constants.json"), "// SPEC: C7 — every tunable in the spec, named for its rule.", "", "enum SpecConstants {"];
  for (const [section, entries] of Object.entries(sections)) {
    lines.push(`    // MARK: ${section}`);
    for (const [name, entry] of Object.entries(entries)) {
      lines.push(`    /// SPEC: ${entry.spec}`);
      lines.push(`    static let ${name}: ${swiftType(entry)} = ${literal(entry.value)}`);
    }
    lines.push("");
  }
  lines.pop(); lines.push("}", "");
  return lines.join("\n");
}

function renderSpecConstantsTs(sections) {
  const lines = [lineHeader("shared/spec-constants.json"), "// SPEC: C7 — every tunable in the spec, named for its rule.", "", "export const SpecConstants = {"];
  for (const [section, entries] of Object.entries(sections)) {
    lines.push(`  // --- ${section} ---`);
    for (const [name, entry] of Object.entries(entries)) {
      lines.push(`  /** SPEC: ${entry.spec} */`);
      lines.push(`  ${name}: ${literal(entry.value)},`);
    }
    lines.push("");
  }
  lines.pop(); lines.push("} as const;", "");
  return lines.join("\n");
}

function renderEmberColorsSwift(tokens) {
  const lines = [lineHeader("shared/design-tokens.json"), "// SPEC: Part III — the Ember color system. Ink acts, Ember rewards.", "", "import SwiftUI", "import UIKit", "", "enum EmberColors {"];
  for (const [name, color] of Object.entries(tokens.colors)) {
    const dark = color.dark ?? color.light;
    const darkNote = color.dark === null ? ` · dark: ${gapNote}` : ` · dark ${color.dark}`;
    lines.push(`    /// ${color.role} · light ${color.light}${darkNote}`);
    lines.push(`    static let ${name} = emberColor(light: 0x${color.light.slice(1)}, dark: 0x${dark.slice(1)})`);
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

function cssName(name) {
  return `--ember-${name.replace(/[A-Z]/g, (upper) => `-${upper.toLowerCase()}`)}`;
}

function renderEmberCss(tokens) {
  const lines = ["/* GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs */",
    "/* Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts. */",
    "/* SPEC: Part III — the Ember color system. Ink acts, Ember rewards. */", "", ":root {", "  color-scheme: light dark;"];
  for (const [name, color] of Object.entries(tokens.colors)) {
    lines.push(`  /* ${color.role} */`, `  ${cssName(name)}: ${color.light};`);
  }
  lines.push("}", "", "@media (prefers-color-scheme: dark) {", "  :root {");
  for (const [name, color] of Object.entries(tokens.colors)) {
    if (color.dark === null) lines.push(`    /* ${name}: ${gapNote} */`);
    lines.push(`    ${cssName(name)}: ${color.dark ?? color.light};`);
  }
  lines.push("  }", "}", "");
  return lines.join("\n");
}

export function renderAll() {
  const sections = readSpecConstants();
  const tokens = readDesignTokens();
  return [
    { path: "ios/Crew/Generated/SpecConstants.swift", content: renderSpecConstantsSwift(sections) },
    { path: "ios/Crew/Generated/EmberColors.swift", content: renderEmberColorsSwift(tokens) },
    { path: "web/src/generated/spec-constants.ts", content: renderSpecConstantsTs(sections) },
    { path: "web/src/generated/ember.css", content: renderEmberCss(tokens) },
  ];
}

const runAsScript = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (runAsScript) {
  for (const { path, content } of renderAll()) {
    mkdirSync(dirname(join(repoRoot, path)), { recursive: true });
    writeFileSync(join(repoRoot, path), content, "utf8");
    console.log(`wrote  ${path}  (${content.split("\n").length - 1} lines)`);
  }
  console.log("generate: done");
}
