// SPEC: A16.c · nutrition addendum §6 · A22 G3 (owner-approved 2026-09-18) — the one gate every nutrition PAGE passes first, the
// page-side twin of lib/nutrition-access.ts. Under 18 the surface does not exist: the page is a 404 like any unknown path — no copy,
// no upsell, no "unlock at 18". An account with no birth year is asked for it once, here, when Nutrition is opened — never at launch.
import { notFound, redirect } from "next/navigation";
import { readSession } from "@/lib/session";
import type { PublicUser } from "@/lib/users";

export async function openNutrition(): Promise<{ user: PublicUser; askBirthYear: boolean }> {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  if (session.user.nutrition === "absent") notFound();
  return { user: session.user, askBirthYear: session.user.nutrition === "askBirthYear" };
}
