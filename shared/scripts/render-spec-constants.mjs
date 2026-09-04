// Renders shared/spec-constants.json as SpecConstants.swift and spec-constants.ts.
// SPEC: C7 (every spec number lives in one file, named for its rule) · Part V 5.2 Generated/

const header = `// GENERATED FILE — DO NOT EDIT. Source: shared/spec-constants.json · Generator: shared/scripts/generate.mjs
// Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts.
// SPEC: C7 — every tunable in the spec, named for its rule.`;

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

export function renderSpecConstantsSwift(sections) {
  const lines = [header, "", "enum SpecConstants {"];
  for (const [section, entries] of Object.entries(sections)) {
    lines.push(`    // MARK: ${section}`);
    for (const [name, entry] of Object.entries(entries)) {
      lines.push(`    /// SPEC: ${entry.spec}`);
      lines.push(`    static let ${name}: ${swiftType(entry)} = ${literal(entry.value)}`);
    }
    lines.push("");
  }
  lines.pop();
  lines.push("}", "");
  return lines.join("\n");
}

export function renderSpecConstantsTs(sections) {
  const lines = [header, "", "export const SpecConstants = {"];
  for (const [section, entries] of Object.entries(sections)) {
    lines.push(`  // --- ${section} ---`);
    for (const [name, entry] of Object.entries(entries)) {
      lines.push(`  /** SPEC: ${entry.spec} */`);
      lines.push(`  ${name}: ${literal(entry.value)},`);
    }
    lines.push("");
  }
  lines.pop();
  lines.push("} as const;", "");
  return lines.join("\n");
}
