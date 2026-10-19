import Foundation
import PreviewModel
import XCTest

@testable import NativeRendering

private struct FixtureCompiler: PreviewCompiling {
  func compile(source: String, documentURL: URL?) async throws -> PreviewScene {
    if source == "bad" { throw PreviewError.invalid("original parse cause") }
    return try PreviewScene.decode(
      Data(#"{"version":1,"leaves":[],"nodes":[],"root":-1,"highlights":[],"backgrounds":[]}"#.utf8)
    )
  }
}
@MainActor final class WorkspaceTests: XCTestCase {
  func testNewResultChangesViewportIdentityAndFailureRetainsLastScene() async {
    let store = WorkspaceStore(compiler: FixtureCompiler())
    await store.preview().value
    let firstRevision = store.sceneRevision
    await store.preview().value
    XCTAssertGreaterThan(store.sceneRevision, firstRevision)
    let lastRevision = store.sceneRevision
    store.source = "bad"
    await store.preview().value
    XCTAssertEqual(store.sceneRevision, lastRevision)
    XCTAssertNotNil(store.scene)
    XCTAssertEqual(store.error, "original parse cause")
    XCTAssertFalse(store.busy)
  }
}
private actor DeferredCompiler: PreviewCompiling {
  private var requests: [String: CheckedContinuation<PreviewScene, any Error>] = [:]
  func compile(source: String, documentURL: URL?) async throws -> PreviewScene {
    try await withCheckedThrowingContinuation { requests[source] = $0 }
  }
  func isPending(_ source: String) -> Bool { requests[source] != nil }
  func finish(_ source: String) throws {
    let object: [String: Any] = [
      "version": 1, "leaves": [], "nodes": [], "root": -1, "highlights": [], "backgrounds": [],
      "diagnostics": [source],
    ]
    let scene = try PreviewScene.decode(JSONSerialization.data(withJSONObject: object))
    requests.removeValue(forKey: source)?.resume(returning: scene)
  }
}
extension WorkspaceTests {
  func testSupersededAndClosedRequestsCannotPublishLateResults() async throws {
    let compiler = DeferredCompiler()
    let store = WorkspaceStore(compiler: compiler)
    store.source = "old"
    let old = store.preview()
    for _ in 0..<100 where !(await compiler.isPending("old")) {
      try await Task.sleep(for: .milliseconds(1))
    }
    let oldStarted = await compiler.isPending("old")
    XCTAssertTrue(oldStarted)
    store.source = "new"
    let new = store.preview()
    for _ in 0..<100 where !(await compiler.isPending("new")) {
      try await Task.sleep(for: .milliseconds(1))
    }
    try await compiler.finish("new")
    await new.value
    try await compiler.finish("old")
    await old.value
    XCTAssertEqual(store.scene?.diagnostics, ["new"])
    XCTAssertEqual(store.sceneRevision, 1)
    store.source = "closed"
    let closed = store.preview()
    for _ in 0..<100 where !(await compiler.isPending("closed")) {
      try await Task.sleep(for: .milliseconds(1))
    }
    store.cancel()
    try await compiler.finish("closed")
    await closed.value
    XCTAssertEqual(store.scene?.diagnostics, ["new"])
    XCTAssertFalse(store.busy)
  }
}
private actor RecordingCompiler: PreviewCompiling {
  private var input: (String, URL?)?
  func compile(source: String, documentURL: URL?) async throws -> PreviewScene {
    input = (source, documentURL)
    return try PreviewScene.decode(
      Data(#"{"version":1,"leaves":[],"nodes":[],"root":-1,"highlights":[],"backgrounds":[]}"#.utf8)
    )
  }
  func lastInput() -> (String, URL?)? { input }
}
extension WorkspaceTests {
  func testDocumentPreviewUsesCurrentUnsavedTextAndLogicalSaveLocation() async {
    let compiler = RecordingCompiler()
    let store = WorkspaceStore(compiler: compiler)
    let location = URL(fileURLWithPath: "/tmp/renamed/model.scad")
    store.updateDocument(source: "// not yet saved\ncube(3);", url: location)
    await store.preview().value
    let input = await compiler.lastInput()
    XCTAssertEqual(input?.0, "// not yet saved\ncube(3);")
    XCTAssertEqual(input?.1, location)
    XCTAssertEqual(store.name, "model.scad")
    XCTAssertNil(store.error)
  }
}
