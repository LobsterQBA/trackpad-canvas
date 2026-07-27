import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Your trackpad is the canvas",
  description:
    "Draw breakdowns and data architecture directly from your Mac trackpad, then refine and copy them into PowerPoint.",
};

const repo = "https://github.com/LobsterQBA/trackpad-canvas";
const download =
  "https://github.com/LobsterQBA/trackpad-canvas/releases/latest/download/TrackpadCanvas-0.1.0-beta.1.dmg";

export default function Home() {
  return (
    <main>
      <header className="site-header">
        <a className="brand" href="#top" aria-label="Trackpad Canvas home">
          <span className="brand-mark" aria-hidden="true" />
          <span>Trackpad Canvas</span>
        </a>
        <nav aria-label="Primary navigation">
          <a href="#workflow">How it works</a>
          <a href="#install">Install</a>
          <a href={repo}>GitHub</a>
        </nav>
        <a className="button button-small" href={download}>
          Download beta
        </a>
      </header>

      <section className="hero section" id="top">
        <div className="hero-doodle doodle-one" aria-hidden="true">⌁</div>
        <div className="hero-doodle doodle-two" aria-hidden="true">↗</div>
        <div className="hero-copy">
          <p className="eyebrow">Native macOS · Open source · No account</p>
          <h1>
            Your trackpad is
            <span className="marker">the canvas.</span>
          </h1>
          <p className="hero-subtitle">
            Sketch a breakdown with your fingers. Snap it into a clean system
            diagram. Paste it straight into your next deck.
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href={download}>
              Download for macOS
              <span aria-hidden="true">↓</span>
            </a>
            <a className="button button-ghost" href={repo}>
              View source
            </a>
          </div>
          <p className="release-note">
            v0.1.0-beta.1 · macOS 13+ · Apple silicon &amp; Intel
          </p>
        </div>

        <ProductDemo />
      </section>

      <section className="hello section" aria-labelledby="hello-title">
        <div className="confetti" aria-hidden="true">
          <i /><i /><i /><i /><i /><i />
        </div>
        <p className="hand-note">meet your new thinking surface</p>
        <h2 id="hello-title">
          Say hi to <span className="marker marker-mint">Trackpad Canvas</span>
        </h2>
        <p>
          It starts like a sketchbook and ends like a diagramming tool.
          Everything stays local on your Mac.
        </p>
        <div className="hello-actions">
          <a className="button button-primary" href={download}>Start drawing</a>
          <a className="button button-ghost" href="#workflow">See the workflow</a>
        </div>
      </section>

      <section className="workflow section" id="workflow" aria-labelledby="workflow-title">
        <div className="section-heading">
          <p className="eyebrow">One continuous flow</p>
          <h2 id="workflow-title">From messy thought to meeting-ready.</h2>
          <p>No switching apps. No wrestling with tiny PowerPoint handles.</p>
        </div>

        <div className="workflow-grid">
          <article className="workflow-card create-card">
            <span className="step-number">01</span>
            <div className="mini-canvas loose-canvas" aria-hidden="true">
              <span className="loose-node n1">question</span>
              <span className="loose-node n2">data</span>
              <span className="loose-node n3">teams</span>
              <span className="scribble-arrow a1">↘</span>
              <span className="scribble-arrow a2">↗</span>
            </div>
            <h3>Create</h3>
            <p>Touch with one finger and ink appears immediately. Two fingers navigate.</p>
          </article>

          <article className="workflow-card refine-card">
            <span className="step-number">02</span>
            <div className="mini-canvas refine-canvas" aria-hidden="true">
              <span className="align-line" />
              <span className="clean-node c1">Source</span>
              <span className="clean-node c2">Model</span>
              <span className="clean-node c3">Serve</span>
              <span className="clean-link l1" />
              <span className="clean-link l2" />
            </div>
            <h3>Refine</h3>
            <p>Bind connectors, snap to an 8 pt grid, lock layers, or auto-layout a selection.</p>
          </article>

          <article className="workflow-card present-card">
            <span className="step-number">03</span>
            <div className="mini-canvas deck-canvas" aria-hidden="true">
              <span className="slide-title">System overview</span>
              <span className="deck-node d1">Input</span>
              <span className="deck-node d2">Core</span>
              <span className="deck-node d3">Output</span>
              <span className="copy-chip">Copied SVG + PNG ✓</span>
            </div>
            <h3>Present</h3>
            <p>Copy crisp vectors into PowerPoint, or export PNG, SVG and multi-page PDF.</p>
          </article>
        </div>
      </section>

      <section className="open-source section" aria-labelledby="open-title">
        <div className="open-copy">
          <p className="hand-note">no black box here</p>
          <h2 id="open-title">A focused Mac tool, built in the open.</h2>
          <p>
            Your documents are versioned <code>.tpa</code> files. There is no
            login, cloud sync, tracking pixel, or hidden AI service.
          </p>
          <a className="text-link" href={repo}>Explore the source on GitHub →</a>
        </div>
        <div className="code-note" aria-label="Trackpad Canvas document example">
          <div className="code-bar">
            <span /><span /><span />
            <b>architecture.tpa</b>
          </div>
          <pre>{`{
  "schemaVersion": 1,
  "pages": [{
    "name": "Data platform",
    "layers": ["Diagram", "Notes"]
  }]
}`}</pre>
          <span className="tape tape-left" aria-hidden="true" />
          <span className="tape tape-right" aria-hidden="true" />
        </div>
      </section>

      <section className="install section" id="install" aria-labelledby="install-title">
        <div className="section-heading">
          <p className="eyebrow">Beta installation</p>
          <h2 id="install-title">On your trackpad in three steps.</h2>
        </div>
        <ol className="install-steps">
          <li>
            <span>1</span>
            <div><strong>Download the DMG</strong><p>Universal build for macOS 13 and later.</p></div>
          </li>
          <li>
            <span>2</span>
            <div><strong>Drag it to Applications</strong><p>The disk image includes a shortcut.</p></div>
          </li>
          <li>
            <span>3</span>
            <div><strong>Open it once</strong><p>Right-click the app and choose Open. If macOS still blocks it, run <code>xattr -cr "/Applications/Trackpad Canvas.app"</code> in Terminal.</p></div>
          </li>
        </ol>
        <div className="install-cta">
          <a className="button button-primary" href={download}>Download beta DMG</a>
          <p>SHA-256 checksum is published with every GitHub release.</p>
        </div>
      </section>

      <section className="final-cta section">
        <p className="hand-note">less clicking, more thinking</p>
        <h2>Sketch fast. Refine clean. Present anywhere.</h2>
        <a className="button button-dark" href={download}>Get Trackpad Canvas</a>
      </section>

      <footer>
        <div className="brand">
          <span className="brand-mark" aria-hidden="true" />
          <span>Trackpad Canvas</span>
        </div>
        <p>Built for breakdowns, architecture and the next good question.</p>
        <div className="footer-links">
          <a href={repo}>GitHub</a>
          <a href="/privacy">Privacy</a>
          <a href="/license">License</a>
        </div>
      </footer>
    </main>
  );
}

function ProductDemo() {
  return (
    <div className="product-demo" aria-label="Animated Trackpad Canvas workflow">
      <div className="demo-caption caption-one">1. move your fingers</div>
      <div className="trackpad" aria-hidden="true">
        <span className="touch-ring r1" /><span className="touch-ring r2" />
        <span className="finger f1" />
        <span className="trackpad-label">TRACKPAD</span>
      </div>
      <div className="demo-arrow" aria-hidden="true">→</div>
      <div className="app-window" aria-hidden="true">
        <div className="window-bar">
          <span /><span /><span />
          <b>Trackpad Canvas</b>
          <em>ZEN</em>
        </div>
        <div className="app-body">
          <div className="app-tools">
            <i>↖</i><i>✎</i><i>□</i><i>○</i><i>↗</i><i>T</i>
          </div>
          <div className="app-canvas">
            <span className="demo-node source">Sources</span>
            <span className="demo-node model">Model</span>
            <span className="demo-node serve">Serve</span>
            <span className="demo-line line-one" />
            <span className="demo-line line-two" />
            <span className="gesture-stroke" />
            <span className="snap-guide" />
            <span className="copy-toast">Copied for PowerPoint ✓</span>
          </div>
          <div className="app-inspector">
            <b>LAYERS</b>
            <span>◉ Diagram</span>
            <span>◉ Notes</span>
            <b>STYLE</b>
            <div className="swatches"><i /><i /><i /><i /></div>
          </div>
        </div>
      </div>
      <div className="demo-caption caption-two">2. watch the structure emerge</div>
    </div>
  );
}
