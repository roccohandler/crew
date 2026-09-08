// Vitest setupFile (runs in every worker before the test file): points lib/db.ts at the in-memory MongoDB and
// gives every test file its own database name so files never share state.
import { inject } from "vitest";

const file = (globalThis as { __vitest_worker__?: { filepath?: string } }).__vitest_worker__?.filepath ?? "unknown";
process.env.MONGODB_URI = inject("mongoUri");
process.env.MONGODB_DB = `crew_test_${file.replace(/[^a-z0-9]/gi, "_").slice(-40)}`;
process.env.JWT_SECRET = "test-secret-that-is-at-least-32-bytes-long!!";
process.env.APP_BASE_URL = "http://localhost:3000";
