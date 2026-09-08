// Doctrine lint for the parts ESLint cannot see: every Swift file under ios/ and every CSS file under web/src.
// Rules (5.3, CI-blocking): a protocol with fewer than two concrete conformers (C1) · a numeric literal outside
// Generated/ (allowlist 0, 1 — C7) · Swift files over swiftFileMaxLines (C9) · a TODO/FIXME anywhere
// (compromises live in docs/debt.md, CLAUDE.md rule 9) · a color literal in hand-written CSS (Part III tokens only).
// Run: node shared/scripts/doctrine-lint.mjs   Exits 1 on any finding.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const constants = JSON.parse(readFileSync(join(repoRoot, "shared", "spec-constants.json"), "utf8"));
const swiftFileMaxLines = constants.build.swiftFileMaxLines.value;
const allowlist = new Set(constants.build.numericLiteralAllowlist.value.map(String));
const findings = [];
const report = (file, line, message) => findings.push(`${relative(repoRoot, file).replaceAll("\\", "/")}:${line}: ${message}`);

function walk(dir, extension, out = []) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (entry === "node_modules" || entry === ".next" || entry.endsWith(".xcodeproj") || entry === "DerivedData" || entry === ".build") continue; // .build = SwiftPM output (ios/Package.swift)
    if (statSync(full).isDirectory()) walk(full, extension, out);
    else if (entry.endsWith(extension)) out.push(full);
  }
  return out;
}

const iosDir = join(repoRoot, "ios");
const swiftFiles = walk(iosDir, ".swift");
const isGenerated = (file) => file.replaceAll("\\", "/").includes("/Generated/");
const isTest = (file) => /CrewTests|CrewUITests/.test(file);
// The one named-constants file for non-spec numbers on iOS (the ESLint side exempts http-status/crypto-params/time-units)
const isNamedConstantsFile = (file) => /\/(Api\/HttpStatus|TimeUnits)\.swift$/.test(file.replaceAll("\\", "/"));

// C1 — a protocol needs two concrete conformers somewhere in the app sources
const protocolNames = [];
for (const file of swiftFiles) {
  if (isTest(file)) continue;
  const text = readFileSync(file, "utf8");
  for (const match of text.matchAll(/^\s*(?:public |internal |private |fileprivate )?protocol\s+([A-Za-z_]\w*)/gm)) protocolNames.push({ name: match[1], file });
}
const appSwiftText = swiftFiles.filter((file) => !isTest(file)).map((file) => readFileSync(file, "utf8")).join("\n");
for (const { name, file } of protocolNames) {
  const conformers = [...appSwiftText.matchAll(new RegExp(`(?:struct|class|enum|actor|extension)\\s+\\w+\\s*:[^{]*\\b${name}\\b`, "g"))].length;
  if (conformers < 2) report(file, 1, `C1: protocol ${name} has ${conformers} concrete conformer(s); two are required before a protocol may exist`);
}

// C7 / C9 / TODO — per file
const numericLiteral = /(?<![\w.])(?:0x[0-9A-Fa-f_]+|\d[\d_]*(?:\.\d+)?(?:e[+-]?\d+)?)(?!\w)/g;
for (const file of swiftFiles) {
  const text = readFileSync(file, "utf8");
  const lines = text.split("\n");
  if (lines.length > swiftFileMaxLines && !isGenerated(file)) report(file, lines.length, `C9: ${lines.length} lines, cap is ${swiftFileMaxLines}`);
  lines.forEach((line, index) => {
    const code = line.replace(/\/\/.*$/, "").replace(/"(?:[^"\\]|\\.)*"/g, '""');
    if (/\b(TODO|FIXME)\b/i.test(line)) report(file, index + 1, "TODO/FIXME is banned — record the compromise in docs/debt.md instead");
    if (isGenerated(file) || isTest(file) || isNamedConstantsFile(file)) return;
    for (const match of code.matchAll(numericLiteral)) {
      const literal = match[0].replaceAll("_", "");
      if (!allowlist.has(literal) && !/^\s*(import|@available)/.test(code)) report(file, index + 1, `C7: numeric literal ${match[0]} outside Generated/ — name it in shared/spec-constants.json or design-tokens.json`);
    }
  });
}

// 8.7 — Keychain-only tokens: no Swift file may put an access/refresh token anywhere near UserDefaults (static check)
for (const file of swiftFiles) {
  const code = readFileSync(file, "utf8").split("\n").map((line) => line.replace(/\/\/.*$/, "")).join("\n");
  if (/UserDefaults/.test(code) && /(accessToken|refreshToken)/.test(code)) report(file, 1, "8.7: tokens must live in the Keychain only — this file touches UserDefaults and a token");
}

// Part III — hand-written CSS carries tokens only, never color literals
const cssFiles = walk(join(repoRoot, "web", "src"), ".css").filter((file) => !file.replaceAll("\\", "/").includes("/generated/"));
for (const file of cssFiles) {
  readFileSync(file, "utf8").split("\n").forEach((line, index) => {
    if (/#[0-9A-Fa-f]{3,8}\b|rgba?\(|hsla?\(/.test(line)) report(file, index + 1, "Part III: color literal in hand-written CSS — use an --ember-* token");
    if (/\b(TODO|FIXME)\b/i.test(line)) report(file, index + 1, "TODO/FIXME is banned — record the compromise in docs/debt.md instead");
  });
}

for (const finding of findings) console.log(`DOCTRINE  ${finding}`);
if (findings.length > 0) { console.log(`doctrine-lint: ${findings.length} finding(s)`); process.exit(1); }
console.log(`doctrine-lint: clean — ${swiftFiles.length} Swift files, ${cssFiles.length} hand-written CSS files`);
