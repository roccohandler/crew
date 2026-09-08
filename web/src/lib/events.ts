// SPEC: Part IV (analytics = first-party events to our DB) · 5.6.4 (every mutation ends with logEvent) · 1D (funnel
// steps) · E10 metrics. One insert, never awaited by the user path for longer than the insert itself.
import { ObjectId } from "mongodb";
import { events } from "@/lib/db";

type EventProps = Record<string, string | number | boolean | null>;

export async function logEvent(userId: string | null, name: string, props: EventProps = {}, source: "server" | "ios" | "web" = "server"): Promise<void> {
  await (await events()).insertOne({
    _id: new ObjectId(),
    userId: userId === null ? null : new ObjectId(userId),
    name,
    at: new Date(),
    props,
    source,
  });
}
