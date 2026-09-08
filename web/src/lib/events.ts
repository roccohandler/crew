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

// A client's batch (POST events): `at` is the client's own timestamp — a funnel step that happened before the account
// existed keeps its moment — and `receivedAt` is the server clock (E15). Returns how many were stored.
export async function logClientEvents(userId: string, source: "ios" | "web", batch: { name: string; at: string; props?: EventProps }[]): Promise<number> {
  const receivedAt = new Date();
  const docs = batch.map((event) => ({
    _id: new ObjectId(),
    userId: new ObjectId(userId),
    name: event.name,
    at: new Date(event.at),
    receivedAt,
    props: event.props ?? {},
    source,
  }));
  const result = await (await events()).insertMany(docs);
  return result.insertedCount;
}
