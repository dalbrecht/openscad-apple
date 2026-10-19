# Phase 0/1 evidence — 19 October 2026

Tracking: #4. Source ledger: `docs/parity/`. Separate core PR: dalbrecht/openscad-core#2.

## Reference inventory

515 Qt Designer actions/controls across 30 forms, plus 18 cross-cutting behavior
families. The supplemental `qt-capabilities.csv` lists 18 export enum values and
41 command-line registrations from the pinned source (`src/io/export.h` and
`src/openscad.cc`). All remain unverified; optional preprocessor branches are
retained. This is an inventory for acceptance work, not completed parity.

The normal Qt configuration was attempted with HEADLESS=OFF and NULLGL=OFF.
Missing OpenCSG and allocator sources were resolved by installing reference-only
packages and initializing the upstream mimalloc submodule. Qt base/SVG/multimedia,
QScintilla and OpenCSG are development reference dependencies only. Configuration
then fails at required Lib3MF discovery. The reduced native configuration is not
substituted for the reference. No running frozen Qt binary or comparison images
are claimed. This remains a phase 0 exit blocker.

## Renderer

The production Metal encoder rendered actual worker-generated difference, curved
surface and modifier-layer scenes. On Apple M5 at 256px, the first experiment's
median GPU execution was 2.37 / 5.37 / 3.01 ms for 584 / 2300 / 1156 triangles.
The expanded 1024px run measured 21.15 / 86.31 / 43.39 ms respectively.
These are device-specific GPU timings, excluding compilation, decode, pipeline
creation and presentation. The curved fixture already exceeds a 60fps frame
budget by over five times, so the brute-force path is not a production performance
solution. XCTest saves the complete 256/1024px report separately.
The rendered difference image visibly contains the cutout. Existing pixel tests
check union/intersection/difference and a new camera-inside-operand regression.

Decision: retain the ray-CSG prototype as a correctness harness, not the selected
production architecture. Acceleration and depth/stencil alternatives remain
comparative experiments. Current quotas, opaque backgrounds and unsupported 2D
prevent parity claims.

## Finder

Two sandboxed, ad-hoc-signed providers compile and register in an isolated host.
The modern thumbnail API activates the custom SCAD-labelled placeholder for a
new test-only `.scadprobe` UTI while `FinderProbe` is stopped. Real `.scad` requests
still return the system's text thumbnail. Legacy qlmanage output alone therefore
cannot prove activation. Finder's actual Space preview was inspected and showed
saved source text. The custom preview controller's visible marker has not been
verified in Finder.

Decision: system source fallback is viable now. 3D extension activation/type
routing, sandboxed core/helper execution, allowed dependencies, cache invalidation
and clean-machine signed activation remain open. No preview worker is launched
inside these provider probes, and no model is falsely presented as fully compiled.

## Spotlight

The registered `org.openscad.source` type inherits `public.source-code`.
`mdimport -t` selects Apple's RichText importer and extracts the saved source and
unique sentinel. `mdimport -i`, `mdls` and a directory-scoped `mdfind` were also run.
The data volume reports a read-only index, metadata remains null and search does
not find the sentinel. Extraction is verified; real search is blocked here.

Decision: keep system text indexing as the first path. Test on a writable index
before adding a custom metadata importer. Index saved source only; never evaluate
SCAD or traverse libraries for search. Do not duplicate file records through Core
Spotlight merely to conceal a failed filesystem-index test.

## Reproduction and remaining gates

See `spikes/README.md`. The probes are not shipped in the editor bundle. Production
boundary coverage and inherited core coverage remain separate. No system privacy,
index configuration or global thumbnail cache was reset. Local build artifacts
under iCloud encountered repeated filesystem timeouts; an exact core checkout in
`/private/tmp` is used for repeatable build verification.

Phases 0/1 have executable evidence and explicit blockers; their full exit gates
are not complete. Next: full Lib3MF-enabled Qt reference, renderer comparison,
actual SCAD 3D providers/helper sandbox test, and writable-index Spotlight search.
