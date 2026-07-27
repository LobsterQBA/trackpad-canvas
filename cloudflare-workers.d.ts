// The public marketing site does not use D1 at runtime. This lightweight
// declaration keeps the optional Cloudflare-only database helper type-safe
// when the same app is built by Vercel's Next.js builder.
declare module "cloudflare:workers" {
  export const env: {
    DB?: any;
  };
}
