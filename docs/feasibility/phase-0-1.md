# Phase 0/1 evidence — 19 October 2026

Tracking: #4. Source ledger: `docs/parity/`. Separate core PR: dalbrecht/openscad-core#2.

## Reference inventory

549 Qt Designer actions/controls across 30 forms, plus 18 cross-cutting behavior
families. The supplemental `qt-capabilities.csv` lists 18 export enum values and
41 command-line registrations from the pinned source (`src/io/export.h` and
`src/openscad.cc`). All remain unverified; optional preprocessor branches are
retained. This is an inventory for acceptance work, not completed parity.

The full Qt desktop reference now builds and runs with OpenCSG, CGAL, Manifold,
Cairo and Lib3MF enabled. Its staged resources include shaders, locale, examples,
fonts and libraries. The Welcome window and bundled examples were inspected; the
same Boolean fixture was rendered through OpenCSG with two normalized elements.
`qt-reference.json` records configuration, dependency versions and hashes. This
reference is development-only and adds no native app dependency. Behavioral
acceptance for all ledger rows remains open; a built reference is not full parity.

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
A metadata-service-enabled probe selects Apple's RichText importer, extracts the
saved-source sentinel and finds the actual file with a directory-scoped `mdfind`
query. The latest volume status is "Indexing enabled". Earlier attempts observed a
read-only index and no match; the repeated end-to-end run now succeeds. Unit tests
cover XML and OpenStep metadata, valid JSON, real source newlines and asynchronous
indexing. Sandbox-restricted command execution is not used as platform evidence.

Decision: use system saved-source text indexing initially. No custom importer is
needed for full-text feasibility. Rich symbol metadata remains an optional future
extension; never evaluate SCAD or traverse libraries for indexing.

## Reproduction and remaining gates

See `spikes/README.md`. The probes are not shipped in the editor bundle. Production
boundary coverage and inherited core coverage remain separate. No system privacy,
index configuration or global thumbnail cache was reset. Local build artifacts
under iCloud encountered repeated filesystem timeouts; an exact core checkout in
`/private/tmp` is used for repeatable build verification.

Phases 0/1 have executable evidence; full exit gates remain incomplete. Next:
behavioral ledger acceptance, accelerated/depth-stencil renderer comparison,
actual SCAD 3D provider activation/helper sandbox tests and clean-machine checks.
Protocol v1 now rejects actual per-face materials (including evaluated render()
materials) unless an explicit uniform color override makes them representable;
per-face material parity is tracked in dalbrecht/openscad-core#3.


## Final review follow-up

Parallelism tolerance now scales by triangle area, preserving long narrow faces
as well as uniformly small models. Spotlight uses a new random sentinel per run,
so old indexed content cannot satisfy the current query. Generated source and
reports use an explicit Unicode line feed; round-trip tests verify valid JSON and
multiline source. The final local gate runs 37 Swift/Metal, 9 script and 30 core
boundary tests. Core-boundary line coverage is 97.92% (84% branches), measured
without instrumenting inherited engine code. No remote CI is configured.
