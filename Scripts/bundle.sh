#!/usr/bin/env bash
# Build a release binary and wrap it in a double-clickable Leap.app bundle.
#
# A real .app (not a bare binary) is required for:
#   • launch-at-login via SMAppService
#   • TCC permissions (Accessibility etc.) to persist across launches
#   • a stable identity macOS can remember
#
# Output: ./dist/Leap.app
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="Leap"
BUNDLE_ID="dev.leap.app"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"

# Version: git tags (vX.Y.Z) are the source of truth.
#   MARKETING_VERSION -> CFBundleShortVersionString (e.g. 1.2.3)
#   BUILD_VERSION     -> CFBundleVersion (monotonic; total commit count)
# Override MARKETING_VERSION in the environment for CI tag builds.
RAW_TAG="$(git describe --tags --always --dirty 2>/dev/null || echo "v0.0.0")"
MARKETING_VERSION="${MARKETING_VERSION:-${RAW_TAG#v}}"
BUILD_VERSION="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
echo "==> Version $MARKETING_VERSION (build $BUILD_VERSION)"

echo "==> Building release binary"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BIN_PATH" "$APP/Contents/MacOS/$APP_NAME"

ICON_KEY=""
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
    ICON_KEY="    <key>CFBundleIconFile</key><string>AppIcon</string>"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key><string>$BUILD_VERSION</string>
    <key>CFBundleShortVersionString</key><string>$MARKETING_VERSION</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
$ICON_KEY
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <!-- Menu-bar-only: no Dock icon -->
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

echo "==> Ad-hoc code signing (local use)"
# Ad-hoc signature is enough to run locally and to let SMAppService register a
# login item. For distribution you'd sign with a Developer ID + notarize.
codesign --force --deep --sign - "$APP"

echo "==> Done: $APP"
echo "    Run it:      open \"$APP\""
echo "    Or binary:   $BIN_PATH"
