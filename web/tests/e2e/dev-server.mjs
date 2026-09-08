// Playwright webServer: an in-memory MongoDB (rule 3b substitute) + `next dev` with a complete local environment.
// SPEC: 8.4 (web journeys against a seeded backend in CI) · T039
import { spawn } from "node:child_process";
import { MongoMemoryServer } from "mongodb-memory-server";

const mongo = await MongoMemoryServer.create();
// `next dev` reads web/.env and only skips keys that are ALREADY set in its environment. A developer's .env holds real
// vendor keys (Atlas, Resend, Blob, APNs), so every vendor variable is pinned to "" here: an empty value keeps each lib on
// its dev/test substitute (outbox, .blob-dev, no APNs client) and the harness can never mail, upload or push for real.
// SPEC: continuous-build rule 3b (local substitutes) · 8.7 (the test tree never touches production services)
const env = {
  ...process.env,
  MONGODB_URI: mongo.getUri(),
  MONGODB_DB: "crew_e2e",
  JWT_SECRET: "e2e-secret-that-is-at-least-32-bytes-long!!",
  APP_BASE_URL: "http://localhost:3000",
  COOKIE_SECURE: "false",
  APPLE_BUNDLE_ID: "com.e2e.crew",
  APPLE_SERVICES_ID: "com.e2e.crew.web",
  CRON_SECRET: "e2e-cron",
  RESEND_API_KEY: "",
  RESEND_FROM: "",
  MODERATION_INBOX: "",
  BLOB_READ_WRITE_TOKEN: "",
  APNS_TEAM_ID: "",
  APNS_KEY_ID: "",
  APNS_PRIVATE_KEY: "",
  APNS_BUNDLE_ID: "",
  APNS_ENVIRONMENT: "",
};
const next = spawn(process.platform === "win32" ? "npx.cmd" : "npx", ["next", "dev", "-p", "3000"], { env, stdio: "inherit", shell: process.platform === "win32" });
const stop = async () => {
  next.kill();
  await mongo.stop();
  process.exit(0);
};
process.on("SIGINT", stop);
process.on("SIGTERM", stop);
next.on("exit", () => void mongo.stop().then(() => process.exit(0)));
