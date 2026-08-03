import type { Metadata } from "next";
import { Bricolage_Grotesque, Caveat, IBM_Plex_Mono } from "next/font/google";
import "./globals.css";

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
      </body>
    </html>
  );
}
