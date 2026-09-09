"use client";
// SPEC: Flow 4 — camera-first (`capture="environment"`), time-smart tags (one tap only if wrong), same-as-yesterday ↻, text-only is
// legit, same-day backfill, caption ≤ 280, no filters; photo → POST photos → POST posts. A1: isPlannedDay comes from the page
// (today ∈ trainingWeekdays), never hard-coded. Web twin of ios PostModel + PostComposer.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { createPost, earnedQuery, isApiClientError, uploadPhoto } from "@/lib/api-client";
import { mealTagEmoji, mealTagFor, type MealTag } from "@/lib/engine/meal-tag";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const TAGS: MealTag[] = ["breakfast", "lunch", "dinner", "snack"];

function TagPicker({ tag, onPick }: { tag: MealTag; onPick: (tag: MealTag) => void }) {
  return (
    <div className="row" role="group" aria-label="Meal">
      {TAGS.map((candidate) => <button key={candidate} type="button" className="toggle" aria-pressed={tag === candidate} aria-label={candidate} onClick={() => onPick(candidate)}>{mealTagEmoji[candidate]}</button>)}
    </div>
  );
}

export function PostComposer({ timezone, inCrew, isPlannedDay, yesterday }: { timezone: string; inCrew: boolean; isPlannedDay: boolean; yesterday: { caption: string; mealTag: string | null } | null }) {
  const router = useRouter();
  const now = new Date();
  const [tag, setTag] = useState<MealTag>(mealTagFor(now.getHours() * TimeUnits.minutesPerHour + now.getMinutes()));
  const [file, setFile] = useState<File | null>(null);
  const [caption, setCaption] = useState("");
  const [earlier, setEarlier] = useState(false);
  const [share, setShare] = useState(true);
  const [repeated, setRepeated] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const canSubmit = file !== null || caption.trim().length > 0;

  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      const photoKey = file ? (await uploadPhoto(file, "post")).photoKey : undefined;
      const reply = await createPost({ clientId: crypto.randomUUID(), type: "meal", photoKey, caption: repeated ? `↻ ${caption}` : caption, mealTag: tag, shareToCrew: inCrew && share, timezone, isPlannedDay, earlierToday: earlier });
      router.push(`/home${earnedQuery(reply.gamification.newAchievementIds)}`);
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Couldn't post that. Try again.");
      setBusy(false);
    }
  };

  return (
    <div className="stack">
      <h1>Post</h1>
      <label className="field"><span>Photo</span><input type="file" accept="image/*" capture="environment" onChange={(event) => setFile(event.target.files?.[0] ?? null)} /></label>
      <TagPicker tag={tag} onPick={setTag} />
      {yesterday && !repeated ? <button type="button" className="chip" onClick={() => { setCaption(yesterday.caption); if (yesterday.mealTag) setTag(yesterday.mealTag as MealTag); setRepeated(true); }}>↻ Same as yesterday</button> : null}
      <label className="field"><span>{"Say something (or don't)"}</span><textarea value={caption} maxLength={SpecConstants.captionMaxChars} onChange={(event) => setCaption(event.target.value)} rows={SpecConstants.mobilityHoldsMin} /></label>
      <label className="row"><input type="checkbox" checked={earlier} onChange={(event) => setEarlier(event.target.checked)} /> Earlier today</label>
      {inCrew ? <label className="row"><input type="checkbox" checked={share} onChange={(event) => setShare(event.target.checked)} /> Share to crew</label> : null}
      {error ? <p className="danger" role="alert">{error}</p> : null}
      <button type="button" className="button button--primary" disabled={!canSubmit || busy} onClick={submit}>{busy ? "Posting…" : "Post"}</button>
    </div>
  );
}
