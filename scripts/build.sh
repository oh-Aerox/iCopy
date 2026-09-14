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

# Accessibility (TCC) grants are keyed to the code signature. An ad-hoc signature's
# cdhash changes on every rebuild, so each build silently drops the Accessibility grant
# and the synthetic ⌘V paste is blocked (paste.blocked_no_accessibility). Signing with a
# stable identity keeps the Designated Requirement constant across rebuilds, so the grant
# persists once given. Override with ICOPY_SIGN_IDENTITY; otherwise auto-pick an
# Apple Development identity; fall back to ad-hoc only when no real identity exists.
SIGN_IDENTITY="${ICOPY_SIGN_IDENTITY:-}"
if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/Apple Development|Developer ID Application/ {print $2; exit}')"
fi

if [[ -n "$SIGN_IDENTITY" ]]; then
  # Stable bundle id + real identity so Privacy → Accessibility matches across rebuilds.
  codesign --force --deep --sign "$SIGN_IDENTITY" --identifier "com.icopy.app" "$APP"
  echo "Signed with stable identity: $SIGN_IDENTITY"
else
  codesign --force --deep --sign - --identifier "com.icopy.app" "$APP"
  echo "WARNING: ad-hoc signed — the Accessibility grant resets on every rebuild, which blocks auto-paste."
  echo "         Set ICOPY_SIGN_IDENTITY or install an Apple Development certificate to make it persist."
fi

BYTES="$(stat -f %z "$APP/Contents/MacOS/iCopy")"
echo "Built $APP (${BYTES} bytes binary)"
