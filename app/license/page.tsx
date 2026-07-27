import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "License",
  description: "Trackpad Architect open-source licensing.",
};

export default function LicensePage() {
  return (
    <>
      <header className="site-header">
        <a className="brand" href="/">
          <span className="brand-mark" aria-hidden="true" />
          <span>Trackpad Architect</span>
        </a>
        <span />
        <a className="button button-small" href="/">Back home</a>
      </header>
      <main className="legal section">
        <article>
          <p className="eyebrow">Open source</p>
          <h1>License</h1>
          <p>
            Trackpad Architect is released under the MIT License. The repository
            includes the complete license and third-party notices.
          </p>
          <h2>Trackpad Studio attribution</h2>
          <p>
            The low-level multitouch work adapts concepts and code from Trackpad
            Studio by Zayn Jarvis, also licensed under MIT.
          </p>
          <pre>{`MIT License

Copyright (c) 2026 Trackpad Architect contributors

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files, to deal
in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software.`}</pre>
          <p>
            Read the complete terms and third-party notice in the{" "}
            <a className="text-link" href="https://github.com/LobsterQBA/trackpad-architect">
              public repository
            </a>.
          </p>
        </article>
      </main>
    </>
  );
}
