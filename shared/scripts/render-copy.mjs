// Renders shared/copy/*.json as CopyData.swift (raw JSON, decoded once by the screen that prints it) and copy.ts (typed constants),
// so both platforms print the SAME words. Every {placeholder} is resolved HERE from shared/spec-constants.json — a number is never
// typed into copy (C7) and the two platforms cannot disagree on a digit. An unknown placeholder fails generation.
// SPEC: A16.a (the methodology screen) · nutrition addendum §3 · Part V 5.2 (shared/ → Generated/) · C7

const swiftHeader = `// GENERATED FILE — DO NOT EDIT. Source: shared/copy/*.json · Generator: shared/scripts/generate.mjs
// Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts.
// SPEC: A16.a · 6.6 — user-facing copy shared by both platforms; placeholders already resolved from spec-constants.`;

const tsHeader = `// GENERATED FILE — DO NOT EDIT. Source: shared/copy/*.json · Generator: shared/scripts/generate.mjs
// Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts.
// SPEC: A16.a · 6.6 — user-facing copy shared by both platforms; placeholders already resolved from spec-constants.`;

// The flat constant table plus the two per-kilogram factors in the unit a person reads (1.8, 0.5) — derived, never typed.
export function copyValues(sections) {
  const flat = Object.fromEntries(Object.values(sections).flatMap((entries) => Object.entries(entries).map(([name, entry]) => [name, entry.value])));
  return { ...flat, proteinGramsPerKg: flat.proteinGramsPerKgScaled / flat.macroFactorScale, fatFloorGramsPerKg: flat.fatFloorGramsPerKgScaled / flat.macroFactorScale };
}

function resolveText(text, values, where) {
  return text.replace(/\{([A-Za-z][A-Za-z0-9]*)\}/g, (_, name) => {
    if (typeof values[name] !== "number") throw new Error(`${where}: unknown placeholder {${name}} — it must name a numeric spec constant`);
    return String(values[name]);
  });
}

// Walks any JSON value; the `spec` note is dropped — it documents the file, it is not copy
export function resolveCopy(value, values, where) {
  if (typeof value === "string") return resolveText(value, values, where);
  if (Array.isArray(value)) return value.map((entry, index) => resolveCopy(entry, values, `${where}[${index}]`));
  if (value !== null && typeof value === "object") return Object.fromEntries(Object.entries(value).filter(([key]) => key !== "spec").map(([key, entry]) => [key, resolveCopy(entry, values, `${where}.${key}`)]));
  return value;
}

export function renderCopySwift(copy) {
  const raw = (json) => `#"""\n${JSON.stringify(json)}\n"""#`;
  return [
    swiftHeader, "", "import Foundation", "",
    "enum CopyData {",
    "    /// shared/copy/nutrition-method.json (A16.a)",
    `    static let nutritionMethodJSON = ${raw(copy.nutritionMethod)}`,
    "}", "",
  ].join("\n");
}

const copyTypes = `export interface CopySource { id: string; label: string; url: string }
export interface NutritionMethodStep { heading: string; body: string; sourceIds: string[] }
export interface NutritionMethodCopy { title: string; lead: string; steps: NutritionMethodStep[]; clinician: string; sources: CopySource[] }`;

export function renderCopyTs(copy) {
  return [tsHeader, "", copyTypes, "", `export const nutritionMethod: NutritionMethodCopy = ${JSON.stringify(copy.nutritionMethod, null, 2)};`, ""].join("\n");
}
