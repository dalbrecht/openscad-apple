import AppKit
import Observation
import PreviewModel
import SwiftUI
import UniformTypeIdentifiers

@MainActor @Observable
public final class WorkspaceStore {
  public var source =
    "// OpenSCAD fast preview\n$fn = 48;\ndifference() {\n  cube([24,24,14], center=true);\n  cylinder(h=20, r=7, center=true);\n}\n"
  public private(set) var scene: PreviewScene?
  public private(set) var busy = false
  public var error: String?
  public private(set) var name = "Untitled.scad"
  public private(set) var url: URL?
  public private(set) var sceneRevision = 0
  private let compiler: any PreviewCompiling
  private let files = SourceFileService()
  private var request = 0
  private var task: Task<Void, Never>?
  public init(compiler: (any PreviewCompiling)? = nil) {
    self.compiler =
      compiler
      ?? PreviewCompiler(
        executable: Bundle.main.bundleURL.appendingPathComponent(
          "Contents/MacOS/openscad-preview-worker"))
  }
  @discardableResult public func preview() -> Task<Void, Never> {
    task?.cancel()
    request += 1
    let revision = request
    let snapshot = source
    let document = url
    busy = true
    error = nil
    let pending = Task { [weak self, compiler] in
      do {
        let result = try await compiler.compile(
          source: snapshot, documentURL: document)
        guard let self, !Task.isCancelled, request == revision else { return }
        scene = result
        sceneRevision += 1
        busy = false
      } catch {
        guard let self, !Task.isCancelled, request == revision else { return }
        self.error = error.localizedDescription
        busy = false
      }
    }
    task = pending
    return pending
  }
  public func cancel() {
    task?.cancel()
    request += 1
    busy = false
  }
  public func open() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.init(filenameExtension: "scad") ?? .plainText]
    guard panel.runModal() == .OK, let selected = panel.url else { return }
    open(selected)
  }
  public func open(_ selected: URL) {
    task?.cancel()
    request += 1
    let revision = request
    busy = true
    error = nil
    task = Task { [weak self, files] in
      do {
        let text = try await files.load(url: selected)
        guard let self, !Task.isCancelled, request == revision else { return }
        source = text
        url = selected
        name = selected.lastPathComponent
        task = nil
        preview()
      } catch {
        guard let self, !Task.isCancelled, request == revision else { return }
        self.error = error.localizedDescription
        busy = false
      }
    }
  }
  public func save() {
    var destination = url
    if destination == nil {
      let panel = NSSavePanel()
      panel.nameFieldStringValue = name
      guard panel.runModal() == .OK else { return }
      destination = panel.url
    }
    guard let destination else { return }
    let snapshot = source
    let savedRequest = request
    Task { [weak self, files] in
      do {
        try await files.save(source: snapshot, to: destination)
        guard let self, request == savedRequest else { return }
        url = destination
        name = destination.lastPathComponent
      } catch { self?.error = error.localizedDescription }
    }
  }
}
public struct WorkspaceView: View {
  @State private var store = WorkspaceStore()
  @State private var wireframe = false
  @State private var reset = 0
  private let editor: Bool
  public init(editor: Bool = false) { self.editor = editor }
  public var body: some View {
    VStack(spacing: 0) {
      if let message = store.error {
        HStack(alignment: .top) {
          Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
          Text(message).textSelection(.enabled)
          Spacer()
          Button("Dismiss") { store.error = nil }
        }.padding()
        Divider()
      }
      HSplitView {
        if editor {
          TextEditor(text: $store.source).font(.system(.body, design: .monospaced))
            .frame(minWidth: 280, idealWidth: 380).accessibilityLabel("OpenSCAD source editor")
        }
        ZStack {
          if let scene = store.scene {
            if scene.triangleCount > 0 {
              PreviewViewport(scene: scene, wireframe: wireframe, reset: reset)
                .id(store.sceneRevision)
            } else {
              ContentUnavailableView("Empty preview", systemImage: "cube")
            }
          } else {
            ContentUnavailableView(
              "Open an OpenSCAD model", systemImage: "cube.transparent",
              description: Text("Choose a .scad file to inspect its fast CSG preview."))
          }
          if store.busy {
            VStack {
              ProgressView("Compiling preview…")
              Button("Cancel") { store.cancel() }
            }
            .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
          }
        }.frame(minWidth: 500, minHeight: 400)
      }
      if let scene = store.scene, !scene.diagnostics.isEmpty {
        Text(scene.diagnostics.joined(separator: "\n"))
          .font(.caption).foregroundStyle(.secondary).textSelection(.enabled).padding(10)
      }
      Divider()
      HStack {
        Text(
          store.scene.map {
            "\($0.leaves.count) leaves · \($0.triangleCount) source triangles · Fast CSG preview"
          } ?? "Native SwiftUI · Metal")
        Spacer()
        Text("Drag to orbit · Scroll to zoom")
      }.font(.caption).foregroundStyle(.secondary).padding(10)
    }
    .frame(minWidth: editor ? 1000 : 700, minHeight: 500)
    .navigationTitle("\(editor ? "OpenSCAD Editor" : "OpenSCAD Viewer") — \(store.name)")
    .toolbar {
      Button {
        store.open()
      } label: {
        Label("Open", systemImage: "folder")
      }.keyboardShortcut("o")
      if editor {
        Button {
          store.save()
        } label: {
          Label("Save", systemImage: "square.and.arrow.down")
        }.keyboardShortcut("s")
      }
      Button {
        store.preview()
      } label: {
        Label("Preview", systemImage: "play")
      }.keyboardShortcut("r")
      Toggle(isOn: $wireframe) { Label("Wireframe", systemImage: "square.3.layers.3d") }
      Button {
        reset += 1
      } label: {
        Label("Fit Model", systemImage: "arrow.up.left.and.arrow.down.right")
      }
    }
    .task { if store.scene == nil && !store.busy { store.preview() } }
    .onOpenURL { store.open($0) }
    .onDisappear { store.cancel() }
  }
}
