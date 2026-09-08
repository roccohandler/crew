// SPEC: G11 rate limits (auth 10 req/min/IP · post creation 60/hour/user · everything else unlimited in MVP) · 8.7.
// A fixed window counted in MongoDB so every Vercel instance shares the same count; documents expire by TTL index.
import { apiError } from "@/lib/api-error";
import { getDb } from "@/lib/db";
import { HttpStatus } from "@/lib/http-status";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

interface RateLimitDoc {
  key: string;
  windowStart: Date;
  count: number;
  expiresAt: Date;
}

let ttlIndexReady: Promise<unknown> | null = null;

async function rateLimits() {
  const collection = (await getDb()).collection<RateLimitDoc>("rateLimits");
  if (ttlIndexReady === null) {
    ttlIndexReady = Promise.all([
      collection.createIndex({ key: 1, windowStart: 1 }, { unique: true }),
      collection.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
    ]);
  }
  await ttlIndexReady;
  return collection;
}

async function consume(key: string, limit: number, windowMs: number, now: Date): Promise<void> {
  const windowStart = new Date(Math.floor(now.getTime() / windowMs) * windowMs);
  const collection = await rateLimits();
  const updated = await collection.findOneAndUpdate(
    { key, windowStart },
    { $inc: { count: 1 }, $setOnInsert: { expiresAt: new Date(windowStart.getTime() + windowMs + windowMs) } },
    { upsert: true, returnDocument: "after" },
  );
  if (updated !== null && updated.count > limit) throw apiError("rateLimited", "Too many attempts. Wait a minute and try again.", HttpStatus.tooManyRequests);
}

export function clientIp(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for") ?? "";
  return forwarded.split(",")[0]?.trim() || req.headers.get("x-real-ip") || "local";
}

export async function limitAuthByIp(req: Request, now: Date = new Date()): Promise<void> {
  await consume(`auth:${clientIp(req)}`, SpecConstants.rateLimitAuthRequestsPerMinutePerIp, TimeUnits.msPerMinute, now);
}

export async function limitPostCreation(userId: string, now: Date = new Date()): Promise<void> {
  await consume(`posts:${userId}`, SpecConstants.rateLimitPostCreationPerHourPerUser, TimeUnits.msPerHour, now);
}
