#!/bin/zsh
set -euo pipefail

usage() {
  cat <<'TXT'
Usage: scripts/build-app.sh [--zip]

Builds build/Scuttle.app (universal when the toolchain allows, else host arch),
ad-hoc signed. With --zip also writes dist/Scuttle-<version>.zip.

Environment:
  SIGN_IDENTITY   Developer ID Application identity; signs with hardened runtime
  NOTARY_PROFILE  notarytool keychain profile; notarizes and staples (implies --zip)
TXT
}

ZIP=0
for arg in "$@"; do
  case "$arg" in
    --zip) ZIP=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

ROOT="${0:A:h:h}"
cd "$ROOT"
VERSION="$(tr -d '[:space:]' < VERSION)"
SCRATCH=".build-release"
APP="build/Scuttle.app"

if swift build -c release --arch arm64 --arch x86_64 --scratch-path "$SCRATCH" --product Scuttle; then
  BIN="$(swift build -c release --arch arm64 --arch x86_64 --scratch-path "$SCRATCH" --show-bin-path)/Scuttle"
else
  echo "Universal build failed; building for the host architecture."
  swift build -c release --scratch-path "$SCRATCH" --product Scuttle
  BIN="$(swift build -c release --scratch-path "$SCRATCH" --show-bin-path)/Scuttle"
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Scuttle"

setopt null_glob
for f in Assets/AppIcon.icns Assets/MenuBarIcon*.png scripts/timelines/*.json; do
  if [[ -f "$f" ]]; then cp "$f" "$APP/Contents/Resources/"; fi
done
unsetopt null_glob

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Scuttle</string>
  <key>CFBundleIdentifier</key><string>app.scuttle.Scuttle</string>
  <key>CFBundleName</key><string>Scuttle</string>
  <key>CFBundleDisplayName</key><string>Scuttle</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSLocationUsageDescription</key><string>Scuttle uses your rough location to match the figures to today's weather.</string>
  <key>NSLocationWhenInUseUsageDescription</key><string>Scuttle uses your rough location to match the figures to today's weather.</string>
  <key>NSHumanReadableCopyright</key><string>Copyright © $(date +%Y). All rights reserved.</string>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key><string>app.scuttle.Scuttle</string>
      <key>CFBundleURLSchemes</key><array><string>scuttle</string></array>
    </dict>
  </array>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
else
  codesign --force --deep --sign - "$APP"
fi
codesign --verify --strict "$APP"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  ZIP=1
fi

if (( ZIP )); then
  mkdir -p dist
  OUT="dist/Scuttle-$VERSION.zip"
  rm -f "$OUT"
  ditto -c -k --keepParent "$APP" "$OUT"
  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    if [[ -z "${SIGN_IDENTITY:-}" ]]; then
      echo "NOTARY_PROFILE needs SIGN_IDENTITY as well." >&2
      exit 1
    fi
    xcrun notarytool submit "$OUT" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    rm -f "$OUT"
    ditto -c -k --keepParent "$APP" "$OUT"
  fi
  echo "Wrote $OUT"
fi

echo "Built $APP ($VERSION, $(lipo -archs "$APP/Contents/MacOS/Scuttle"))"
