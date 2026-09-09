"use client";
// SPEC: S17 · A7 — per-row notification toggles backed by server fields (notificationPrefs, merged server-side): Workout
// reminder + its time (the stored value; G12: 7:30 is only a placeholder, never saved on its own), Streak reminder, Crew
// activity, Mute {crew} (initial state from the membership). Web has no push: reminders reach the iPhone app. Footer: the
// one email promise. Web twin of the ios Notifications section.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { muteCrew, updateMe } from "@/lib/api-client-crew";
import type { NotificationPrefs } from "@/lib/documents";
import type { PublicUser } from "@/lib/users";

type Props = { user: PublicUser; crew: { id: string; name: string; muted: boolean } | null };

function Switch({ label, checked, onChange }: { label: string; checked: boolean; onChange: (next: boolean) => Promise<void> }) {
  return <label className="switch"><span>{label}</span><input type="checkbox" checked={checked} onChange={(event) => void onChange(event.target.checked)} /></label>;
}

export function NotificationRows({ user, crew }: Props) {
  const router = useRouter();
  const [prefs, setPrefs] = useState<NotificationPrefs>(user.notificationPrefs);
  const [reminderTime, setReminderTime] = useState(user.reminderTime ?? "");
  const [status, setStatus] = useState<string | null>(null);
  const saved = () => setStatus("Saved.");
  const failed = () => setStatus("Couldn't save. Try again.");
  // SPEC: A7 — one field per toggle, sent partial, merged by the server
  const setPref = async (key: keyof NotificationPrefs, value: boolean) => {
    setPrefs({ ...prefs, [key]: value });
    await updateMe({ notificationPrefs: { [key]: value } }).then(saved).catch(() => { setPrefs(prefs); failed(); });
  };
  const saveTime = async (value: string) => {
    setReminderTime(value);
    await updateMe({ reminderTime: value.length > 0 ? value : null }).then(saved).catch(failed);
  };
  return (
    <section className="card stack stack--tight" aria-label="Notifications">
      <h2>Notifications</h2>
      <p className="whisper">{"Push isn't on web yet — you'll see it in the iPhone app."}</p>
      <Switch label="Workout reminder" checked={prefs.workoutReminder} onChange={(next) => setPref("workoutReminder", next)} />
      <label className="field"><span>Time</span><input type="time" placeholder="07:30" value={reminderTime} disabled={!prefs.workoutReminder} onChange={(event) => void saveTime(event.target.value)} /></label>
      <Switch label="Streak reminder" checked={prefs.streakRisk} onChange={(next) => setPref("streakRisk", next)} />
      <Switch label="Crew activity" checked={prefs.crewActivity} onChange={(next) => setPref("crewActivity", next)} />
      {crew ? <Switch label={`Mute ${crew.name}`} checked={crew.muted} onChange={async (next) => { await muteCrew(crew.id, next); router.refresh(); }} /> : null}
      <p className="whisper">We only email you for password resets and account deletion.</p>
      {status ? <p className="muted" role="status">{status}</p> : null}
    </section>
  );
}
