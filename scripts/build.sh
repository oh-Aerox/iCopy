#!/bin/zsh
set -euo pipefail

# Produce a signed .app so Finder and the menu bar extra can launch it on Apple Silicon.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release --arch arm64

BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"
BIN="$BIN_DIR/iCopy"
APP="$ROOT/dist/iCopy.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/iCopy"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Stable bundle id in the signature so Privacy → Accessibility can match the same app entry.
codesign --force --deep --sign - --identifier "com.icopy.app" "$APP"

BYTES="$(stat -f %z "$APP/Contents/MacOS/iCopy")"
echo "Built $APP (${BYTES} bytes binary)"
