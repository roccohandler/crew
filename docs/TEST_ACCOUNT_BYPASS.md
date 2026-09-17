# Test-account bypass — re-running onboarding in production with one Gmail inbox

Owner goal: re-run onboarding in production repeatedly with his own Gmail inbox, without weakening any check for anyone
else. Investigated read-only on 2026-09-17 at commit `7fa7e52`; findings reuse `docs/MVP_STATE_REPORT.md` §3 and §9.

## Step 1 — Findings

**a. Email uniqueness on signup.** One rule, applied identically everywhere: the exact address, lower-cased.

- The unique index is on `emailLower` (`web/src/lib/db.ts:63`).
- `POST auth/register` looks up `{ emailLower: body.email.toLowerCase() }` and answers `409 emailTaken` when it exists
  (`web/src/app/api/v1/auth/register/route.ts:17-18`); the stored value is `input.email.toLowerCase()`
  (`web/src/lib/users.ts:102`). Sign in with Apple links to an existing account by the same exact lower-cased email
  (`web/src/lib/apple-sign-in.ts:36`).
- **No normalisation of Gmail plus-addressing or dots exists.** `grep -rn -i "gmail\|plus\|split('+')"` over
  `validate.ts`, `users.ts` and `app/api/v1/auth` returns nothing. The only email validation is `z.email().max(…)`
  (`web/src/lib/validate.ts:24`), and zod accepts plus-addressed and dotted forms — verified with the installed zod:

  ```
  max+1@gmail.com => true · max+onboard.2@gmail.com => true · m.a.x@gmail.com => true · Max@Gmail.com => true
  ```

  So `owner+1@gmail.com` and `owner+2@gmail.com` are two different accounts to the server, and Gmail delivers both to the
  `owner@gmail.com` inbox. The duplicate-email test pins case-insensitivity only (`web/tests/api/auth.test.ts:34-37`).

**b. In-app account deletion.** A hard delete, immediate, no retention window.

- `deleteAccount` (`web/src/lib/account-delete.ts:11-34`) removes posts, sessions, plan, reactions given, messages,
  pauses, blocks, refresh tokens, password resets, push tokens, gamification state, notification log and photos (blob
  objects included), anonymises analytics events, then `deleteOne`s the user (`:32`). `UserDoc.deletedAt` is declared but
  never written (audit §3), so there is no soft-delete path.
- The unique index therefore frees the email the moment the document is gone; `web/tests/api/account.test.ts:93-103`
  registers again with the same email after deletion and asserts a fresh account ("re-signup is fresh").
- What survives deletion (audit §9): `reports` naming the user, reactions other people gave on the deleted posts, event
  props, dev-only outbox rows. None of it blocks or alters a re-signup.

**c. Other per-email gates in onboarding.** None on the email itself.

- No email verification: `register` issues tokens immediately (`register/route.ts:22`).
- The only signup gate is per **IP**, not per email: `limitAuthByIp` allows 10 auth requests per minute per IP
  (`web/src/lib/rate-limit.ts:46-48`, spec G11) on register, login, apple, reset and reset/confirm. Re-running onboarding
  more than ~5 times a minute from one address (register + login count separately) returns `429 rateLimited` — wait a minute.
- Invite consumption is per **account** (one crew per user: unique membership index `db.ts:73`, checked in
  `crews.ts:48`), not per email; each plus-addressed account can join a crew once.
- Password-reset mail goes to the exact stored address (`auth/reset/route.ts:16-19`); Gmail routes `owner+3@gmail.com`
  to the base inbox, so resets on a variant work.
- The EULA and 13+ gates run on every registration (`users.ts:63-68`) and are unaffected.

## Step 2 — Branch taken: **plus-addressed variants already register as distinct accounts → no code change.**

Test loop in production, entirely with the existing rules:

1. Sign up with `owner+1@gmail.com`; the next run uses `owner+2@gmail.com`, then `owner+3@gmail.com`, … (any tag after
   the `+` works — `owner+ios-17@gmail.com`, `owner+2026-09-17@gmail.com`). Mail for every variant lands in the base inbox.
2. Never register the bare base address as a test account; the purge script below leaves it alone by design.
3. If a run must reuse the *same* variant, Settings → Delete account frees it immediately (finding b) — so
   "delete account → re-onboard" is also a valid loop, with the same address every time.
4. Sign in with Apple is a separate identity (`appleSub`); it does not collide with a plus-addressed email account unless
   Apple hands back that exact email.

Nothing about the uniqueness check, normalisation, rate limits or deletion changes for anyone. `TEST_EMAIL_ALLOWLIST` is
**not read by the server in this branch**; it exists only to tell the purge script which bases are the owner's.

## Step 3 — `web/scripts/purge-test-accounts.ts` (local only)

Deletes every `base+<tag>@<domain>` account for each base in `TEST_EMAIL_ALLOWLIST`, through the app's own
`deleteAccount` cascade — the same function `DELETE users/me` calls — so posts, crew memberships (with captaincy hand-off
or crew archive), uploads and their blobs go with it. It prints each deleted address and id, a per-base count and the total.

```
cd web
TEST_EMAIL_ALLOWLIST=owner@gmail.com node scripts/purge-test-accounts.ts
```

- Reads `MONGODB_URI` / `MONGODB_DB` like every lib file; with `RESEND_API_KEY` in the local environment each deletion
  also sends the normal "Your Crew account is deleted" email (to the variant, i.e. the base inbox); without it the mail
  goes to the `emailOutbox` collection as in tests.
- Never callable from the server: it lives outside `src/app`, refuses to run when `VERCEL` or `NEXT_RUNTIME` is set, and
  no route imports it. `web/scripts/alias-hooks.mjs` is the four-line resolver that lets plain `node` follow the app's
  `@/` imports (Node has no tsconfig `paths`); it is registered by the script itself and used by nothing else.
- With an empty or unset allowlist it prints "nothing to purge" and exits 0. The base address itself never matches the
  pattern (`^local\+[^@]+@domain$`).

## Step 4 — Launch gate and registry

- Launch checklist (`docs/OWNER-REVIEW.md` §6, step 10): **`TEST_EMAIL_ALLOWLIST` unset in production before public launch.**
- Decision Registry (`docs/crew-mvp-spec.md`, Appendix A, entry dated 2026-09-17): owner-approved — plus-addressed variants
  stay distinct accounts by the existing exact-email rule (no normalisation is added, deliberately), the purge script is
  the only consumer of the allowlist, and the launch gate above.
- `web/.env.example` documents the variable (empty by default).

Files touched by Part B: this document, `web/scripts/purge-test-accounts.ts`, `web/scripts/alias-hooks.mjs`,
`web/.env.example`, `docs/OWNER-REVIEW.md`, `docs/crew-mvp-spec.md`, `docs/commit-queue.sh` (block F52). No app code changed.
