import AppKit
import NativeRendering
import SwiftUI

@main struct OpenSCADEditorApp: App {
  init() {
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }
  var body: some Scene { WindowGroup { WorkspaceView(editor: true) } }
}
