# Trackpad Canvas v0.1.0-beta.1

The first public beta turns the Mac trackpad into a native architecture canvas.

## Highlights

- Immediate one-finger drawing with an ephemeral trail and adaptive smoothing
- Familiar `Esc` to exit drawing mode, with `D` to return
- Two-finger pan and zoom, plus a safe pointer fallback
- Shapes, text, arrows and connectors that remain attached while nodes move
- Pages, layers, locking, grouping, grid snapping and two auto-layout options
- Five templates for breakdowns, pipelines, system context and ownership
- Local `.tpa` files and recovery snapshots
- PowerPoint-friendly SVG + PNG copy
- PNG, SVG and PDF export
- Universal 2 build for macOS 13+

## Beta note

This build is ad-hoc signed while Developer ID notarization is being prepared.
After copying it to Applications, right-click the app and choose **Open** the
first time. If macOS still blocks it, run `xattr -cr "/Applications/Trackpad Canvas.app"`.
