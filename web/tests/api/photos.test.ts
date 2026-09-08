// SPEC: T027 (Verify: posts suite incl. the EXIF fixture test) · 8.2 Posts: EXIF stripped (a GPS-tagged fixture asserts a
// clean stored object) · 8.7 (blob URLs auth-checked) · 8.8 (image pipeline ≤ ~300 KB).
import sharp from "sharp";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as readPhoto } from "@/app/api/v1/photos/[key]/route";
import { POST as uploadPhoto } from "@/app/api/v1/photos/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson } from "./http";

let me: TestUser;

// A JPEG with EXIF (make + GPS) — what a phone camera produces
async function gpsTaggedJpeg(width: number, height: number): Promise<Buffer> {
  return sharp({ create: { width, height, channels: 3, background: { r: 255, g: 102, b: 0 } } })
    .jpeg({ quality: 95 })
    .withExif({ IFD0: { Make: "Crew Test Camera", Software: "fixture" }, IFD3: { GPSLatitudeRef: "N", GPSLatitude: "37/1 46/1 30/1", GPSLongitudeRef: "W", GPSLongitude: "122/1 25/1 0/1" } })
    .toBuffer();
}

function multipart(bytes: Buffer, purpose: string, token: string, type = "image/jpeg"): Request {
  const form = new FormData();
  form.set("file", new Blob([new Uint8Array(bytes)], { type }), "plate.jpg");
  form.set("purpose", purpose);
  return new Request("http://localhost:3000/api/v1/photos", { method: "POST", headers: { authorization: `Bearer ${token}`, "x-crew-client": "ios" }, body: form });
}

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("photos");
});
afterAll(async () => {
  await closeDb();
});

describe("photos", () => {
  it("strips EXIF/GPS, resizes, keeps the upload under the budget, and serves it back only to the owner", async () => {
    const source = await gpsTaggedJpeg(3000, 2000);
    expect((await sharp(source).metadata()).exif).toBeDefined(); // the fixture really carries EXIF
    const response = await uploadPhoto(multipart(source, "post", me.accessToken));
    expect(response.status).toBe(201);
    const reply = await readJson<{ photoKey: string; width: number; height: number; bytes: number }>(response);
    expect(reply.width).toBe(SpecConstants.photoMaxEdgePx);
    expect(reply.bytes).toBeLessThanOrEqual(SpecConstants.imageUploadMaxKb * 1000);
    const served = await readPhoto(new Request(`http://localhost:3000/api/v1/photos/${reply.photoKey}`, { headers: { authorization: `Bearer ${me.accessToken}` } }), { params: Promise.resolve({ key: reply.photoKey }) });
    expect(served.status).toBe(200);
    const stored = Buffer.from(await served.arrayBuffer());
    const metadata = await sharp(stored).metadata();
    expect(metadata.exif).toBeUndefined();
    expect(metadata.width).toBe(SpecConstants.photoMaxEdgePx);
    const stranger = await createUser("stranger");
    const denied = await readPhoto(new Request(`http://localhost:3000/api/v1/photos/${reply.photoKey}`, { headers: { authorization: `Bearer ${stranger.accessToken}` } }), { params: Promise.resolve({ key: reply.photoKey }) });
    expect(denied.status).toBe(404);
  });

  it("rejects a non-image and a missing purpose", async () => {
    expect((await uploadPhoto(multipart(Buffer.from("not an image"), "post", me.accessToken, "text/plain"))).status).toBe(400);
    expect((await uploadPhoto(multipart(await gpsTaggedJpeg(64, 64), "poster", me.accessToken))).status).toBe(400);
  });
});
