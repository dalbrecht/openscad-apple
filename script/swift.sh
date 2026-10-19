#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="${OPENSCAD_BUILD_ROOT:-/private/tmp/openscad-apple-native}"
mkdir -p "$BUILD_ROOT"/{clang,cache,config,security}
export CLANG_MODULE_CACHE_PATH="$BUILD_ROOT/clang"
cd "$ROOT"
xcrun swift "$@" --build-system native --disable-sandbox --scratch-path "$BUILD_ROOT/build" --cache-path "$BUILD_ROOT/cache" --config-path "$BUILD_ROOT/config" --security-path "$BUILD_ROOT/security" -j 6 -Xswiftc -warnings-as-errors
