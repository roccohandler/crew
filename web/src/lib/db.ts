// SPEC: Part IV (MongoDB Atlas) · Part IX (collections + invariants as unique indexes: one plan per user, one crew
// per user, reaction uniqueness) · C3 (well-known singleton, plain functions) · T009.
// One client per process; every collection has a typed getter; the indexes are ensured once per process.
import { MongoClient, type Db } from "mongodb";
import type { PlanDoc, SessionDoc, UserDoc } from "@/lib/documents";
import type { EventDoc, PasswordResetDoc, PhotoDoc, PushTokenDoc, RefreshTokenDoc } from "@/lib/documents-auth";
import type { BlockDoc, CrewDoc, CrewMembershipDoc, GamificationStateDoc, MessageDoc, PauseDoc, PostDoc, ReactionDoc, ReportDoc } from "@/lib/documents-social";

let client: MongoClient | null = null;
let indexesReady: Promise<void> | null = null;

export async function getDb(): Promise<Db> {
  if (client === null) {
    client = new MongoClient(process.env.MONGODB_URI ?? "mongodb://127.0.0.1:27017");
    await client.connect();
  }
  const db = client.db(process.env.MONGODB_DB ?? "crew");
  if (indexesReady === null) indexesReady = ensureIndexes(db);
  await indexesReady;
  return db;
}

export async function closeDb(): Promise<void> {
  if (client !== null) await client.close();
  client = null;
  indexesReady = null;
}

// Tests only: drop everything and rebuild the indexes (real database, no mocks — C4)
export async function resetDbForTests(): Promise<void> {
  const db = await getDb();
  await db.dropDatabase();
  indexesReady = ensureIndexes(db);
  await indexesReady;
}

export async function users() { return (await getDb()).collection<UserDoc>("users"); }
export async function plans() { return (await getDb()).collection<PlanDoc>("plans"); }
export async function sessions() { return (await getDb()).collection<SessionDoc>("sessions"); }
export async function posts() { return (await getDb()).collection<PostDoc>("posts"); }
export async function crews() { return (await getDb()).collection<CrewDoc>("crews"); }
export async function crewMemberships() { return (await getDb()).collection<CrewMembershipDoc>("crewMemberships"); }
export async function messages() { return (await getDb()).collection<MessageDoc>("messages"); }
export async function reactions() { return (await getDb()).collection<ReactionDoc>("reactions"); }
export async function gamificationStates() { return (await getDb()).collection<GamificationStateDoc>("gamificationStates"); }
export async function pauses() { return (await getDb()).collection<PauseDoc>("pauses"); }
export async function reports() { return (await getDb()).collection<ReportDoc>("reports"); }
export async function blocks() { return (await getDb()).collection<BlockDoc>("blocks"); }
export async function refreshTokens() { return (await getDb()).collection<RefreshTokenDoc>("refreshTokens"); }
export async function passwordResets() { return (await getDb()).collection<PasswordResetDoc>("passwordResets"); }
export async function pushTokens() { return (await getDb()).collection<PushTokenDoc>("pushTokens"); }
export async function events() { return (await getDb()).collection<EventDoc>("events"); }
export async function photos() { return (await getDb()).collection<PhotoDoc>("photos"); }

// SPEC: Part IX invariants — every UNIQUE in the model is a unique index here, nowhere else
async function ensureIndexes(db: Db): Promise<void> {
  await ensureModelIndexes(db);
  await ensureOperationalIndexes(db);
}

async function ensureModelIndexes(db: Db): Promise<void> {
  await db.collection("users").createIndexes([
    { key: { emailLower: 1 }, unique: true },
    { key: { appleSub: 1 }, unique: true, sparse: true },
  ]);
  await db.collection("plans").createIndex({ userId: 1 }, { unique: true });
  await db.collection("sessions").createIndexes([{ key: { clientId: 1 }, unique: true }, { key: { userId: 1, dayKey: 1 } }]);
  await db.collection("posts").createIndexes([
    { key: { clientId: 1 }, unique: true },
    { key: { userId: 1, dayKey: 1 } },
    { key: { crewId: 1, createdAt: -1 } },
  ]);
  await db.collection("crews").createIndex({ inviteToken: 1 }, { unique: true });
  await db.collection("crewMemberships").createIndexes([{ key: { userId: 1 }, unique: true }, { key: { crewId: 1, userId: 1 }, unique: true }]);
  await db.collection("messages").createIndexes([{ key: { clientId: 1 }, unique: true }, { key: { crewId: 1, createdAt: -1 } }]);
  await db.collection("reactions").createIndexes([
    { key: { targetType: 1, targetId: 1, userId: 1 }, unique: true },
    { key: { userId: 1, dayKey: 1 } },
  ]);
  await db.collection("gamificationStates").createIndex({ userId: 1 }, { unique: true });
  await db.collection("pauses").createIndex({ userId: 1, endDay: -1 });
  await db.collection("reports").createIndex({ status: 1, createdAt: -1 });
  await db.collection("blocks").createIndex({ blockerId: 1, blockedId: 1 }, { unique: true });
}

async function ensureOperationalIndexes(db: Db): Promise<void> {
  await db.collection("refreshTokens").createIndexes([{ key: { tokenHash: 1 }, unique: true }, { key: { userId: 1 } }, { key: { familyId: 1 } }]);
  await db.collection("passwordResets").createIndex({ tokenHash: 1 }, { unique: true });
  await db.collection("pushTokens").createIndexes([{ key: { token: 1 }, unique: true }, { key: { userId: 1 } }]);
  await db.collection("events").createIndex({ userId: 1, at: -1 });
  await db.collection("photos").createIndex({ photoKey: 1 }, { unique: true });
}
