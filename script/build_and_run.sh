#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="TrackpadCanvas"
BUNDLE_ID="com.trackpadcanvas.app"
MIN_SYSTEM_VERSION="13.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACOS_DIR="$ROOT_DIR/macos"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/Trackpad Canvas.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$MACOS_DIR"
if xcrun --sdk macosx --show-sdk-platform-path >/dev/null 2>&1; then
  swift build
  BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
else
  SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
  DIRECT_DIR="$MACOS_DIR/.build-direct"
  mkdir -p "$DIRECT_DIR"
  clang -isysroot "$SDK_PATH" -arch arm64 -mmacosx-version-min="$MIN_SYSTEM_VERSION" \
    -c Sources/CMultitouchShim/shim.c -o "$DIRECT_DIR/shim.o"
  swiftc -sdk "$SDK_PATH" -target arm64-apple-macos"$MIN_SYSTEM_VERSION" \
    -parse-as-library -I Sources/CMultitouchShim/include \
    $(find Sources/TrackpadArchitect -name '*.swift' -print | sort) \
    "$DIRECT_DIR/shim.o" -o "$DIRECT_DIR/$APP_NAME"
  BUILD_BINARY="$DIRECT_DIR/$APP_NAME"
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_CONTENTS/Resources"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
"$ROOT_DIR/script/generate_app_icon.sh" "$APP_CONTENTS/Resources/AppIcon.icns"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>Trackpad Canvas</string>
  <key>CFBundleDisplayName</key><string>Trackpad Canvas</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>UTExportedTypeDeclarations</key>
  <array><dict>
    <key>UTTypeIdentifier</key><string>com.trackpadcanvas.document</string>
    <key>UTTypeDescription</key><string>Trackpad Canvas Document</string>
    <key>UTTypeConformsTo</key><array><string>public.json</string></array>
    <key>UTTypeTagSpecification</key><dict>
      <key>public.filename-extension</key><array><string>tpa</string></array>
      <key>public.mime-type</key><string>application/vnd.trackpadcanvas+json</string>
    </dict>
  </dict></array>
  <key>CFBundleDocumentTypes</key>
  <array><dict>
    <key>CFBundleTypeName</key><string>Trackpad Canvas Document</string>
    <key>LSItemContentTypes</key><array><string>com.trackpadcanvas.document</string></array>
    <key>CFBundleTypeRole</key><string>Editor</string>
  </dict></array>
</dict></plist>
PLIST

codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
