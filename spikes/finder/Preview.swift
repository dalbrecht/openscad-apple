import AppKit
import QuickLookUI

/// Feasibility provider: bounded saved-source fallback, not a geometry preview.
@objc(PreviewController)
final class PreviewController: NSViewController, @MainActor QLPreviewingController {
  override func loadView() { view = NSTextView(frame: NSRect(x: 0, y: 0, width: 640, height: 480)) }
  func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
    do {
      let file = try FileHandle(forReadingFrom: url)
      defer { try? file.close() }
      let data = try file.read(upToCount: 65_537) ?? Data()
      guard data.count <= 65_536, let source = String(data: data, encoding: .utf8) else {
        throw CocoaError(.fileReadTooLarge)
      }
      (view as? NSTextView)?.string = "OpenSCAD Finder feasibility fallback\n" + source
      (view as? NSTextView)?.isEditable = false
      handler(nil)
    } catch { handler(error) }
  }
}
