# ADR 0002 — Native editor document ownership

Status: accepted for the local editor prototype.

The initial WindowGroup editor copied text into WorkspaceStore and opened/saved it
with custom panels. That architecture did not participate in macOS dirty tracking,
close/quit decisions or document recovery, so opening another file could overwrite
unsaved text and closing a window could lose it.

Use SwiftUI DocumentGroup with a value-based SourceDocument conforming to
FileDocument. Its binding is the editor's single source of truth. The preview store
receives a copied source/path snapshot only when compiling; compiler success,
errors and cancellation never mark the document saved. Native File commands and the
responder-chain Save action own coordinated saves, save errors and window closing.
Open creates/focuses another native document rather than replacing the current draft.
The viewer retains its read-only WindowGroup and file loader.

macOS owns dirty indicators, Save/Cancel/Discard choices, autosaving and recovery
according to system document preferences. We do not install an NSWindow delegate,
replace application termination handling, or maintain a second recovery sidecar.
Recovery is based on source snapshots, not successful compilation: incomplete or
invalid SCAD can still be saved. UTF-8 and the existing 4 MiB source quota apply to
reads and writes; rejected writes throw without clearing the current edits.
FileDocument configuration adapters stay thin because their framework-created
configuration values are not publicly constructible for unit tests.

Document type registration declares org.openscad.source as imported source code
with the .scad extension. The build/run wrapper refuses to replace a running editor
before and after compilation, and fails closed when process inspection fails.
It never force-kills editor documents. Close the editor through normal macOS commands
before rebuilding. Distribution/signing policy remains unchanged.

References: [Apple DocumentGroup documentation](https://developer.apple.com/documentation/swiftui/documentgroup)
and [Apple document architecture](https://developer.apple.com/library/archive/documentation/General/Devpedia-CocoaApp-MOSX/DocArchitecture.html).
Native close/open interaction remains a manual acceptance boundary in addition to
snapshot, failed-save, preview-isolation and launcher regression tests. No claim is
made that an arbitrary immediate power loss before an OS autosave is recoverable.
