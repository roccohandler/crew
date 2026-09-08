// SPEC: Flow 3 "pre-fill from reality" / S08 (last-time values per exercise) — the most recent completed session's actual
// performance per exercise id, as one gray line ("last: 8 · 8 · 7 @ 135"). Server-side helper for the web session page.
import type { ObjectId } from "mongodb";
import { sessions } from "@/lib/db";

export async function lastTimeLines(userId: ObjectId, exerciseIds: string[], excludeSessionId: ObjectId, units: string): Promise<Record<string, string>> {
  const lines: Record<string, string> = {};
  const completed = await (await sessions()).find({ userId, status: "completed", _id: { $ne: excludeSessionId } }).sort({ completedAt: -1 }).limit(SAMPLE).toArray();
  for (const exerciseId of exerciseIds) {
    for (const session of completed) {
      const row = session.exercises.find((exercise) => exercise.exerciseId === exerciseId);
      const done = row?.sets.filter((set) => set.done && !set.isWarmup) ?? [];
      if (done.length === 0) continue;
      const reps = done.map((set) => String(set.actualReps)).join(" · ");
      const weights = done.map((set) => set.weight).filter((weight): weight is number => weight !== null);
      lines[exerciseId] = weights.length > 0 ? `last: ${reps} @ ${Math.max(...weights)} ${units}` : `last: ${reps}`;
      break;
    }
  }
  return lines;
}

const SAMPLE = 30;
