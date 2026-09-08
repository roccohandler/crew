// SPEC: Part IV (APNs direct, HTTP/2 token auth via apns2) · 5.2 lib/push.ts · Flow 2 ("Push day is ready 💪") · 6.6 (every
// notification names its subject) · E5 (notifications denied → in-app banners, never re-prompt). Without APNS_* credentials
// every push is written to the `pushOutbox` collection — the dev/test transport (rule 3b). T033
import { ObjectId } from "mongodb";
import { ApnsClient, Notification } from "apns2";
import { getDb, pushTokens } from "@/lib/db";

export interface PushMessage {
  title: string;
  body: string;
  kind: "reminder" | "streakRisk" | "reaction" | "crewActivity";
}

type OutboxDoc = PushMessage & { _id: ObjectId; userId: ObjectId; token: string; sentAt: Date };

export async function pushOutbox() {
  return (await getDb()).collection<OutboxDoc>("pushOutbox");
}

function apnsClient(): ApnsClient | null {
  const { APNS_TEAM_ID, APNS_KEY_ID, APNS_PRIVATE_KEY, APNS_BUNDLE_ID, APNS_ENVIRONMENT } = process.env;
  if (!APNS_TEAM_ID || !APNS_KEY_ID || !APNS_PRIVATE_KEY || !APNS_BUNDLE_ID) return null;
  return new ApnsClient({ team: APNS_TEAM_ID, keyId: APNS_KEY_ID, signingKey: APNS_PRIVATE_KEY.replace(/\\n/g, "\n"), defaultTopic: APNS_BUNDLE_ID, host: APNS_ENVIRONMENT === "production" ? "api.push.apple.com" : "api.sandbox.push.apple.com" });
}

export async function sendPush(userId: ObjectId, message: PushMessage, now: Date = new Date()): Promise<number> {
  const tokens = await (await pushTokens()).find({ userId }).toArray();
  if (tokens.length === 0) return 0;
  const client = apnsClient();
  if (client === null) {
    await (await pushOutbox()).insertMany(tokens.map((doc) => ({ _id: new ObjectId(), userId, token: doc.token, ...message, sentAt: now })));
    return tokens.length;
  }
  const notifications = tokens.map((doc) => new Notification(doc.token, { alert: { title: message.title, body: message.body }, data: { kind: message.kind } }));
  await client.sendMany(notifications);
  return tokens.length;
}
