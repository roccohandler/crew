// SPEC: S14 Plan editor on web — Mon–Sun at a glance; tiered editing (swap / tune / full); limits enforced by input constraints;
// Rebuild goes through the questions again; forward-only stated in copy. T038 (Flow 8)
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { EmptyState } from "@/components/EmptyState";
import { PlanEditor } from "@/components/PlanEditor";
import { findPlan } from "@/lib/plans";
import { readSession } from "@/lib/session";

export default async function PlanPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const plan = await findPlan(new ObjectId(session.user.id));
  if (plan === null) return <EmptyState title="No plan yet" line="Answer three questions and your week is built." ctaTitle="Build my week" href="/onboarding" />;
  return <PlanEditor initial={{ workouts: plan.workouts }} />;
}
