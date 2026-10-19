import AppKit
import QuickLookThumbnailing

/// Deliberate fallback icon; geometry rendering is evaluated separately.
@objc(ThumbnailProvider)
final class ThumbnailProvider: QLThumbnailProvider {
  override func provideThumbnail(
    for request: QLFileThumbnailRequest,
    _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
  ) {
    let reply = QLThumbnailReply(
      contextSize: NSSize(width: 256, height: 256),
      currentContextDrawing: {
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 256, height: 256)).fill()
        ("SCAD" as NSString).draw(
          at: NSPoint(x: 30, y: 110), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 48)])
        return true
      })
    handler(reply, nil)
  }
}
