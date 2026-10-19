#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="${OPENSCAD_CORE_PATH:-$ROOT/work/openscad-core}"
BUILD_ROOT="${OPENSCAD_BUILD_ROOT:-/private/tmp/openscad-apple-native}"
for FILE in "$CORE/build-native/openscad-preview-worker" "$BUILD_ROOT/app/OpenSCADViewer.app/Contents/MacOS/OpenSCADViewer"; do
  LINKAGE="$(otool -L "$FILE")" || { echo "Cannot inspect: $FILE" >&2; exit 1; }
  if printf "%s\n" "$LINKAGE" | grep -E 'Qt|OpenGL'; then
    echo "Forbidden GUI linkage: $FILE" >&2
    exit 1
  fi
done
