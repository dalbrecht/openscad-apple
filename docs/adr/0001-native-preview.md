# ADR 0001 — Native preview boundary

Status: accepted for the working local prototype; full parity remains incomplete.

Upstream OpenSCAD at 7bbf603833e167712e9cc7ae3432001dc26817d0 already supports
HEADLESS and NULLGL builds. The Qt-free OpenSCADLibInternal includes the real
Flex/Bison parser, context/evaluation system, GeometryEvaluator and CSGTreeEvaluator.
The latter emits leaf polysets, transforms, colors and a Boolean tree. OpenCSG's
OpenGL renderer is a separate implementation, not part of this native boundary.

A portable CMake worker links the inherited library and accepts one source snapshot
and optional logical document path. It uses preview=true, resolves includes relative
to the logical path, evaluates modules/functions with the real engine, tessellates
individual leaves, and emits protocol-v1 JSON. Boolean union/intersection/difference
remain operations; render(), hull(), extrusion and other geometry-producing nodes
retain upstream evaluator behavior. Background/highlight roots are separate.
No final STL export is used as a replacement for fast preview.

The worker is the first embedding API. A stable in-process C ABI is deferred until
this scene contract is exercised; duplicating upstream ownership into Swift now
would add risk without improving fault isolation. JSON copies all buffers; no native
pointer escapes the process. Each request has private globals, caches and files.
The Swift actor polls process completion off the main actor, enforces a 30-second
wall deadline and terminates its own child on cancellation. A worker crash is a
request error. This deliberately sacrifices cache reuse for isolation and reliable
cancellation. It is not an OS sandbox: includes/imports retain local filesystem access.

Limits: 4 MiB source, 64 leaves, 127 postorder nodes, 100,000 leaf triangles,
64 MiB response. Geometry workspace is not hard-memory-limited. A single Metal ray
supports 128 triangle events; overflow appears magenta. That is an explicit prototype
limit, not a claim of OpenCSG equivalence for arbitrary documents.

Metal intersects source triangles, sorts ray events, computes per-leaf occupancy,
and evaluates the Boolean tree at boundaries. This preserves fast-preview structure
without producing a final Boolean mesh. Coplanar/nonmanifold/numerically degenerate
inputs and layer transparency require more acceptance work. Colors and basic lighting
are present; background is currently opaque. Wireframe shows source-triangle edges.

SwiftPM declares macOS 14+, Swift 6 application and rendering targets. CMake builds
the portable dependency because upstream uses system geometry/text libraries and
generated parsers. core-revision.txt pins the exact core commit; the local override
supports iteration. Homebrew dependency paths make this first launcher Apple-Silicon
specific. The core itself retains upstream Linux/Windows build logic.
