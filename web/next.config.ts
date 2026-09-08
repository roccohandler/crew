import type { NextConfig } from "next";

// SPEC: Part IV — one Next.js app on Vercel: /api/v1, the full web app, invite landing pages.
const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  serverExternalPackages: ["sharp", "mongodb"],
};

export default nextConfig;
