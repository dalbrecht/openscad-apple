# Phase 1 feasibility experiments

Tracking issue: #4. These are experiments, not shipped app extensions or parity
acceptance. Portable compilation remains in `dalbrecht/openscad-core`; these
Apple-only probes add no Qt dependency to the native app.

## Metal

The XCTest `FeasibilityTests` runs real worker output through the production Metal
encoder. It checks command completion and nonempty solid pixels, saves offscreen
images, and records ten GPU timings after two warmup frames per workload. It
covers difference, curved surfaces and modifier layers at 256 and 1024 pixels.
Run from the app repository after building the worker:

```
mkdir -p outputs/phase-1
OPENSCAD_TEST_WORKER="$PWD/work/openscad-core/build-native/openscad-preview-worker" \
OPENSCAD_SPIKE_OUTPUT="$PWD/outputs/phase-1" \
./script/swift.sh test --filter FeasibilityTests
```

The report records GPU execution only; it excludes source compilation, JSON decode,
pipeline creation and presentation. Device-specific timings are evidence, not CI
performance thresholds. Current ray CSG is brute force with a 128-event diagnostic,
64 leaves and opaque background. No claim is made about 2D, transparency, coplanar
robustness, large scenes or Qt pixel equivalence. An accelerated ray candidate and
a depth/stencil candidate still require comparative evaluation before choosing a
production renderer.

## Finder

`finder/build.py` builds an isolated ad-hoc-signed host in
`/private/tmp/openscad-finder-spike`, leaving the document editor untouched. It
builds two sandboxed extensions: a bounded UTF-8 source fallback and a recognizable
SCAD thumbnail placeholder. No geometry evaluation or dependency access occurs.
The extra `.scadprobe` UTI isolates activation from the system's text fallback.

```
python3 spikes/finder/build.py
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /private/tmp/openscad-finder-spike/OpenSCADFinderProbe.app
pluginkit -a /private/tmp/openscad-finder-spike/OpenSCADFinderProbe.app/Contents/PlugIns/Preview.appex
pluginkit -a /private/tmp/openscad-finder-spike/OpenSCADFinderProbe.app/Contents/PlugIns/Thumbnail.appex
```

Enable only these probe IDs if necessary with `pluginkit -e use -i ID`.
`RequestThumbnail.swift` exercises the modern QLThumbnailGenerator API with a
30-second deadline; it saves the actual returned image. The older `qlmanage`
command can show the system's source-text fallback and is insufficient to prove
custom-provider activation. Inspect the recognizable SCAD image, not only exit 0.
Finder Space previews must likewise contain the probe's visible marker before
being attributed to the custom extension. Confirm the host is stopped with
`pgrep -x FinderProbe` (status 1 means stopped).

Cleanup only the probe registrations with `pluginkit -r EXTENSION_PATH`; unregister
the host with `lsregister -u HOST_PATH`. Do not reset global Quick Look caches or
change Spotlight privacy settings. The host does not run or kill the editor.

Unresolved gates: actual sandboxed core/helper execution, dependency permissions,
shared/offline cache design, cancellation, malformed-source behavior, image-based
3D providers, signing/notarization and activation on a clean machine. Registration
and an ad-hoc placeholder do not establish release feasibility.

## Spotlight

```
python3 spikes/spotlight/probe.py outputs/phase-1
```

The script creates one known saved-source sentinel, test-imports it, requests
indexing, records `mdls` and polls a scoped `mdfind` query with a 15-second deadline.
It parses XML, binary and OpenStep importer attributes structurally. Unit tests
verify successful extraction, valid JSON/source newlines and delayed indexing.
It changes no system settings and never evaluates SCAD or follows dependencies.
The final metadata-service-enabled run extracts and finds the sentinel on a volume
reporting indexing enabled. Earlier read-only observations are retained as history,
not the final result. System full-text indexing is feasible without a custom
metadata importer. Rich symbol metadata and clean-machine checks remain future work.

Apple APIs: [QLPreviewingController](https://developer.apple.com/documentation/QuickLookUI/QLPreviewingController),
[Spotlight importer guidance](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/MDImporters/Concepts/WritingAnImp.html).
