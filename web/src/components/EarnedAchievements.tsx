// SPEC: E8 (achievement unlocks fold into the completion celebration) · Part III law ④ (ember = reward) · seed copy in
// gym-buddy voice. Server component: the ids ride the URL (?earned=a,b) from the mutation reply; unknown ids render nothing.
import { achievements } from "@/generated/seed";

export function earnedIds(raw: string | undefined): string[] {
  return (raw ?? "").split(",").filter((id) => achievements.some((achievement) => achievement.id === id));
}

export function EarnedAchievements({ ids }: { ids: string[] }) {
  if (ids.length === 0) return null;
  return (
    <section className="stack stack--tight" aria-label="Unlocked">
      {ids.map((id) => {
        const achievement = achievements.find((candidate) => candidate.id === id);
        return achievement ? <p key={id} className="ember-text"><strong>{achievement.title}</strong> — {achievement.line}</p> : null;
      })}
    </section>
  );
}
