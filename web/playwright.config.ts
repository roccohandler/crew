import { defineConfig, devices } from "@playwright/test";

// SPEC: 8.4 (web journeys ①–④ against a seeded backend), 8.9 (viewport matrix 375 / 768 / 1280)
export default defineConfig({
  testDir: "tests/e2e",
  fullyParallel: false,
  workers: 3, // one per viewport: the default (half the cores — eight here) opened the same cold pages eight at a time
  retries: 0,
  timeout: 60_000, // next dev compiles each page on first hit; warm-up.ts pays for it before the first journey
  globalSetup: "./tests/e2e/warm-up.ts",
  expect: { timeout: 10_000 }, // a first-hit route under three workers can still take longer than the 5 s default

  reporter: [["list"]],
  use: { baseURL: "http://localhost:3000", trace: "retain-on-failure" },
  projects: [
    { name: "phone-375", use: { ...devices["iPhone 13"], viewport: { width: 375, height: 812 } } },
    { name: "tablet-768", use: { ...devices["Desktop Chrome"], viewport: { width: 768, height: 1024 } } },
    { name: "desktop-1280", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 800 } } },
  ],
  webServer: {
    command: "node tests/e2e/dev-server.mjs",
    url: "http://localhost:3000/login",
    reuseExistingServer: true,
    timeout: 180_000,
  },
});
