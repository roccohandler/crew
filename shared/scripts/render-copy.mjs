// Renders shared/copy/*.json as CopyData.swift (raw JSON, decoded once by the screen that prints it) and copy.ts (typed constants),
// so both platforms print the SAME words. Every {placeholder} is resolved HERE from shared/spec-constants.json — a number is never
// typed into copy (C7) and the two platforms cannot disagree on a digit. An unknown placeholder fails generation.
// SPEC: A16.a (the methodology screen) · nutrition addendum §3 · A23 (the education layer: every whisper and the How Crew works page
// live in ONE file, shared/copy/education.json) · Part V 5.2 (shared/ → Generated/) · C7

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

// "why.ppl" → whyPpl: the Swift case a call site names, so a whisper id that does not exist cannot compile
const swiftCase = (id) => id.replace(/\.([a-zA-Z])/g, (_, letter) => letter.toUpperCase());

export function renderCopySwift(copy) {
  const raw = (json) => `#"""\n${JSON.stringify(json)}\n"""#`;
  return [
    swiftHeader, "", "import Foundation", "",
    "// A23 — the whisper ids, in the order shared/copy/education.json lists them (the page prints them in this order)",
    "enum WhisperId: String, CaseIterable {",
    ...copy.education.whispers.map((whisper) => `    case ${swiftCase(whisper.id)} = "${whisper.id}"`),
    "}", "",
    "enum CopyData {",
    "    /// shared/copy/nutrition-method.json (A16.a)",
    `    static let nutritionMethodJSON = ${raw(copy.nutritionMethod)}`,
    "    /// shared/copy/education.json (A23)",
    `    static let educationJSON = ${raw(copy.education)}`,
    "}", "",
  ].join("\n");
}

const copyTypes = `export interface CopySource { id: string; label: string; url: string }
export interface NutritionMethodStep { heading: string; body: string; sourceIds: string[] }
export interface NutritionMethodCopy { title: string; lead: string; steps: NutritionMethodStep[]; clinician: string; sources: CopySource[] }
export type CopyGate = "all" | "adult"; // adult = behind the 18+ nutrition gate (A16.c)
export interface EducationWhisper { id: WhisperId; line: string; moment: string; gate: CopyGate }
export interface EducationSource { label: string; url: string; gate: CopyGate }
export interface EducationSection { id: string; heading: string; body: string; adultBody: string; source: EducationSource | null }
export interface EducationPage { title: string; note: { draft: boolean; heading: string; body: string }; sections: EducationSection[]; whispersHeading: string; clinician: string }
export interface EducationCopy { whispers: EducationWhisper[]; page: EducationPage }
export interface LegalSection { heading: string; paragraphs: string[] }
export interface LegalDocument { title: string; lead: string; sections: LegalSection[] }
export interface LegalCopy { updated: string; privacy: LegalDocument; terms: LegalDocument }`;

export function renderCopyTs(copy) {
  const whisperIds = copy.education.whispers.map((whisper) => JSON.stringify(whisper.id));
  return [
    tsHeader, "",
    `export type WhisperId = ${whisperIds.join(" | ")};`,
    `export const whisperIds: WhisperId[] = [${whisperIds.join(", ")}];`,
    copyTypes, "",
    `export const nutritionMethod: NutritionMethodCopy = ${JSON.stringify(copy.nutritionMethod, null, 2)};`,
    `export const education: EducationCopy = ${JSON.stringify(copy.education, null, 2)};`,
    `export const legal: LegalCopy = ${JSON.stringify(copy.legal, null, 2)};`,
    "",
  ].join("\n");
}
