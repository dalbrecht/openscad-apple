# OpenSCAD Apple prototype

Native macOS 14+ SwiftUI/Metal viewer and separate source editor backed by a pinned,
Qt-free fork of the real OpenSCAD parser/evaluator. This is an early local prototype;
see [acceptance](docs/acceptance.md) and [architecture](docs/adr/0001-native-preview.md).

Install Xcode CLI tools and Homebrew dependencies:
`brew install cmake ninja eigen boost bison flex libzip libxml2 pkgconf tbb cgal`.
Existing HarfBuzz, FreeType, Fontconfig, GLib, GMP, MPFR, OpenSSL and double-conversion
are also required by upstream (`brew install harfbuzz freetype fontconfig glib gmp mpfr openssl double-conversion`).

Run `./script/build_and_run.sh` for the viewer, or add `--editor` for the editor.
Use `--verify` to check launch and `--build-only` to stage without launching.
Builds use /private/tmp/openscad-apple-native to avoid File Provider signature issues.
Local app ZIPs appear in outputs/. They link Homebrew libraries and are not standalone
distribution packages. `make ci` builds/tests and checks Qt/OpenGL linkage.

The CMake worker preserves fast CSG leaves and operations, not just final meshes.
Drag to orbit, scroll to zoom, Fit Model to reset, Wireframe for source edges.
The editor opens/saves .scad text and previews explicitly with Command-R.
Bounded prototype limits, opaque background layers and degenerate input limitations
are documented. No full OpenCSG rendering or OpenSCAD editor parity is claimed.

Core history, license and regression fixtures remain in the upstream-derived
[openscad-core](https://github.com/dalbrecht/openscad-core) fork. App code is
GPL-2.0-or-later to align with the linked engine. See LICENSE and DEPENDENCIES.md.
