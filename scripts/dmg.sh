#!/bin/zsh
set -euo pipefail

# Package the signed .app into a compressed disk image so it can be shared and dragged into Applications.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

./scripts/build.sh

APP="$ROOT/dist/iCopy.app"
STAGE="$ROOT/dist/dmg-stage"
DMG="$ROOT/dist/iCopy.dmg"
VOLUME_NAME="iCopy"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/iCopy.app"
# Finder users expect to drag the app next to Applications.
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"

rm -rf "$STAGE"

BYTES="$(stat -f %z "$DMG")"
echo "Created $DMG (${BYTES} bytes)"
