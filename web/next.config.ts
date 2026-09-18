import { readFileSync } from "node:fs";
import type { NextConfig } from "next";

// SPEC: Part IV — one Next.js app on Vercel: /api/v1, the full web app, invite landing pages.
// W6 (owner's walkthrough, 2026-09-17): the web's "Version" line reads package.json's version plus the deployed commit (Vercel's
// VERCEL_GIT_COMMIT_SHA when present), so it names the same release the iPhone's About row does instead of "beta".
const { version } = JSON.parse(readFileSync(new URL("./package.json", import.meta.url), "utf8")) as { version: string };
const commit = (process.env.VERCEL_GIT_COMMIT_SHA ?? "").slice(0, 7);

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  serverExternalPackages: ["sharp", "mongodb"],
  env: { NEXT_PUBLIC_APP_VERSION: commit.length > 0 ? `${version} (${commit})` : version },
};

export default nextConfig;
