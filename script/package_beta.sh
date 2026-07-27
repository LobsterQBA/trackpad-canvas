#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACOS_DIR="$ROOT_DIR/macos"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Trackpad Architect"
EXECUTABLE="TrackpadArchitect"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/TrackpadArchitect-0.1.0-beta.1.dmg"

mkdir -p "$DIST_DIR"
cd "$MACOS_DIR"

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

build_arch() {
  local arch="$1"
  local target_dir="$MACOS_DIR/.build-$arch"
  mkdir -p "$target_dir"
  clang -isysroot "$SDK_PATH" -arch "$arch" -mmacosx-version-min=13.0 \
    -O2 -c Sources/CMultitouchShim/shim.c -o "$target_dir/shim.o"
  swiftc -sdk "$SDK_PATH" -target "$arch-apple-macos13.0" -O \
    -parse-as-library -I Sources/CMultitouchShim/include \
    $(find Sources/TrackpadArchitect -name '*.swift' -print | sort) \
    "$target_dir/shim.o" -o "$target_dir/$EXECUTABLE"
}

build_arch arm64
build_arch x86_64

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
lipo -create \
  ".build-arm64/$EXECUTABLE" \
  ".build-x86_64/$EXECUTABLE" \
  -output "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE"

cp "$ROOT_DIR/LICENSE" "$APP_BUNDLE/Contents/Resources/LICENSE.txt"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$APP_BUNDLE/Contents/Resources/THIRD_PARTY_NOTICES.md"
"$ROOT_DIR/script/generate_app_icon.sh" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

cat >"$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>$EXECUTABLE</string>
  <key>CFBundleIdentifier</key><string>com.trackpadarchitect.app</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleShortVersionString</key><string>0.1.0-beta.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>UTExportedTypeDeclarations</key>
  <array><dict>
    <key>UTTypeIdentifier</key><string>com.trackpadarchitect.document</string>
    <key>UTTypeDescription</key><string>Trackpad Architect Document</string>
    <key>UTTypeConformsTo</key><array><string>public.json</string></array>
    <key>UTTypeTagSpecification</key><dict>
      <key>public.filename-extension</key><array><string>tpa</string></array>
      <key>public.mime-type</key><string>application/vnd.trackpadarchitect+json</string>
    </dict>
  </dict></array>
  <key>CFBundleDocumentTypes</key>
  <array><dict>
    <key>CFBundleTypeName</key><string>Trackpad Architect Document</string>
    <key>LSItemContentTypes</key><array><string>com.trackpadarchitect.document</string></array>
    <key>CFBundleTypeRole</key><string>Editor</string>
  </dict></array>
</dict></plist>
PLIST

codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT
cp -R "$APP_BUNDLE" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

rm -f "$DMG_PATH" "$DMG_PATH.sha256"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG_PATH"
(cd "$DIST_DIR" && shasum -a 256 "$(basename "$DMG_PATH")") > "$DMG_PATH.sha256"
lipo -archs "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE"
