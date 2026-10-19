#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="${OPENSCAD_CORE_PATH:-$ROOT/work/openscad-core}"
for FILE in "$CORE/build-native/openscad-preview-worker" /private/tmp/openscad-apple-native/build/arm64-apple-macosx/debug/OpenSCADViewer; do
  if otool -L "$FILE" | grep -E 'Qt|OpenGL'; then
    echo "Forbidden GUI linkage: $FILE" >&2
    exit 1
  fi
done
