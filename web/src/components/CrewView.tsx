"use client";
// SPEC: Flow 6 — CREW PULSE + member strip + ONE unified stream + chat composer; reactions on posts; Part IV polling (5 s while
// the tab is open); E20 un-react by tapping again. A5: solo = three lines then one CTA; a crew of one = the open invite card
// and no composer until two members; E9: report / block from a card, then one confirming line. Web twin of ios CrewModel +
// CrewScreen.
import { useCallback, useEffect, useState } from "react";
import { CrewHeader, Composer } from "@/components/CrewHeader";
import { CrewInvitePanel } from "@/components/CrewInvitePanel";
import { EmptyState, ErrorState } from "@/components/EmptyState";
import { StreamList, type Moderation } from "@/components/StreamList";
import { isApiClientError } from "@/lib/api-client";
import { block, createCrew, myCrew, react, report, sendMessage, stream, unreact, type CrewSummary, type StreamReply } from "@/lib/api-client-crew";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

type Loaded = { crew: CrewSummary | null; feed: StreamReply | null };

// SPEC: A5 · Flow 10 — the solo tab explains the loop in three lines, then one warm invitation (never a waiting room)
function SoloState({ onStart }: { onStart: () => void }) {
  return (
    <EmptyState title="Start a crew" line="Two to ten friends. A link, a name, an emoji." ctaTitle="Start a crew" onClick={onStart}>
      <ul className="loop">
        <li>Post a workout or a meal photo.</li>
        <li>It lands here for your crew.</li>
        <li>They react 🔥💪👏😂❤️ and chat.</li>
      </ul>
    </EmptyState>
  );
}

// SPEC: E9 — report a post, then "Reported. A human will look."; block a user, then "Blocked. You won't see each other." and
// the stream reloads without them (both silent toward the other person)
function moderationFor(reload: () => Promise<void>, notify: (line: string) => void): Moderation {
  return {
    onReport: async (postId) => { await report("post", postId, "Reported from the crew stream"); notify("Reported. A human will look."); },
    onBlock: async (userId) => { await block(userId); notify("Blocked. You won't see each other."); await reload(); },
  };
}

// SPEC: E20 — tapping the emoji you already gave takes it back; any other emoji replaces it
async function toggleReactionFor(feed: StreamReply | null, myUserId: string, postId: string, emoji: string): Promise<void> {
  const mine = feed?.items.find((item) => item.post?.id === postId)?.reactions?.find((reaction) => reaction.userId === myUserId);
  if (mine?.emoji === emoji) await unreact(postId); else await react(postId, emoji);
}

export function CrewView({ myUserId }: { myUserId: string }) {
  const [state, setState] = useState<Loaded | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      const mine = await myCrew();
      setState({ crew: mine.crew, feed: mine.crew ? await stream(mine.crew.id) : null });
      setError(null);
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Couldn't reach your crew. Try again.");
    }
  }, []);

  useEffect(() => {
    // subscribe to the server: first poll on the next tick, then every 5 s (Part IV polling)
    const first = window.setTimeout(() => void load(), 0);
    const timer = window.setInterval(() => void load(), SpecConstants.chatPollIntervalMinSeconds * TimeUnits.msPerSecond);
    return () => { window.clearTimeout(first); window.clearInterval(timer); };
  }, [load]);

  const toggleReaction = async (postId: string, emoji: string) => { await toggleReactionFor(state?.feed ?? null, myUserId, postId, emoji); await load(); };

  if (error && !state) return <ErrorState line={error} onRetry={load} />;
  if (state === null) return <div className="stack"><div className="skeleton" /><div className="skeleton" /></div>;
  if (state.crew === null && !creating) return <SoloState onStart={() => setCreating(true)} />;
  if (state.crew === null) return <CrewInvitePanel crew={null} members={[]} onCreate={async (name, emoji) => { await createCrew(name, emoji); setCreating(false); await load(); }} onChanged={load} />;
  const members = state.feed?.members ?? [];
  const hasCrewmates = members.length >= SpecConstants.crewMinMembers; // SPEC: A5 — no composer, no "Quiet in here" until two members
  return (
    <div className="stack">
      <CrewHeader crew={state.crew} feed={state.feed} />
      <CrewInvitePanel crew={state.crew} members={members} onCreate={async () => undefined} onChanged={load} />
      {notice ? <p className="muted" role="status">{notice}</p> : null}
      {hasCrewmates && state.feed && state.feed.items.length === 0 ? <p className="muted">Quiet in here. Post a workout or a plate and it lands right here.</p> : null}
      {state.feed ? <StreamList items={state.feed.items} members={members} myUserId={myUserId} onReact={toggleReaction} moderation={moderationFor(load, setNotice)} /> : null}
      {hasCrewmates ? <Composer onSend={async (body) => { await sendMessage(state.crew!.id, crypto.randomUUID(), body); await load(); }} /> : null}
    </div>
  );
}
