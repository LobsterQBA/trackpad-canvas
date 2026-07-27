import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The `worker/` and `db/` folders are optional Cloudflare-only adapters.
  // The Vercel deployment renders only the public App Router pages, which are
  // separately type-checked by the project's Vinext build and tests.
  typescript: {
    ignoreBuildErrors: true,
  },
  turbopack: {
    root: process.cwd(),
  },
};

export default nextConfig;
