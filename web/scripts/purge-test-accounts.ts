// Purge the owner's plus-addressed test accounts — LOCAL ONLY. Run from web/ with the database in the environment:
//     cd web && TEST_EMAIL_ALLOWLIST=you@gmail.com node scripts/purge-test-accounts.ts
// For every base email in TEST_EMAIL_ALLOWLIST (comma-separated, empty by default) it finds every account whose
// stored email is `<local>+<tag>@<domain>` — the base address itself is never touched — and deletes each one through
// the app's own cascade (lib/account-delete.ts: crew exit, posts, sessions, plan, reactions, messages, pauses, blocks,
// tokens, push tokens, gamification, notification log, photos and their blobs, then the user, then the "account
// deleted" email). It prints what it deleted and nothing else changes.
// It is never callable from the server: this file lives outside src/app (Next routes nothing here), it refuses to run
// when Vercel's environment is present, and the allowlist is read by this script alone — the API never sees it.
// SPEC: docs/TEST_ACCOUNT_BYPASS.md (owner-approved 2026-09-17) · E9/E18 (delete is real; re-signup is a fresh start) ·
// C5 (the cascade is reused, not copied) · launch gate: TEST_EMAIL_ALLOWLIST unset in production before public launch.
import { register } from "node:module";

register("./alias-hooks.mjs", import.meta.url); // plain node cannot resolve the app's `@/` alias; see alias-hooks.mjs
const { deleteAccount } = await import("@/lib/account-delete");
const { closeDb, users } = await import("@/lib/db");

if (process.env.VERCEL !== undefined || process.env.NEXT_RUNTIME !== undefined) {
  console.error("purge-test-accounts runs on a laptop against the database, never on a server.");
  process.exit(1);
}

const bases = (process.env.TEST_EMAIL_ALLOWLIST ?? "")
  .split(",")
  .map((entry) => entry.trim().toLowerCase())
  .filter((entry) => entry.length > 0);

if (bases.length === 0) {
  console.log("TEST_EMAIL_ALLOWLIST is empty — nothing to purge.");
  process.exit(0);
}

// A literal for a regex: every metacharacter escaped, so a dot in a domain matches a dot and nothing else
function escapeForRegex(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

let deletedTotal = 0;
const collection = await users();
for (const base of bases) {
  const [local, domain] = base.split("@");
  if (local === undefined || domain === undefined || local.length === 0 || domain.length === 0 || base.split("@").length !== "a@b".split("@").length) {
    console.error(`skip: "${base}" is not an email address`);
    continue;
  }
  // emailLower is what the unique index and the signup check use (lib/db.ts, auth/register/route.ts)
  const pattern = `^${escapeForRegex(local)}\\+[^@]+@${escapeForRegex(domain)}$`;
  const matches = await collection.find({ emailLower: { $regex: pattern } }).sort({ createdAt: 1 }).toArray();
  for (const doc of matches) {
    await deleteAccount(doc._id);
    deletedTotal += 1;
    console.log(`deleted ${doc.email} (${doc._id.toHexString()}, created ${doc.createdAt.toISOString()})`);
  }
  console.log(`${base}: ${matches.length} test account(s) deleted`);
}
console.log(`done — ${deletedTotal} account(s) deleted in total`);
await closeDb();
