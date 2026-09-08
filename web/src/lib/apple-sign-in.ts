// SPEC: docs/api.md POST auth/apple — find-or-create the User by appleSub (E18: re-signup after deletion is a fresh
// identity, so a deleted account's sub simply creates a new user) · E9 gates on first sign-in only · T012
import { ObjectId } from "mongodb";
import type { AppleIdentity } from "@/lib/apple-auth";
import { users } from "@/lib/db";
import type { UserDoc } from "@/lib/documents";
import { logEvent } from "@/lib/events";
import { createUserWithState, requireSignupGates } from "@/lib/users";

interface AppleSignInInput {
  identity: AppleIdentity;
  displayName?: string;
  timezone: string;
  eulaAccepted: boolean;
  birthYear?: number;
}

function fallbackEmail(sub: string): string {
  return `apple-${sub.replace(/[^a-z0-9]/gi, "").toLowerCase()}@privaterelay.crew.invalid`;
}

function fallbackDisplayName(email: string): string {
  return email.split("@")[0] ?? "Crew member";
}

export async function signInOrCreateAppleUser(input: AppleSignInInput): Promise<{ user: UserDoc; created: boolean }> {
  const collection = await users();
  const existing = await collection.findOne({ appleSub: input.identity.sub });
  if (existing !== null) {
    await logEvent(existing._id.toHexString(), "login", { provider: "apple" });
    return { user: existing, created: false };
  }
  requireSignupGates(input.eulaAccepted, input.birthYear);
  const email = input.identity.email ?? fallbackEmail(input.identity.sub);
  const byEmail = await collection.findOne({ emailLower: email.toLowerCase() });
  if (byEmail !== null && byEmail.appleSub === undefined) {
    // Same verified email, previously email/password: link the Apple subject to the existing account
    await collection.updateOne({ _id: byEmail._id }, { $set: { appleSub: input.identity.sub } });
    await logEvent(byEmail._id.toHexString(), "login", { provider: "apple", linked: true });
    return { user: { ...byEmail, appleSub: input.identity.sub }, created: false };
  }
  const user = await createUserWithState({
    email,
    authProvider: "apple",
    appleSub: input.identity.sub,
    displayName: input.displayName ?? fallbackDisplayName(email),
    timezone: input.timezone,
  });
  await logEvent(user._id.toHexString(), "account_created", { provider: "apple" });
  return { user, created: true };
}

export function asObjectId(value: string): ObjectId {
  return new ObjectId(value);
}
