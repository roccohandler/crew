// SPEC: S14 Plan on web · A4 (the week map: 7 rows, zero controls; the workout editor lives at /plan/[kind]) · A1 (the rows
// come from the rotation projection, the pointer derived from history — rotationFor). Rebuild goes through the questions
// again; forward-only stated in copy. T038 (Flow 8)
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { EmptyState } from "@/components/EmptyState";
import { WeekOverview } from "@/components/WeekOverview";
import { dayKeyFor } from "@/lib/engine/day-key";
import { findPlan } from "@/lib/plans";
import { readSession } from "@/lib/session";
import { rotationFor } from "@/lib/today-state";

export default async function PlanPage({ searchParams }: { searchParams: Promise<{ saved?: string }> }) {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const plan = await findPlan(userId);
  if (plan === null) return <EmptyState title="No plan yet" line="Answer three questions and your week is built." ctaTitle="Build my week" href="/onboarding" />;
  const rotation = await rotationFor(userId, plan, dayKeyFor(new Date(), session.user.timezone));
  const { saved } = await searchParams;
  const savedName = plan.workouts.find((workout) => workout.kind === saved)?.name ?? null;
  return <WeekOverview trainingWeekdays={plan.trainingWeekdays} workouts={plan.workouts} week={rotation.week} cycle={rotation.cycle} nextKind={rotation.nextKind} savedName={savedName} />;
}
