// Vitest globalSetup: one in-memory MongoDB for the whole run (dev-only substitute for Atlas — continuous-build
// rule 3b, ratification R-005). The URI reaches every test worker through `provide` → tests/setup/env.ts.
// SPEC: C4 (API routes test against a real MongoDB, no mocks) · 8.2
import { MongoMemoryServer } from "mongodb-memory-server";
import type { TestProject } from "vitest/node";

declare module "vitest" {
  export interface ProvidedContext {
    mongoUri: string;
  }
}

export default async function setup(project: TestProject) {
  const server = await MongoMemoryServer.create();
  project.provide("mongoUri", server.getUri());
  return async () => {
    await server.stop();
  };
}
