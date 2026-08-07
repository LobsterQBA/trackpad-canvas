import type { Metadata } from "next";
import { Bricolage_Grotesque, Caveat, IBM_Plex_Mono } from "next/font/google";
import { Analytics, type AnalyticsProps } from "@vercel/analytics/next";
import "./globals.css";

const analyticsOrigin = "https://trackpad-canvas.vercel.app";

function analyticsProps(): AnalyticsProps {
  const configString =
    process.env.NEXT_PUBLIC_VERCEL_OBSERVABILITY_CLIENT_CONFIG ??
    process.env.VERCEL_OBSERVABILITY_CLIENT_CONFIG;
  if (!configString) return {};

  const config = JSON.parse(configString).analytics ?? {};
  return Object.fromEntries(
    ["scriptSrc", "viewEndpoint", "eventEndpoint", "sessionEndpoint"]
      .filter((key) => config[key])
      .map((key) => [key, new URL(config[key], analyticsOrigin).toString()]),
  );
}

const display = Bricolage_Grotesque({
  variable: "--font-display",
  subsets: ["latin"],
});

const handwriting = Caveat({
  variable: "--font-hand",
  subsets: ["latin"],
});

const mono = IBM_Plex_Mono({
  variable: "--font-mono",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://www.leozhao.me/projects/trackpad-canvas"),
  title: {
    default: "Trackpad Canvas — Your trackpad is the canvas.",
    template: "%s · Trackpad Canvas",
  },
  description:
    "A native macOS canvas for turning trackpad gestures into presentation-ready system diagrams.",
  keywords: [
    "trackpad drawing",
    "macOS diagramming",
    "data architecture",
    "system design",
    "PowerPoint diagrams",
  ],
  openGraph: {
    title: "Trackpad Canvas",
    description: "Sketch fast. Refine clean. Present anywhere.",
    type: "website",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "Trackpad Canvas — Your trackpad is the canvas.",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Trackpad Canvas",
    description: "Your trackpad is the canvas.",
    images: ["/og.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${display.variable} ${handwriting.variable} ${mono.variable}`}>
        {children}
        <Analytics {...analyticsProps()} />
      </body>
    </html>
  );
}
