// Module-resolution hooks for the LOCAL scripts in this folder, and nothing else. The app's own files import each other
// through the `@/` alias that tsconfig.json declares (`"@/*": ["./src/*"]`) and that Next, Vitest and ESLint all
// understand — but plain `node` does not, and a script that wants to reuse the app's real functions (the account
// cascade, the collection getters) has to import them from the real files (C12: no barrel, no copy). This maps `@/x`
// to `src/x`, trying the extensions TypeScript leaves off, and hands everything else back to Node. Registered by the
// script itself (`register("./alias-hooks.mjs", import.meta.url)`), so no command-line flag is needed.
// SPEC: docs/TEST_ACCOUNT_BYPASS.md · C6 (no clever code: one resolve hook, four candidate paths, no rewriting of anything else)
import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";

const ALIAS = "@/";
const srcRoot = new URL("../src/", import.meta.url);

export async function resolve(specifier, context, nextResolve) {
  if (!specifier.startsWith(ALIAS)) return nextResolve(specifier, context);
  const base = new URL(specifier.slice(ALIAS.length), srcRoot).href;
  for (const candidate of [base, `${base}.ts`, `${base}.tsx`, `${base}/index.ts`]) {
    if (existsSync(fileURLToPath(candidate))) return { url: candidate, shortCircuit: true };
  }
  return nextResolve(specifier, context);
}
