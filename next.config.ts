import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The public site is mounted inside Leo's portfolio. `basePath` keeps every
  // Next.js script, stylesheet and route scoped below the project URL.
  basePath: "/projects/trackpad-canvas",
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
