// SPEC: 8.2 standing checks auto-generated for EVERY route: ① cross-user access → 403/404 ② expired JWT → 401 + refresh
// works ③ malformed body → 400 with the standard error shape ④ idempotent retries where a client UUID exists · T015
// (Verify: npm test — fails on any uncovered route forever after). Real handlers, real MongoDB.
import { readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as refresh } from "@/app/api/v1/auth/refresh/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { createUser, expiredAccessToken, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { STANDING_REGISTRY } from "./standing-registry";

const API_DIR = join(process.cwd(), "src", "app", "api", "v1");
const CRON_DIR = join(process.cwd(), "src", "app", "api", "cron");
const METHODS = ["GET", "POST", "PUT", "PATCH", "DELETE"] as const;
type Handler = (req: Request, context: { params: Promise<Record<string, string>> }) => Promise<Response>;

// Next passes dynamic segments as `context.params`; rebuild them from the route pattern and the concrete path
function contextFor(routePath: string, concretePath: string) {
  const patternParts = routePath.split("/");
  const pathParts = concretePath.replace(/^\//, "").split("/");
  const params: Record<string, string> = {};
  patternParts.forEach((part, index) => {
    const match = /^\[(.+)\]$/.exec(part);
    if (match?.[1] && pathParts[index]) params[match[1]] = pathParts[index];
  });
  return { params: Promise.resolve(params) };
}

function call(handler: Handler, routePath: string, req: Request) {
  return handler(req, contextFor(routePath, new URL(req.url).pathname.replace(/^\/api\/v1/, "")));
}

function routeFiles(dir: string, out: string[] = []): string[] {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) routeFiles(full, out);
    else if (entry === "route.ts") out.push(full);
  }
  return out;
}

const routes = [...routeFiles(API_DIR), ...routeFiles(CRON_DIR)].map((file) => ({ file, path: relative(API_DIR, file).replaceAll("\\", "/").replace(/\/route\.ts$/, "") }));
let me: TestUser;
let other: TestUser;

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("me");
  other = await createUser("other");
});
afterAll(async () => {
  await closeDb();
});

function concretePath(path: string, entry: { foreignPath?: unknown }): string {
  return entry.foreignPath === undefined ? `/${path}` : `/${path.replace(/\[[^\]]+\]/g, "000000000000000000000000")}`;
}

describe("standing checks — every route under app/api/v1", () => {
  it("discovers at least the auth routes", () => {
    expect(routes.length).toBeGreaterThan(0);
  });

  for (const route of routes) {
    describe(route.path, async () => {
      const mod = (await import(route.file)) as Record<string, Handler>;
      for (const method of METHODS.filter((name) => typeof mod[name] === "function")) {
        const key = `${route.path}:${method}`;
        const handler = mod[method] as Handler;
        const entry = STANDING_REGISTRY[key];
        it(`${method} is declared in the standing registry`, () => {
          expect(entry, `${key} is not in tests/api/standing-registry.ts`).toBeDefined();
        });
        if (!entry) continue;

        if (!entry.public) {
          it(`${method} ② expired access token → 401, then refresh recovers`, async () => {
            const token = await expiredAccessToken(me.id);
            const response = await call(handler, route.path, request(method, concretePath(route.path, entry), { token, body: entry.jsonBody ? {} : undefined }));
            expect(response.status).toBe(401);
            expect((await readJson(response)).error).toMatchObject({ code: "unauthorized" });
            const recovered = await refresh(request("POST", "/auth/refresh", { body: { refreshToken: me.refreshToken } }));
            expect(recovered.status).toBe(200);
            me.refreshToken = (await readJson<{ refreshToken: string }>(recovered)).refreshToken;
          });
        }

        if (entry.jsonBody) {
          it(`${method} ③ malformed body → 400 in the standard error shape`, async () => {
            const path = entry.foreignPath ? await entry.foreignPath(me, other) : concretePath(route.path, entry);
            const broken = await call(handler, route.path, request(method, path, { token: me.accessToken, rawBody: "{not json" }));
            expect(broken.status).toBe(400);
            const body = await readJson<{ error: { code: string; message: string } }>(broken);
            expect(body.error.code).toBe("validation");
            expect(typeof body.error.message).toBe("string");
          });
        }

        if (entry.foreignPath) {
          it(`${method} ① another user's resource → 403 or 404`, async () => {
            const path = await entry.foreignPath!(me, other);
            const response = await call(handler, route.path, request(method, path, { token: me.accessToken, body: entry.jsonBody ? await entry.validBody?.(me) : undefined }));
            expect([403, 404]).toContain(response.status);
          });
        }

        if (entry.validBody && entry.idField) {
          it(`${method} ④ the same clientId twice → the same document`, async () => {
            const body = await entry.validBody!(me);
            const first = await readJson<Record<string, { id: string }>>(await call(handler, route.path, request(method, concretePath(route.path, entry), { token: me.accessToken, body })));
            const second = await readJson<Record<string, { id: string }>>(await call(handler, route.path, request(method, concretePath(route.path, entry), { token: me.accessToken, body })));
            expect(second[entry.idField!]?.id).toBe(first[entry.idField!]?.id);
          });
        }
      }
    });
  }
});
