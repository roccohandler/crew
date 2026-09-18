// SPEC: A6 — one day of the Journal: the readable day header (<time> carries the ISO date for assistive tech; "Rest day" when
// the day was not a training day and holds no workout), then one card per post — the summary line, the caption, and the
// two-tap delete (E3). A22 G2: no photo on a post. Server component; the words come from rows.ts.
import { DeletePostButton } from "@/components/DeletePostButton";
import { isRestDay, postLine } from "@/app/(app)/journal/rows";
import type { PostDoc } from "@/lib/documents-social";
import { dayLabel } from "@/lib/engine/day-label";

type Props = { dayKey: string; todayKey: string; dayPosts: PostDoc[]; trainingWeekdays: number[]; sessionLines: Map<string, string> };

export function JournalDay({ dayKey, todayKey, dayPosts, trainingWeekdays, sessionLines }: Props) {
  const label = dayLabel(dayKey, todayKey);
  return (
    <section className="stack stack--tight" aria-label={label}>
      <h3 className="row row--between">
        <time dateTime={dayKey}>{label}</time>
        {isRestDay(dayKey, dayPosts, trainingWeekdays) ? <span className="whisper">Rest day</span> : null}
      </h3>
      {dayPosts.map((post) => (
        <article key={post._id.toHexString()} className="card stack stack--tight">
          <p>{postLine(post, sessionLines.get(post.sessionId?.toHexString() ?? "") ?? null)}</p>
          {post.caption ? <p className="muted">{post.caption}</p> : null}
          <DeletePostButton id={post._id.toHexString()} />
        </article>
      ))}
    </section>
  );
}
