"use client";
// SPEC: Flow 6 — CREW PULSE + member strip + ONE unified stream + chat composer; reactions on posts; Part IV polling (5 s while the
// tab is open); E20 un-react by tapping again. Web twin of ios CrewModel + CrewScreen.
import { useCallback, useEffect, useState } from "react";
import { CrewHeader, Composer } from "@/components/CrewHeader";
import { CrewInvitePanel } from "@/components/CrewInvitePanel";
import { EmptyState, ErrorState } from "@/components/EmptyState";
import { StreamList } from "@/components/StreamList";
import { isApiClientError } from "@/lib/api-client";
import { createCrew, myCrew, react, sendMessage, stream, unreact, type CrewSummary, type StreamReply } from "@/lib/api-client-crew";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

type Loaded = { crew: CrewSummary | null; feed: StreamReply | null };

export function CrewView({ myUserId }: { myUserId: string }) {
  const [state, setState] = useState<Loaded | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);

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

  const toggleReaction = async (postId: string, emoji: string) => {
    const mine = state?.feed?.items.find((item) => item.post?.id === postId)?.reactions?.find((reaction) => reaction.userId === myUserId);
    if (mine?.emoji === emoji) await unreact(postId); else await react(postId, emoji);
    await load();
  };

  if (error && !state) return <ErrorState line={error} onRetry={load} />;
  if (state === null) return <div className="stack"><div className="skeleton" /><div className="skeleton" /></div>;
  if (state.crew === null && !creating) return <EmptyState title="Start a crew" line="Two to ten friends. A link, a name, an emoji — that's the whole setup." ctaTitle="Start a crew" onClick={() => setCreating(true)} />;
  if (state.crew === null) return <CrewInvitePanel crew={null} members={[]} onCreate={async (name, emoji) => { await createCrew(name, emoji); setCreating(false); await load(); }} onChanged={load} />;
  return (
    <div className="stack">
      <CrewHeader crew={state.crew} feed={state.feed} />
      <CrewInvitePanel crew={state.crew} members={state.feed?.members ?? []} onCreate={async () => undefined} onChanged={load} />
      {state.feed && state.feed.items.length === 0 ? <p className="muted">Quiet in here. Post a workout or a plate and it lands right here.</p> : null}
      {state.feed ? <StreamList items={state.feed.items} members={state.feed.members} myUserId={myUserId} onReact={toggleReaction} /> : null}
      <Composer onSend={async (body) => { await sendMessage(state.crew!.id, crypto.randomUUID(), body); await load(); }} />
    </div>
  );
}
