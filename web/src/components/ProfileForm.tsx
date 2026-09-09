"use client";
// SPEC: E1 · A7 — profile on web: the avatar (photo when a key exists, initials until then), a photo picker (camera or library
// through the browser's file input), Remove photo, the Name field (≤ displayNameMaxChars), Save. The picked file uploads with
// purpose "profile", then PATCH users/me carries profilePhotoKey + displayName together. Web twin of ios EditProfileScreen.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { initialsOf } from "@/components/CrewHeader";
import { isApiClientError, uploadPhoto } from "@/lib/api-client";
import { updateMe } from "@/lib/api-client-crew";
import type { PublicUser } from "@/lib/users";
import { SpecConstants } from "@/generated/spec-constants";

const failureLine = (caught: unknown, fallback: string) => (isApiClientError(caught) ? caught.message : fallback);

export function ProfileForm({ user }: { user: PublicUser }) {
  const router = useRouter();
  const [displayName, setDisplayName] = useState(user.displayName);
  const [photoKey, setPhotoKey] = useState(user.profilePhotoKey);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const pick = async (file: File | undefined) => {
    if (!file) return;
    setBusy(true);
    try { setPhotoKey((await uploadPhoto(file, "profile")).photoKey); setStatus("Photo ready. Save to keep it."); }
    catch (caught) { setStatus(failureLine(caught, "Couldn't upload that photo. Try another.")); }
    setBusy(false);
  };
  const save = async () => {
    setBusy(true);
    try { await updateMe({ displayName: displayName.trim(), profilePhotoKey: photoKey }); setStatus("Saved."); router.refresh(); }
    catch (caught) { setStatus(failureLine(caught, "Couldn't save. Try again.")); }
    setBusy(false);
  };
  return (
    <section className="card stack stack--tight" aria-label="Profile">
      <h2>Profile</h2>
      <div className="row">
        <span className="avatar avatar--large">{photoKey ? <img className="avatar__photo" src={`/api/v1/photos/${photoKey}`} alt="Your profile photo" /> : initialsOf(displayName || user.displayName)}</span>
        <div className="stack stack--tight">
          <label className="field"><span>Photo</span><input type="file" accept="image/*" disabled={busy} onChange={(event) => void pick(event.target.files?.[0])} /></label>
          {photoKey ? <button type="button" className="button button--text" onClick={() => setPhotoKey(null)}>Remove photo</button> : null}
        </div>
      </div>
      <label className="field"><span>Name</span><input value={displayName} maxLength={SpecConstants.displayNameMaxChars} onChange={(event) => setDisplayName(event.target.value)} /></label>
      <p className="whisper">Your photo and name are all your crew sees. Location data is stripped from photos.</p>
      <button type="button" className="button button--primary" disabled={busy || displayName.trim().length === 0} onClick={save}>Save</button>
      {status ? <p className="muted" role="status">{status}</p> : null}
    </section>
  );
}
