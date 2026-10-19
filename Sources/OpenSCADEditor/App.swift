import AppKit
import NativeRendering
import SwiftUI

@main struct OpenSCADEditorApp: App {
  init() {
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }
  var body: some Scene {
    DocumentGroup(newDocument: SourceDocument()) { file in
      WorkspaceView(document: file.$document, url: file.fileURL)
    }
  }
}
