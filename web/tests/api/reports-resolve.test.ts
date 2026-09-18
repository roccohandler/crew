// SPEC: W5 (owner-approved 2026-09-17) · E9 — a report is filed open; a human resolves it from the laptop (scripts/resolve-reports.ts →
// lib/reports.ts): the named open reports flip to resolved with a resolvedAt, exactly those are returned, a second pass changes nothing,
// and an unknown or malformed id is ignored. No route ever sets `resolved`.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { ObjectId } from "mongodb";
import { POST as fileReport } from "@/app/api/v1/reports/route";
import { closeDb, reports, resetDbForTests } from "@/lib/db";
import { openReports, resolveReports } from "@/lib/reports";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { postWorkout } from "./workout-post";

let reporter: TestUser;
let poster: TestUser;

beforeAll(async () => {
  await resetDbForTests();
  reporter = await createUser("reporter");
  poster = await createUser("poster");
});
afterAll(async () => {
  await closeDb();
});

async function fileOne(reason: string): Promise<string> {
  const post = { post: { id: (await postWorkout(poster, { cardio: true, caption: "a line" })).postId } }; // A22: a post is a workout post
  const filed = await fileReport(request("POST", "/reports", { token: reporter.accessToken, body: { targetType: "post", targetId: post.post.id, reason } }));
  expect(filed.status).toBe(201);
  return (await readJson<{ reportId: string }>(filed)).reportId;
}

describe("report resolution (W5)", () => {
  it("lists open reports oldest first, resolves exactly the named ones once, and ignores unknown ids", async () => {
    const first = await fileOne("first");
    const second = await fileOne("second");
    const open = await openReports();
    expect(open.map((report) => report._id.toHexString())).toEqual([first, second]);
    expect(open.every((report) => report.status === "open" && report.resolvedAt === undefined)).toBe(true);

    const when = new Date("2026-09-18T10:00:00Z");
    const resolved = await resolveReports([first, "not-an-id", new ObjectId().toHexString()], when);
    expect(resolved.map((report) => report._id.toHexString())).toEqual([first]);
    expect(resolved[0]?.status).toBe("resolved");
    expect(resolved[0]?.resolvedAt).toEqual(when);
    const stored = await (await reports()).findOne({ _id: new ObjectId(first) });
    expect(stored?.status).toBe("resolved");
    expect(stored?.resolvedAt).toEqual(when);
    expect((await openReports()).map((report) => report._id.toHexString())).toEqual([second]);

    expect(await resolveReports([first])).toEqual([]); // already resolved: nothing changes, nothing returned
    expect((await (await reports()).findOne({ _id: new ObjectId(first) }))?.resolvedAt).toEqual(when);
  });
});
