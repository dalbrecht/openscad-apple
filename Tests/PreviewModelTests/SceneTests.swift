import XCTest

@testable import PreviewModel

final class SceneTests: XCTestCase {
  func testRejectsFutureProtocol() throws {
    XCTAssertThrowsError(
      try PreviewScene.decode(
        Data(
          #"{"version":2,"leaves":[],"nodes":[],"root":-1,"highlights":[],"backgrounds":[]}"#.utf8))
    )
  }
  func testEmptySceneHasSafeBounds() throws {
    let scene = try PreviewScene.decode(
      Data(#"{"version":1,"leaves":[],"nodes":[],"root":-1,"highlights":[],"backgrounds":[]}"#.utf8)
    )
    XCTAssertEqual(scene.radius, 1)
  }
  func testRejectsInvalidNodeReference() throws {
    XCTAssertThrowsError(
      try PreviewScene.decode(
        Data(
          #"{"version":1,"leaves":[],"nodes":[{"op":0,"left":5,"right":-1}],"root":0,"highlights":[],"backgrounds":[]}"#
            .utf8)))
  }
}
extension SceneTests {
  private func sceneData(_ changes: (inout [String: Any]) -> Void) throws -> Data {
    var object: [String: Any] = [
      "version": 1,
      "leaves": [["triangles": [[0, 0, 0, 1, 0, 0, 0, 1, 0]], "color": [1, 0.5, 0, 1]]],
      "nodes": [["op": 0, "left": 0, "right": -1]], "root": 0, "highlights": [], "backgrounds": [],
    ]
    changes(&object)
    return try JSONSerialization.data(withJSONObject: object)
  }
  func testTriangleBoundsAndCopiedColor() throws {
    let scene = try PreviewScene.decode(sceneData { _ in })
    XCTAssertEqual(scene.triangleCount, 1)
    XCTAssertEqual(scene.center, SIMD3<Float>(0.5, 0.5, 0))
    XCTAssertEqual(scene.leaves[0].color, [1, 0.5, 0, 1])
  }
  func testRejectsMalformedTriangles() throws {
    for triangles in [[[0.0]], [[0, 0, 0, 1, 0, 0, 0, 1, 1e20]]] {
      XCTAssertThrowsError(
        try PreviewScene.decode(
          sceneData { $0["leaves"] = [["triangles": triangles, "color": [1, 1, 1, 1]]] }))
    }
  }
  func testRejectsBadColor() throws {
    XCTAssertThrowsError(
      try PreviewScene.decode(
        sceneData { $0["leaves"] = [["triangles": [], "color": [2, 0, 0, 1]]] }))
  }
  func testRejectsCycleAndUnknownOperatorAndInvalidRoot() throws {
    for node in [
      ["op": 1, "left": 0, "right": 0], ["op": 9, "left": 0, "right": 0],
      ["op": 1, "left": -2, "right": -1],
    ] {
      XCTAssertThrowsError(try PreviewScene.decode(sceneData { $0["nodes"] = [node] }))
    }
    XCTAssertThrowsError(try PreviewScene.decode(sceneData { $0["root"] = 3 }))
  }
  func testRejectsLeafAndNodeQuotas() throws {
    XCTAssertThrowsError(
      try PreviewScene.decode(
        sceneData {
          $0["leaves"] = Array(repeating: ["triangles": [], "color": [1, 1, 1, 1]], count: 65)
        }))
    XCTAssertThrowsError(
      try PreviewScene.decode(
        sceneData { $0["nodes"] = Array(repeating: ["op": 0, "left": 0, "right": -1], count: 128) })
    )
  }
}
extension SceneTests {
  func testRejectsLeafWithArbitraryRightReference() throws {
    XCTAssertThrowsError(
      try PreviewScene.decode(sceneData { $0["nodes"] = [["op": 0, "left": 0, "right": 999]] }))
  }
  func testRejectsUnboundedLayerRoots() throws {
    XCTAssertThrowsError(
      try PreviewScene.decode(sceneData { $0["highlights"] = Array(repeating: 0, count: 128) }))
  }
}
extension SceneTests {
  func testDiagnosticAndPayloadQuotasAreEnforcedBeforeRendering() throws {
    XCTAssertThrowsError(
      try PreviewScene.decode(
        sceneData { $0["diagnostics"] = Array(repeating: "warning", count: 129) }))
    XCTAssertThrowsError(
      try PreviewScene.decode(
        sceneData { $0["diagnostics"] = [String(repeating: "x", count: 8193)] }))
    XCTAssertThrowsError(try PreviewScene.decode(Data(count: 64 * 1024 * 1024 + 1)))
  }
}
