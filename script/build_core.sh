#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="${OPENSCAD_CORE_PATH:-$ROOT/work/openscad-core}"
if [ ! -d "$CORE/.git" ]; then
  git clone https://github.com/dalbrecht/openscad-core.git "$CORE"
  git -C "$CORE" checkout "$(cat "$ROOT/core-revision.txt")"
  git -C "$CORE" submodule update --init submodules/Clipper2 submodules/manifold submodules/sanitizers-cmake
fi
PIN="$(cat "$ROOT/core-revision.txt")"
if [ -z "${OPENSCAD_CORE_PATH:-}" ] && [ "$(git -C "$CORE" rev-parse HEAD)" != "$PIN" ]; then
  echo "Core revision differs from core-revision.txt; use an explicit OPENSCAD_CORE_PATH for development." >&2
  exit 1
fi
if [ -z "${OPENSCAD_CORE_PATH:-}" ] && ! git -C "$CORE" diff --quiet HEAD -- CMakeLists.txt src native; then
  echo "Core sources differ from their pin; use an explicit OPENSCAD_CORE_PATH for development." >&2
  exit 1
fi
cmake -S "$CORE" -B "$CORE/build-native" -G Ninja -DHEADLESS=ON -DNULLGL=ON -DAPPLE_UNIX=ON \
  -DENABLE_CGAL=ON -DENABLE_NATIVE_PREVIEW=ON -DNATIVE_PREVIEW_COVERAGE=OFF -DMANIFOLD_PAR=OFF -DUSE_MIMALLOC=OFF \
  -DENABLE_TESTS=OFF -DENABLE_CAIRO=OFF -DENABLE_HIDAPI=OFF -DENABLE_SPNAV=OFF \
  -DCMAKE_REQUIRE_FIND_PACKAGE_Lib3MF=OFF -DBISON_EXECUTABLE=/opt/homebrew/opt/bison/bin/bison \
  -DFLEX_EXECUTABLE=/opt/homebrew/opt/flex/bin/flex -DCMAKE_BUILD_TYPE=Release
cmake --build "$CORE/build-native" --target openscad-preview-worker -j 6
