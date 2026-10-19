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

32 Swift/GPU tests pass without skips. New Swift file coverage: PreviewCompiler
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

The editor uses native DocumentGroup/FileDocument ownership for source editing,
coordinated saves, dirty tracking, close/quit protection and macOS recovery. Syntax
highlighting, customizer, export and animation remain unimplemented. Recovery timing
is controlled by macOS; immediate power-loss durability is not guaranteed. Linux/Windows core runtime tests, macOS 14
runtime deployment and distribution packaging remain unverified.

## Final local gate

`make ci` passes: 32 Swift/Metal tests, 2 launcher regression tests, 20 core tests, strict Swift formatting,
shell parsing and Qt/OpenGL linkage rejection. No tests are skipped in that run.
Core PR #2 reports no remote checks configured; local results are not remote CI.

## Dirty-document follow-up (PR #2, issue #3)

The editor now binds TextEditor directly to the native document value. Open uses
native document commands, preserving the edited draft in a separate window. Save
uses the responder chain; native macOS owns close/quit decisions and recovery.
The viewer remains read-only. See ADR 0002.

Added regression coverage includes independent saved/recovery snapshots, saving
incomplete/invalid SCAD, malformed UTF-8 and source quotas, retained edits after
failed encoding, current source/path preview snapshots, and refusing bundle
replacement both for a running editor and failed process inspection. The
FileDocument bridge measures 58.33% automated line coverage: framework-created
read/write configurations and native dialogs are a thin manual boundary; their
constructors are not public. This is not claimed as 95% whole-adapter coverage.

Native acceptance on this host:
- Created an edited untitled draft and closed it; macOS presented Save/Delete/Cancel.
- Cancel kept the complete source and edited indicator.
- Opened acceptance-model.scad; both it and the original dirty draft remained in
  the Window menu, and the original source was unchanged when selected again.
- Toolbar Save wrote dirty-recovery-model.scad with matching UTF-8 bytes.
- Quit with another edited draft presented the same native protection. Cancel
  aborted quitting and retained all text. Command-S then saved that source as
  quit-protection-model.scad; Preview rendered its sphere.
- The real launcher refused an attempted editor rebuild while those windows were
  open, without replacing the bundle or closing documents.

Save and Cancel were exercised; the destructive Delete choice was observed but
not selected. Forced-crash/power-loss recovery and older macOS versions were not
simulated. System-managed autosave/recovery depends on macOS preferences and timing.

## Phase 0/1 baseline review follow-up

At core revision `65b79fac2aba2cb8911703a9e7a29949af8b7948`, the complete local
`OPENSCAD_CORE_PATH=/private/tmp/openscad-core-spike make ci` gate passes. The
explicit checkout has the exact pin and avoids iCloud file-provider timeouts.
The gate builds the viewer bundle and explicitly compiles the editor executable;
it does not replace a running editor bundle. Swift/Metal tests cover the camera
inside an operand and portrait viewport fitting. Script regressions verify failed
linkage inspection and consistent core override selection. The separate core's
24 boundary regressions cover failed evaluation, reflected winding, nonfinite
colors and deep traversal quotas. No full inherited-engine coverage is claimed.

The prior native document interaction evidence remains applicable; this follow-up
does not claim a new manual portrait-window inspection or clean-machine install.
