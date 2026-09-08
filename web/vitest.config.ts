import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

// SPEC: 8.1 (vectors), 8.2 (API integration against a real test MongoDB — C4, no mocks), 8.3 (unit areas)
export default defineConfig({
  resolve: { alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) } },
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
    passWithNoTests: true,
    testTimeout: 30_000,
    hookTimeout: 180_000,
    globalSetup: ["tests/setup/mongo-global.ts"],
    setupFiles: ["tests/setup/env.ts"],
    fileParallelism: false,
  },
});
