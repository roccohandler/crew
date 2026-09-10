"use client";
// SPEC: S17 · A7 — Settings on web, top to bottom: Profile (name + photo) · Plan (pause ≤ 21 days with the return day in
// words, units, timezone) · Notifications (per-row toggles, reminder time, mute) · Privacy & safety (blocked people, privacy
// policy, terms) · Account (export E9, log out, delete E18: two-step, "can't be undone") · the version line. Every number
// is a constant; every row is ink. Web twin of SettingsModel + SettingsScreen.
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { BlockedPeople } from "@/components/BlockedPeople";
import { NotificationRows } from "@/components/NotificationRows";
import { ProfileForm } from "@/components/ProfileForm";
import { logout } from "@/lib/api-client";
import { createPause, deleteAccount, endPause, updateMe } from "@/lib/api-client-crew";
import { addDays } from "@/lib/engine/day-key";
import { dayLabel } from "@/lib/engine/day-label";
import type { PublicUser } from "@/lib/users";
import { SpecConstants } from "@/generated/spec-constants";

// zones come from the server page so the option list hydrates identically (Node and the browser disagree on Intl.supportedValuesOf)
type Props = { user: PublicUser; crew: { id: string; name: string; muted: boolean } | null; pause: { startDay: string; endDay: string } | null; todayKey: string; zones: string[] };

// SPEC: Flow 7 — pause up to pauseMaxDays out; "Until {dayLabel}" while paused (A6: never raw ISO); end early any time
function PauseSection({ pause, todayKey, timezone, onChanged }: { pause: Props["pause"]; todayKey: string; timezone: string; onChanged: () => void }) {
  const [returnDay, setReturnDay] = useState(addDays(todayKey, SpecConstants.pauseDefaultDays));
  const [error, setError] = useState<string | null>(null);
  if (pause) return <div className="stack stack--tight"><h3>Plan paused 🧊</h3><p className="muted">Streak frozen, reminders off, until {dayLabel(pause.endDay, todayKey)}.</p><button type="button" className="button button--secondary" onClick={async () => { await endPause(); onChanged(); }}>End the pause now</button></div>;
  return (
    <div className="stack stack--tight">
      <h3>Pause my plan</h3>
      <p className="muted">{"Vacations and injuries are life, not failure. Pick the day you're back — up to"} {SpecConstants.pauseMaxDays} days out.</p>
      <label className="field"><span>Return date</span><input type="date" min={addDays(todayKey, 1)} max={addDays(todayKey, SpecConstants.pauseMaxDays)} value={returnDay} onChange={(event) => setReturnDay(event.target.value)} /></label>
      {error ? <p className="danger" role="alert">{error}</p> : null}
      <button type="button" className="button button--secondary" onClick={async () => { try { await createPause(todayKey, returnDay, timezone); onChanged(); } catch (caught) { setError((caught as { message?: string }).message ?? "Couldn't pause."); } }}>Pause until then</button>
    </div>
  );
}

// Units and timezone save as soon as they change — a select is its own Save
function PlanSection({ user, zones, onChanged }: { user: PublicUser; zones: string[]; onChanged: () => void }) {
  // SPEC: A9 — weight and distance are chosen separately (a UK lifter loads kilos and runs in miles)
  const change = async (body: { weightUnit?: PublicUser["weightUnit"]; distanceUnit?: PublicUser["distanceUnit"]; timezone?: string }) => { await updateMe(body).catch(() => undefined); onChanged(); };
  return (
    <>
      <label className="field"><span>Weight</span><select value={user.weightUnit} onChange={(event) => void change({ weightUnit: event.target.value as PublicUser["weightUnit"] })}><option value="lb">lb</option><option value="kg">kg</option></select></label>
      <label className="field"><span>Distance</span><select value={user.distanceUnit} onChange={(event) => void change({ distanceUnit: event.target.value as PublicUser["distanceUnit"] })}><option value="mi">mi</option><option value="km">km</option></select></label>
      <label className="field"><span>Timezone</span><select value={user.timezone} onChange={(event) => void change({ timezone: event.target.value })}>{zones.map((zone) => <option key={zone} value={zone}>{zone}</option>)}</select></label>
    </>
  );
}

// SPEC: E18 — delete is two-step and says "can't be undone"; nothing else on the page is red
function AccountSection({ onLogout, onDelete }: { onLogout: () => Promise<void>; onDelete: () => Promise<void> }) {
  const [confirming, setConfirming] = useState(false);
  return (
    <section className="stack stack--tight" aria-label="Account">
      <h2>Account</h2>
      <a className="button button--secondary" href="/api/v1/users/me/export" download="crew-export.json">Export my data (JSON)</a>
      <button type="button" className="button button--secondary" onClick={onLogout}>Log out</button>
      {!confirming ? <button type="button" className="button button--text danger" onClick={() => setConfirming(true)}>Delete account</button> : <div className="card stack stack--tight"><p>{"This deletes your plan, workouts, posts and photos everywhere. It can't be undone."}</p><button type="button" className="button button--primary" onClick={onDelete}>Delete my account</button><button type="button" className="button button--text" onClick={() => setConfirming(false)}>Keep it</button></div>}
    </section>
  );
}

export function SettingsView({ user, crew, pause, todayKey, zones }: Props) {
  const router = useRouter();
  const refresh = () => router.refresh();
  return (
    <div className="stack">
      <h1>Settings</h1>
      <ProfileForm user={user} />
      <section className="card stack stack--tight" aria-label="Plan">
        <h2>Plan</h2>
        <PauseSection pause={pause} todayKey={todayKey} timezone={user.timezone} onChanged={refresh} />
        <PlanSection user={user} zones={zones} onChanged={refresh} />
      </section>
      <NotificationRows user={user} crew={crew} />
      <BlockedPeople />
      <section className="card stack stack--tight" aria-label="Privacy and safety">
        <h2>Privacy &amp; safety</h2>
        <p className="muted">Crew has no public feed. A post is visible only to the crew you shared it with.</p>
        <Link className="button button--text" href="/privacy">Privacy policy</Link>
        <Link className="button button--text" href="/terms">Terms</Link>
      </section>
      <AccountSection onLogout={async () => { await logout(); router.push("/"); }} onDelete={async () => { await deleteAccount(); router.push("/"); }} />
      <p className="whisper">Version {process.env.NEXT_PUBLIC_APP_VERSION ?? "beta"}</p>
    </div>
  );
}
