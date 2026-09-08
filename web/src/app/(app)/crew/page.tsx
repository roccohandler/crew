// SPEC: S12–S13 on web — the unified stream, pulse, member strip, composer, reactions with a visible button (6.7), invite/create/
// leave; Flow 10 (solo: one warm invitation); Part IV (polling 5–10 s). T038
import { redirect } from "next/navigation";
import { CrewView } from "@/components/CrewView";
import { readSession } from "@/lib/session";

export default async function CrewPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  return <CrewView myUserId={session.user.id} />;
}
