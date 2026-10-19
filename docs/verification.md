# Local prototype verification — 2026-10-19

Host: Apple Silicon, macOS 27.0.1, Xcode 27 / Swift 6 toolchain.
Source deployment declaration: macOS 14. The local Homebrew dylibs target macOS
26/27, so these development ZIPs are verified only on this host. Building the
runtime dependency closure for macOS 14 and testing that OS remain required.

## Real core boundary

Core pin: 51f9cfe870f2599a1fd0626159279ef5101ba609.
CMake HEADLESS/NULLGL build succeeds with CGAL and Manifold enabled. Native worker
and Apple executable linkage checks reject Qt and OpenGL dependencies.
20 worker tests cover difference/intersection structure, $preview, real modules
and loops, malformed syntax, NUL rejection, source/topology quotas, empty output,
relative includes, retained successful warnings, owned outputs and independent
concurrent workers. All pass.

Clang instrumentation scoped only to native/preview_worker.cc measured 97.27% line,
90.62% region and 80.88% branch coverage. The inherited OpenSCAD library is not
instrumented in this figure. Exception/resource edge branches and unsupported
geometry paths remain; this is not a claim of 100% engine coverage.

## Swift and GPU

27 Swift/GPU tests pass without skips. New Swift file coverage: PreviewCompiler
98.55% lines, PreviewScene 98.73%, SourceFileService 95.24%. Production GPU resource
encoding measures 94.37%; AppKit viewport and macro-expanded SwiftUI workspace have
lower automated coverage (38.27% and 14.54%) and are supplemented by native checks.
No whole-app 95% or legacy-engine coverage claim is made.

The suite includes real-engine ownership across later compiles, source/output
quotas, malformed scene topology/colors/coordinates, future versions, cancellation
before/during work, process deadline/failure diagnostics, late-result suppression,
background UTF-8 file snapshots and atomic source round trips.
The production Metal encoder is exercised on offscreen textures: difference shows
a background hole where union is solid; intersection clips the outer region;
wireframe changes rendered pixels. Tests also cover position-based AppKit drags.

A full run exposed Foundation waitUntilExit blocking after killing an exited child;
it was removed. Foundation owns process reaping; cancellation sends SIGKILL only to
the request's own live child. Completion is polled asynchronously. A rendered editor
check exposed stale NSView identity on successful compilation; the identity now
advances on scene completion, with regression tests for retained failures and late
results. These failures were fixed, not excluded from the final gate.

## Native observations

Both app bundles launch through the canonical script and have verified ad-hoc
signatures. Native UI inspection observed the viewer's evaluated cube-minus-cylinder,
counts and wireframe control. The separate editor displayed a new coral sphere with
a cylindrical hole after source replacement, and the saved UTF-8 SCAD example was
reopened with matching text and preview. The initial stale geometry issue was
reproduced and fixed before accepting that check.

## Acceptance limits

This is a working viewer and initial source-editor slice. It is not full OpenCSG or
OpenSCAD editor parity. The renderer supports 3D leaves, explicit Boolean structure,
flat leaf-triangle lighting and source wireframe. Background layers are opaque;
coplanar/nonmanifold/degenerate cases, translucency and broad regression-render
comparisons remain. A ray with more than 128 triangle events becomes magenta.
Large scenes can be expensive; no GPU acceleration structure is implemented.
Core geometry workspace memory is not hard capped and local includes/imports are
not sandboxed. Normal process isolation is not a hostile-document security boundary.

The editor has explicit preview/open/save and the standard text control; syntax
highlighting, customizer, export, animation, autosave, dirty-document close recovery
and full document lifecycle protection are not implemented. Save edits explicitly
before opening or closing documents. Linux/Windows core runtime tests, macOS 14
runtime deployment and distribution packaging remain unverified.

## Final local gate

`make ci` passes: 27 Swift/Metal tests, 20 core tests, strict Swift formatting,
shell parsing and Qt/OpenGL linkage rejection. No tests are skipped in that run.
Core PR #2 reports no remote checks configured; local results are not remote CI.
