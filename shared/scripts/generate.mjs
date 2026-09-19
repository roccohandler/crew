// Reads shared/spec-constants.json + shared/design-tokens.json, validates them, and writes the
// Generated files for both platforms. Run: node shared/scripts/generate.mjs
// SPEC: Part V 5.2 (shared/ → Generated/), C7 (every spec number lives in one file), 6.8 (token parity)

import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { renderEmberColorsSwift, renderEmberCss, renderEmberTokensSwift } from "./render-ember.mjs";
import { copyValues, renderCopySwift, renderCopyTs, resolveCopy } from "./render-copy.mjs";
import { renderSeedDataSwift, renderSeedTs } from "./render-seed.mjs";
import { renderSpecConstantsSwift, renderSpecConstantsTs } from "./render-spec-constants.mjs";

export const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const specConstantsPath = join(repoRoot, "shared", "spec-constants.json");
const designTokensPath = join(repoRoot, "shared", "design-tokens.json");
const seedDir = join(repoRoot, "shared", "seed");
const copyDir = join(repoRoot, "shared", "copy");

function readSeeds() {
  const seeds = {
    exercises: JSON.parse(readFileSync(join(seedDir, "exercises.json"), "utf8")),
    planTemplates: JSON.parse(readFileSync(join(seedDir, "plan-templates.json"), "utf8")),
    achievements: JSON.parse(readFileSync(join(seedDir, "achievements.json"), "utf8")),
    fastFood: JSON.parse(readFileSync(join(seedDir, "fast-food.json"), "utf8")), // nutrition addendum §5
  };
  for (const [name, doc] of Object.entries(seeds)) if (JSON.stringify(doc).includes('"#')) throw new Error(`seed ${name}: the sequence "# would break the Swift raw string`);
  return seeds;
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
  const opacity = (value) => value === undefined || (typeof value === "number" && value > 0 && value < 1);
  const checkColor = (where, color) => {
    if (!hex.test(color.light) || !hex.test(color.dark)) throw new Error(`design-tokens.json: ${where} needs light + dark as #RRGGBB`);
    if (!opacity(color.lightOpacity) || !opacity(color.darkOpacity) || (color.lightOpacity === undefined) !== (color.darkOpacity === undefined)) throw new Error(`design-tokens.json: ${where} opacities come as a pair, each between 0 and 1`);
    if (typeof color.role !== "string") throw new Error(`design-tokens.json: ${where} needs a role`);
  };
  // A28 (a) — `colors` IS the system's table; macro identity is A16's bounded exception; every alias names ONE table row
  for (const [name, color] of Object.entries(tokens.colors)) checkColor(`colors.${name}`, color);
  for (const [name, color] of Object.entries(tokens.macroColors.colors)) checkColor(`macroColors.colors.${name}`, color);
  const colorNames = new Set([...Object.keys(tokens.colors), ...Object.keys(tokens.macroColors.colors)]);
  for (const [name, alias] of Object.entries(tokens.colorAliases.aliases)) {
    if (colorNames.has(name)) throw new Error(`design-tokens.json: colorAliases.aliases.${name} shadows a colour of the same name`);
    if (!(alias.token in tokens.colors)) throw new Error(`design-tokens.json: colorAliases.aliases.${name} must point at a row of the table (colors), not ${alias.token}`);
    if (typeof alias.why !== "string") throw new Error(`design-tokens.json: colorAliases.aliases.${name} needs a why`);
  }
  const weights = new Set(["medium", "semibold", "bold", "heavy"]);
  const textStyles = new Set(["largeTitle", "title", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote", "caption", "caption2"]);
  for (const [name, role] of Object.entries(tokens.typography.roles)) {
    if (!Number.isInteger(role.size) || !weights.has(role.weight) || typeof role.tracking !== "number" || typeof role.rounded !== "boolean" || typeof role.uppercase !== "boolean" || !textStyles.has(role.relativeTo) || typeof role.role !== "string") {
      throw new Error(`design-tokens.json: typography.roles.${name} needs an integer size, a weight (${[...weights].join(" / ")}), a numeric tracking, rounded and uppercase booleans, a relativeTo text style, and a role`);
    }
  }
  for (const [name, value] of Object.entries(tokens.focus.scale)) {
    if (!Number.isInteger(value)) throw new Error(`design-tokens.json: focus.scale.${name} must be an integer`);
  }
  for (const name of ["nearY", "nearBlur", "farY", "farBlur", "nearOpacity", "farOpacity"]) {
    if (typeof tokens.elevation[name] !== "number") throw new Error(`design-tokens.json: elevation.${name} must be a number`);
  }
  for (const [name, value] of Object.entries(tokens.spacing.scale)) {
    if (!Number.isInteger(value)) throw new Error(`design-tokens.json: spacing.scale.${name} must be an integer`);
  }
  for (const [name, value] of Object.entries(tokens.sizes.scale)) {
    if (!Number.isInteger(value)) throw new Error(`design-tokens.json: sizes.scale.${name} must be an integer`);
  }
  const spring = tokens.motion.spring;
  if (typeof spring.response !== "number" || typeof spring.dampingFraction !== "number") throw new Error("design-tokens.json: motion.spring needs response + dampingFraction");
  for (const [name, haptic] of Object.entries(tokens.haptics)) {
    if (typeof haptic.meaning !== "string") throw new Error(`design-tokens.json: haptics.${name} needs a meaning`);
  }
  return tokens;
}

// SPEC: A16.a · C7 — copy is shared words; its numbers are {placeholders} resolved from the constants above
export function readCopy(sections) {
  const values = copyValues(sections);
  const copy = {
    nutritionMethod: resolveCopy(JSON.parse(readFileSync(join(copyDir, "nutrition-method.json"), "utf8")), values, "nutrition-method.json"),
    education: resolveCopy(JSON.parse(readFileSync(join(copyDir, "education.json"), "utf8")), values, "education.json"), // A23
    legal: resolveCopy(JSON.parse(readFileSync(join(copyDir, "legal.json"), "utf8")), values, "legal.json"), // W9: web only — the phone opens these pages in its in-app browser
  };
  for (const [name, doc] of Object.entries(copy)) if (JSON.stringify(doc).includes('"#')) throw new Error(`copy ${name}: the sequence "# would break the Swift raw string`);
  return copy;
}

export function renderAll() {
  const sections = readSpecConstants();
  const tokens = readDesignTokens();
  const seeds = readSeeds();
  const copy = readCopy(sections);
  return [
    { path: "ios/Crew/Generated/SpecConstants.swift", content: renderSpecConstantsSwift(sections) },
    { path: "ios/Crew/Generated/EmberColors.swift", content: renderEmberColorsSwift(tokens) },
    { path: "ios/Crew/Generated/EmberTokens.swift", content: renderEmberTokensSwift(tokens) },
    { path: "ios/Crew/Generated/SeedData.swift", content: renderSeedDataSwift(seeds) },
    { path: "ios/Crew/Generated/CopyData.swift", content: renderCopySwift(copy) },
    { path: "web/src/generated/spec-constants.ts", content: renderSpecConstantsTs(sections) },
    { path: "web/src/generated/ember.css", content: renderEmberCss(tokens, sections) },
    { path: "web/src/generated/seed.ts", content: renderSeedTs(seeds) },
    { path: "web/src/generated/copy.ts", content: renderCopyTs(copy) },
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
