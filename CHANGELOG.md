# Changelog

## Unreleased
- Fit models in narrow preview panes and fail closed during linkage inspection.
- Protect unsaved editor documents with native document windows, save/close handling, and source recovery snapshots.
- Refuse rebuilding a running editor to prevent force-quitting unsaved work.
- Add a Qt-free OpenSCAD fast-preview worker integration.
- Add native SwiftUI/Metal viewer and separate source editor prototypes.

### Feasibility work
- Added a pinned Qt source inventory and executable Metal, Finder and Spotlight probes.
- Kept test worker selection consistent with the explicit core checkout override.
- Preserve Metal visibility for small models and record successful saved-source Spotlight search.
- Reject unrepresentable per-face materials explicitly; core material parity remains tracked in [core issue #3](https://github.com/dalbrecht/openscad-core/issues/3).
