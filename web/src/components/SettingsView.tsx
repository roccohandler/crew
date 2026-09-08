"use client";
// SPEC: S17 — profile, units, timezone, reminder time (G12 suggestion 7:30 as placeholder, never silently set), mute, pause
// (Flow 7: pick a return date ≤ 21 days), export (E9), log out, delete (E18: two-step, "can't be undone"). Web twin of SettingsModel.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { logout } from "@/lib/api-client";
import { createPause, deleteAccount, endPause, muteCrew, updateMe } from "@/lib/api-client-crew";
import { addDays } from "@/lib/engine/day-key";
import type { PublicUser } from "@/lib/users";
import { SpecConstants } from "@/generated/spec-constants";

// zones come from the server page so the option list hydrates identically (Node and the browser disagree on Intl.supportedValuesOf)
type Props = { user: PublicUser; crew: { id: string; name: string; muted: boolean } | null; pause: { startDay: string; endDay: string } | null; todayKey: string; zones: string[] };

function PauseSection({ pause, todayKey, timezone, onChanged }: { pause: Props["pause"]; todayKey: string; timezone: string; onChanged: () => void }) {
  const [returnDay, setReturnDay] = useState(addDays(todayKey, SpecConstants.pauseDefaultDays));
  const [error, setError] = useState<string | null>(null);
  if (pause) return <section className="card stack stack--tight"><h2>Plan paused 🧊</h2><p className="muted">Streak frozen, reminders off, until {pause.endDay}.</p><button type="button" className="button button--secondary" onClick={async () => { await endPause(); onChanged(); }}>End the pause now</button></section>;
  return (
    <section className="card stack stack--tight">
      <h2>Pause my plan</h2>
      <p className="muted">{"Vacations and injuries are life, not failure. Pick the day you're back — up to"} {SpecConstants.pauseMaxDays} days out.</p>
      <label className="field"><span>Return date</span><input type="date" min={addDays(todayKey, 1)} max={addDays(todayKey, SpecConstants.pauseMaxDays)} value={returnDay} onChange={(event) => setReturnDay(event.target.value)} /></label>
      {error ? <p className="danger" role="alert">{error}</p> : null}
      <button type="button" className="button button--secondary" onClick={async () => { try { await createPause(todayKey, returnDay, timezone); onChanged(); } catch (caught) { setError((caught as { message?: string }).message ?? "Couldn't pause."); } }}>Pause until then</button>
    </section>
  );
}

export function SettingsView({ user, crew, pause, todayKey, zones }: Props) {
  const router = useRouter();
  const [profile, setProfile] = useState({ displayName: user.displayName, units: user.units, timezone: user.timezone, reminderTime: user.reminderTime ?? "" });
  const [confirming, setConfirming] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const saveProfile = async () => { await updateMe({ displayName: profile.displayName, units: profile.units, timezone: profile.timezone, reminderTime: profile.reminderTime.length > 0 ? profile.reminderTime : null }); setStatus("Saved."); router.refresh(); };
  return (
    <div className="stack">
      <h1>Settings</h1>
      <section className="card stack stack--tight">
        <label className="field"><span>Name</span><input value={profile.displayName} maxLength={SpecConstants.displayNameMaxChars} onChange={(event) => setProfile({ ...profile, displayName: event.target.value })} /></label>
        <label className="field"><span>Units</span><select value={profile.units} onChange={(event) => setProfile({ ...profile, units: event.target.value as "lb" | "kg" })}><option value="lb">lb</option><option value="kg">kg</option></select></label>
        <label className="field"><span>Timezone</span><select value={profile.timezone} onChange={(event) => setProfile({ ...profile, timezone: event.target.value })}>{zones.map((zone) => <option key={zone} value={zone}>{zone}</option>)}</select></label>
        <label className="field"><span>Workout reminder (in-app on web)</span><input type="time" placeholder="07:30" value={profile.reminderTime} onChange={(event) => setProfile({ ...profile, reminderTime: event.target.value })} /></label>
        <button type="button" className="button button--primary" onClick={saveProfile}>Save</button>
        {status ? <p className="muted" role="status">{status}</p> : null}
      </section>
      {crew ? <section className="card row row--between"><span>Mute {crew.name}</span><input type="checkbox" checked={crew.muted} onChange={async (event) => { await muteCrew(crew.id, event.target.checked); router.refresh(); }} aria-label={`Mute ${crew.name}`} /></section> : null}
      <PauseSection pause={pause} todayKey={todayKey} timezone={user.timezone} onChanged={() => router.refresh()} />
      <a className="button button--secondary" href="/api/v1/users/me/export" download="crew-export.json">Export my data (JSON)</a>
      <button type="button" className="button button--secondary" onClick={async () => { await logout(); router.push("/"); }}>Log out</button>
      {!confirming ? <button type="button" className="button button--text danger" onClick={() => setConfirming(true)}>Delete account</button> : <section className="card stack stack--tight"><p>{"This deletes your plan, workouts, posts and photos everywhere. It can't be undone."}</p><button type="button" className="button button--primary" onClick={async () => { await deleteAccount(); router.push("/"); }}>Delete my account</button><button type="button" className="button button--text" onClick={() => setConfirming(false)}>Keep it</button></section>}
    </div>
  );
}
