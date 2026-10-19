# Qt parity ledger — phase 0

Tracking: #4. Reference: upstream OpenSCAD `7bbf603833e167712e9cc7ae3432001dc26817d0`.
Historical first SDK prototype: `51f9cfe870f2599a1fd0626159279ef5101ba609` in the separate
`dalbrecht/openscad-core` repository. Native targets use HEADLESS and NULLGL.

`qt-controls.csv` inventories 549 actions and interactive controls from all 30
Qt Designer forms in the pinned source. Generate it with:

```
python3 script/parity_ledger.py work/openscad-core work/qt-controls.csv
```

The generator deliberately emits **unverified** rows. Preserve accepted behavior,
issue, fixture and evidence columns when reconciling a future regeneration; never
regenerate over a maintained ledger. Identifiers are form-relative path plus Qt
object name. Compare IDs before updating. Labels and keyboard shortcuts are
reference metadata, not a specification of semantics. Disabled, optional and
platform-specific controls remain visible.

`behaviors.csv` complements those rows with dynamic and cross-cutting behavior.
Every row is presently owned by umbrella issue #4; split implementation issues
before scheduling each subsystem. Acceptance requires a concrete fixture and
recorded reference/native result, including errors and file mutations. Empty
acceptance evidence means incomplete, regardless of menu availability.

The inventory source is the exact core checkout recorded in `reference-manifest.json`;
the current runtime worker pin is maintained separately in `core-revision.txt`.

## Reference profile

Freeze normal desktop capabilities: CGAL and Manifold, fast OpenCSG preview,
STL/OFF/AMF/3MF and 2D/vector/image exports, fonts, Customizer and animation.
Record enabled build flags, dependency versions, fonts, locale and scale alongside
reference screenshots. Python, AI, input devices and print services require
separate optional profiles; they are not silently excluded from scope.

**Reference binary not yet frozen:** the repository contains the pinned Qt source,
but the currently built worker is headless and does not establish Qt runtime
behavior. No reference screenshot or full parity acceptance is claimed. Building
the full desktop profile and recording its dependency manifest remains a phase 0
exit gate. Do not substitute the prototype's reduced dependency profile.

## Phase gates

- Phase 0: reconcile source inventory with a running pinned Qt reference; map all
  dynamic commands and backend formats; attach behavioral fixtures and acceptance
  evidence. The source ledger is the starting baseline, not completed parity.
- Phase 1: record actual GPU timings and images, Finder extension activation with
  the main app stopped, and Spotlight metadata plus search results. A successful
  build alone is insufficient. Explicitly record sandbox/signing/registration
  blockers and fallback behavior.

Architecture and implementation sequence: [native port plan](../native-port-plan.md).

## Reproduction evidence

`reference-manifest.json` records all 30 form hashes, individual row counts, the
GUI Git tree, and excluded built-in container/display classes. Regenerating from
the exact core pin was byte-compared against the committed CSV. Designer-declared
custom widgets are included even when their inheritance is not a standard input
class; checkable groups are also included, so mouse configuration, viewport and custom search controls remain visible.
The regression covers custom controls and invalid/empty checkout paths; invalid
input fails before the existing output is opened.
