// SPEC: S09 Session on web (keyboard-first, T037) — the logger is a client component fed the session, units, last-time lines and
// whether a crew exists (share toggle). Own sessions only (8.2 ①).
import { ObjectId } from "mongodb";
import { notFound, redirect } from "next/navigation";
import { SessionLogger } from "@/components/SessionLogger";
import { crewMemberships, sessions } from "@/lib/db";
import { lastTimeLines } from "@/lib/last-time";
import { readSession } from "@/lib/session";
import { sessionResponse } from "@/lib/sessions";

export default async function SessionPage({ params }: { params: Promise<{ id: string }> }) {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const { id } = await params;
  const userId = new ObjectId(session.user.id);
  const doc = ObjectId.isValid(id) ? await (await sessions()).findOne({ _id: new ObjectId(id), userId }) : null;
  if (doc === null) notFound();
  if (doc.status === "completed") redirect(`/session/${id}/done`);
  const lastTime = await lastTimeLines(userId, doc.exercises.map((exercise) => exercise.exerciseId), doc._id, session.user.weightUnit);
  const inCrew = (await (await crewMemberships()).findOne({ userId })) !== null;
  return <SessionLogger initial={sessionResponse(doc)} units={session.user.weightUnit} distanceUnit={session.user.distanceUnit} timezone={session.user.timezone} lastTime={lastTime} inCrew={inCrew} />;
}
