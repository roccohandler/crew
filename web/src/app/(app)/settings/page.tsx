// SPEC: S17 Settings on web — pause flow (≤ 21 days, no retro), per-crew mute, notification note (no push on web: in-app only),
// units, timezone, reminder time (G12: no silent default), JSON export, delete = two-step "can't be undone". T041 (web half)
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { SettingsView } from "@/components/SettingsView";
import { crewMemberships, crews } from "@/lib/db";
import { dayKeyFor } from "@/lib/engine/day-key";
import { currentPause, pauseResponse } from "@/lib/pauses";
import { readSession } from "@/lib/session";

export default async function SettingsPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const membership = await (await crewMemberships()).findOne({ userId });
  const crew = membership ? await (await crews()).findOne({ _id: membership.crewId }) : null;
  const pause = await currentPause(userId, dayKeyFor(new Date(), session.user.timezone));
  return <SettingsView user={session.user} crew={crew ? { id: crew._id.toHexString(), name: crew.name, muted: membership?.mutedAt !== null } : null} pause={pause ? pauseResponse(pause) : null} todayKey={dayKeyFor(new Date(), session.user.timezone)} zones={Intl.supportedValuesOf("timeZone")} />;
}
