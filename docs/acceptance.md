# Milestones and acceptance

Reference inspected read-only: Dust3D README, Package.swift, native viewer store/view,
viewer README/tests, coding audit, C++ supplement, ADR 0001, canonical build/run and
Swift wrappers. Dust3D's actual current viewer also supports asynchronous baked
materials; OpenSCAD has different source semantics and that feature is not claimed.

1. Feasibility: real Qt-free parser/evaluator emits fast CSG structure; difference,
   intersection, preview variable, modules, loops, layers and errors tested.
2. Viewer: open .scad, native SwiftUI chrome, progress/cancel/errors, Metal preview,
   orbit/zoom/fit, wireframe, counts, copied snapshots, stale-result suppression.
   Basic rendered/GPU checks pass; full parity requires a larger upstream compatibility corpus.
3. Editor: separate application with shared renderer; source editing, preview,
   native document open/save, dirty tracking, close/quit protection and source recovery.
   Source highlighting, customizer, diagnostics locations, export, animation and
   comprehensive editing parity follow.

The prototype must not be described as viewer parity until the rendered checks and
remaining limitations are recorded. Signing is local/ad-hoc only; distribution,
notarization and App Store work are deferred. PRs are never auto-merged.

See docs/verification.md for observed native behavior, measured coverage and limits.

Editor document ownership and recovery: docs/adr/0002-native-document-recovery.md.
