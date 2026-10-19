import AppKit
import NativeRendering
import SwiftUI

@main struct OpenSCADViewerApp: App {
  init() {
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }
  var body: some Scene { WindowGroup { WorkspaceView() } }
}
