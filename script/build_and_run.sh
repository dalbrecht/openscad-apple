#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP=OpenSCADViewer
if [ "${1:-}" = --editor ]; then APP=OpenSCADEditor; shift; fi
ROLE=Viewer
if [ "$APP" = OpenSCADEditor ]; then ROLE=Editor; fi
MODE="${1:-run}"
case "$MODE" in run|--build-only|--verify|--debug|--logs|--telemetry) ;; *) exit 2;; esac
BUILD_ROOT="${OPENSCAD_BUILD_ROOT:-/private/tmp/openscad-apple-native}"
BUNDLE="$BUILD_ROOT/app/$APP.app"
CORE="${OPENSCAD_CORE_PATH:-$ROOT/work/openscad-core}"
"$ROOT/script/build_core.sh"
"$ROOT/script/swift.sh" build --product "$APP"
BIN="$("$ROOT/script/swift.sh" build --show-bin-path)"
# Stop only this dedicated product; the Dust3D applications are independent.
pkill -x "$APP" 2>/dev/null || true
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources" "$ROOT/outputs"
cp "$BIN/$APP" "$BUNDLE/Contents/MacOS/"
cp "$CORE/build-native/openscad-preview-worker" "$BUNDLE/Contents/MacOS/"
cp -R "$BIN/OpenSCADApple_NativeRendering.bundle" "$BUNDLE/Contents/Resources/"
cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP</string>
<key>CFBundleIdentifier</key><string>org.openscad.native.$APP</string>
<key>CFBundleName</key><string>$APP</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleDocumentTypes</key><array><dict>
<key>CFBundleTypeName</key><string>OpenSCAD Design</string>
<key>CFBundleTypeExtensions</key><array><string>scad</string></array>
<key>CFBundleTypeRole</key><string>$ROLE</string>
<key>LSHandlerRank</key><string>Alternate</string>
</dict></array>
</dict></plist>
PLIST
xattr -cr "$BUNDLE"
codesign --force --sign - "$BUNDLE/Contents/MacOS/openscad-preview-worker"
codesign --force --sign - "$BUNDLE"
codesign --verify --deep --strict "$BUNDLE"
ditto -c -k --keepParent "$BUNDLE" "$ROOT/outputs/$APP.zip"
case "$MODE" in
  --build-only) echo "$BUNDLE";;
  --debug) lldb -- "$BUNDLE/Contents/MacOS/$APP";;
  --verify) open -n "$BUNDLE"; sleep 1; pgrep -x "$APP";;
  --logs|--telemetry) open -n "$BUNDLE"; log stream --info --predicate "process == \"$APP\"";;
  run) open -n "$BUNDLE";;
esac
