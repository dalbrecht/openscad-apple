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
ensure_editor_closed() {
  if [ "$APP" != OpenSCADEditor ]; then return; fi
  if pgrep -x "$APP" >/dev/null; then
    echo "Close OpenSCAD Editor normally before rebuilding; unsaved documents must not be killed or replaced." >&2
    exit 1
  else
    STATUS=$?
    if [ "$STATUS" -ne 1 ]; then
      echo "Cannot safely check whether OpenSCAD Editor is running; refusing to replace its bundle." >&2
      exit 1
    fi
  fi
}
ensure_editor_closed
"$ROOT/script/build_core.sh"
"$ROOT/script/swift.sh" build --product "$APP"
BIN="$("$ROOT/script/swift.sh" build --show-bin-path)"
# Recheck after compilation in case the editor was opened while the build ran.
ensure_editor_closed
if [ "$APP" = OpenSCADViewer ]; then pkill -x "$APP" 2>/dev/null || true; fi
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
<key>LSItemContentTypes</key><array><string>org.openscad.source</string></array>
<key>CFBundleTypeRole</key><string>$ROLE</string>
<key>LSHandlerRank</key><string>Alternate</string>
</dict></array>
<key>UTImportedTypeDeclarations</key><array><dict>
<key>UTTypeIdentifier</key><string>org.openscad.source</string>
<key>UTTypeDescription</key><string>OpenSCAD Source</string>
<key>UTTypeConformsTo</key><array><string>public.source-code</string></array>
<key>UTTypeTagSpecification</key><dict><key>public.filename-extension</key><array><string>scad</string></array></dict>
</dict></array>
<key>NSDocumentsUseCocoaOpenPanel</key><true/>
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
