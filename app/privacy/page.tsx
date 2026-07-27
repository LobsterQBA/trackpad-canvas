import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy",
  description: "Trackpad Architect privacy policy.",
};

export default function PrivacyPage() {
  return (
    <>
      <header className="site-header">
        <a className="brand" href="/">
          <span className="brand-mark" aria-hidden="true">TA</span>
          <span>Trackpad Architect</span>
        </a>
        <span />
        <a className="button button-small" href="/">Back home</a>
      </header>
      <main className="legal section">
        <article>
          <p className="eyebrow">Plain-language policy</p>
          <h1>Privacy</h1>
          <p>Trackpad Architect is designed as a local-first macOS application.</p>
          <h2>What the app collects</h2>
          <p>
            Nothing. The beta has no account system, analytics SDK, advertising,
            telemetry, cloud sync, or remote AI service. Trackpad touch data is
            processed in memory and is not transmitted.
          </p>
          <h2>Your documents</h2>
          <p>
            Documents are saved as local <code>.tpa</code> files at locations
            you choose. Recovery data remains in your Mac&apos;s Application
            Support folder.
          </p>
          <h2>This website</h2>
          <p>
            The product website serves static content and download links. It
            does not set product analytics cookies or build an advertising profile.
          </p>
          <h2>Updates</h2>
          <p>
            Material privacy changes will be documented in the public GitHub
            repository before they ship.
          </p>
        </article>
      </main>
    </>
  );
}

