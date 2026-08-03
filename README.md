# Trackpad Canvas

**Your trackpad is the canvas.**

Trackpad Canvas is a native macOS diagramming tool for breakdowns, data
architecture, system design and presentation sketches. One finger draws the
moment it touches the trackpad, two fingers navigate, and the pointer editor
turns the sketch into a clean, connected diagram.

## Beta features

- Pen, line, rectangle, ellipse, arrow, connector, text, select and hand tools
- Immediate pressure-aware one-finger drawing with a subtle live trail
- Adaptive smoothing and point interpolation for continuous strokes
- `Esc` exits drawing mode; `D` or the Canvas button returns to drawing
- Pointer and Zen interaction modes
- Selection, move, resize, duplicate, group, delete and lock
- Persistent connectors, 8 pt grid snapping and two auto-layout directions
- Pages, layers and five editable architecture templates
- Versioned local `.tpa` documents with crash recovery
- SVG + PNG clipboard output for PowerPoint
- PNG, SVG, single-page PDF and multi-page PDF export
- Trackpad Lab with live contact diagnostics

## Install

Download [`TrackpadCanvas-0.1.0-beta.2.dmg`](https://github.com/LobsterQBA/trackpad-canvas/releases/download/v0.1.0-beta.2/TrackpadCanvas-0.1.0-beta.2.dmg),
drag the app to Applications, then right-click the app and choose **Open**.
The beta is ad-hoc signed and is not yet notarized.

If macOS still blocks the app, run this once in Terminal:

```sh
xattr -cr "/Applications/Trackpad Canvas.app"
```

Requires macOS 13 or later. The DMG contains a Universal 2 build for Apple
silicon and Intel.

## Development

The macOS app is a Swift Package in `macos/`. A project-local run action builds
and launches a real app bundle:

```sh
./script/build_and_run.sh
```

Run the website:

```sh
npm install
npm run dev
```

Build and test:

```sh
cd macos && swift test
npm test
./script/package_beta.sh
```

`swift test` requires a complete Xcode installation. The local build script
also supports a direct-compiler fallback for machines that only have Apple
Command Line Tools.

Ready-to-enable GitHub Actions definitions live in `ci/`. Move them into
`.github/workflows/` from a GitHub credential with Workflow permission to
activate continuous integration and tagged releases.

## Privacy

The app is local-first. It has no accounts, analytics, cloud sync, tracking,
advertising or remote AI service.

## Attribution

The low-level multitouch implementation adapts work from
[Trackpad Studio](https://github.com/ZaynJarvis/trackpad-studio) by Zayn Jarvis.
See `THIRD_PARTY_NOTICES.md`.

## License

MIT
