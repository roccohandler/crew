// Reads shared/spec-constants.json + shared/design-tokens.json, validates them, and writes the
// Generated files for both platforms. Run: node shared/scripts/generate.mjs
// SPEC: Part V 5.2 (shared/ → Generated/), C7 (every spec number lives in one file), 6.8 (token parity)

import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { renderEmberColorsSwift, renderEmberCss, renderEmberTokensSwift } from "./render-ember.mjs";
import { renderSeedDataSwift, renderSeedTs } from "./render-seed.mjs";
import { renderSpecConstantsSwift, renderSpecConstantsTs } from "./render-spec-constants.mjs";

export const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const specConstantsPath = join(repoRoot, "shared", "spec-constants.json");
const designTokensPath = join(repoRoot, "shared", "design-tokens.json");
const seedDir = join(repoRoot, "shared", "seed");

function readSeeds() {
  const seeds = {
    exercises: JSON.parse(readFileSync(join(seedDir, "exercises.json"), "utf8")),
    planTemplates: JSON.parse(readFileSync(join(seedDir, "plan-templates.json"), "utf8")),
    achievements: JSON.parse(readFileSync(join(seedDir, "achievements.json"), "utf8")),
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
  for (const [name, color] of Object.entries(tokens.colors)) {
    if (!hex.test(color.light) || !hex.test(color.dark)) throw new Error(`design-tokens.json: colors.${name} needs light + dark as #RRGGBB`);
    if (typeof color.role !== "string") throw new Error(`design-tokens.json: colors.${name} needs a role`);
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

export function renderAll() {
  const sections = readSpecConstants();
  const tokens = readDesignTokens();
  const seeds = readSeeds();
  return [
    { path: "ios/Crew/Generated/SpecConstants.swift", content: renderSpecConstantsSwift(sections) },
    { path: "ios/Crew/Generated/EmberColors.swift", content: renderEmberColorsSwift(tokens) },
    { path: "ios/Crew/Generated/EmberTokens.swift", content: renderEmberTokensSwift(tokens) },
    { path: "ios/Crew/Generated/SeedData.swift", content: renderSeedDataSwift(seeds) },
    { path: "web/src/generated/spec-constants.ts", content: renderSpecConstantsTs(sections) },
    { path: "web/src/generated/ember.css", content: renderEmberCss(tokens, sections) },
    { path: "web/src/generated/seed.ts", content: renderSeedTs(seeds) },
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
