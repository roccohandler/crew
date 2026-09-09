// SPEC: A4 — the workout editor for one workout of the rotation, keyed by kind (A1: no weekday). An unknown kind goes back
// to the week map. The client editor starts from the saved plan and only Save writes it, forward-only (Flow 8).
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { WorkoutEditor } from "@/components/WorkoutEditor";
import { findPlan } from "@/lib/plans";
import { readSession } from "@/lib/session";

export default async function WorkoutPage({ params }: { params: Promise<{ kind: string }> }) {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const { kind } = await params;
  const plan = await findPlan(new ObjectId(session.user.id));
  const workout = plan?.workouts.find((candidate) => candidate.kind === kind);
  if (plan === null || workout === undefined) redirect("/plan");
  return <WorkoutEditor trainingWeekdays={plan.trainingWeekdays} workouts={plan.workouts} workout={workout} />;
}
