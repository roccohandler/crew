// SPEC: 5.3 lint rules that enforce doctrine (CI-blocking): no numeric literal outside Generated (allowlist 0, 1 — C7) ·
// file length caps (C9: TS ≤ 150) · functions ≤ ~40 lines (C9) · no TODO without a debt entry (TODO is banned outright;
// docs/debt.md is the place) · no barrel files / re-exports (C12) · no classes, generics, or `implements` in app code
// (C1, C2, C6) · formatting is Prettier's (5.3). Tests and config carry numbers by nature and are exempt from C7.
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import specConstants from "../shared/spec-constants.json" with { type: "json" };

const tsFileMaxLines = specConstants.build.tsFileMaxLines.value;
const functionMaxLines = specConstants.build.functionMaxLines.value;
// The allowlist (0, 1) and their negations: `-1` is the same literal with a sign, not a magic number.
const numericAllowlist = [...new Set(specConstants.build.numericLiteralAllowlist.value.flatMap((literal) => [literal, -literal]))];

export default defineConfig([
  ...nextVitals,
  ...nextTs,
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts", "playwright-report/**", "test-results/**", "src/generated/**"]),
  {
    files: ["src/**/*.{ts,tsx}"],
    rules: {
      "no-magic-numbers": ["error", { ignore: numericAllowlist, ignoreArrayIndexes: true, ignoreDefaultValues: false, enforceConst: true, detectObjects: false }],
      "max-lines": ["error", { max: tsFileMaxLines, skipBlankLines: false, skipComments: false }],
      "max-lines-per-function": ["error", { max: functionMaxLines, skipBlankLines: true, skipComments: true, IIFEs: true }],
      "no-warning-comments": ["error", { terms: ["todo", "fixme"], location: "anywhere" }],
      // Photos are private, cookie-authenticated and already resized server-side (8.7, 8.8); next/image cannot proxy them
      "@next/next/no-img-element": "off",
      "no-restricted-syntax": [
        "error",
        { selector: "ExportAllDeclaration", message: "C12: no barrel files or re-exports — import from the real file." },
        { selector: "ExportNamedDeclaration[source]", message: "C12: no re-exports — import from the real file." },
        { selector: "ClassDeclaration", message: "C2: no classes in app code — plain functions and plain data." },
        { selector: "TSTypeParameterDeclaration", message: "C1: no generics in app code (standard-library generics are fine at call sites)." },
        { selector: "TSInterfaceDeclaration[extends.length>0]", message: "C1: no interface hierarchies — one concrete shape per DTO." },
      ],
    },
  },
  {
    // The three named-constants files: HTTP statuses, crypto parameters, time units — implementation numbers
    // that are not spec numbers live here and nowhere else (the C7 idea applied to non-spec numbers).
    files: ["src/lib/http-status.ts", "src/lib/crypto-params.ts", "src/lib/time-units.ts", "src/lib/geometry.ts"],
    rules: { "no-magic-numbers": "off" },
  },
  {
    files: ["tests/**/*.ts", "*.config.ts", "*.config.mjs"],
    rules: { "no-magic-numbers": "off", "max-lines": "off", "max-lines-per-function": "off" },
  },
]);
