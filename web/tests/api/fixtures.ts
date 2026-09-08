// Shared test fixtures: real accounts through the real register handler (C4). Every suite that needs a signed-in
// user calls createUser(); nothing is mocked.
import { SignJWT } from "jose";
import { POST as register } from "@/app/api/v1/auth/register/route";
import { readJson, request } from "./http";

export interface TestUser {
  id: string;
  email: string;
  accessToken: string;
  refreshToken: string;
}

let counter = 0;

export async function createUser(label = "user", timezone = "America/Los_Angeles"): Promise<TestUser> {
  counter += 1;
  const email = `${label}-${counter}-${Date.now()}@example.com`;
  // each fixture account arrives from its own IP so the G11 auth limiter (10/min/IP) never trips inside a suite
  const response = await register(request("POST", "/auth/register", { ip: `198.51.100.${counter % 250}`, body: { email, password: "test password 123", displayName: label, timezone, eulaAccepted: true, birthYear: 1990 } }));
  if (response.status !== 201) throw new Error(`fixture register failed: ${response.status} ${await response.text()}`);
  const body = await readJson<{ user: { id: string }; accessToken: string; refreshToken: string }>(response);
  return { id: body.user.id, email, accessToken: body.accessToken, refreshToken: body.refreshToken };
}

// An access token that expired a minute ago, signed with the real secret — the ② standing check
export async function expiredAccessToken(userId: string): Promise<string> {
  const secret = new TextEncoder().encode(process.env.JWT_SECRET ?? "");
  const nowSeconds = Math.floor(Date.now() / 1000);
  return new SignJWT({}).setProtectedHeader({ alg: "HS256" }).setSubject(userId).setIssuedAt(nowSeconds - 3600).setExpirationTime(nowSeconds - 60).sign(secret);
}
