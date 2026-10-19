import AppKit
import PreviewModel
import XCTest

@testable import NativeRendering

@MainActor final class CameraInteractionTests: XCTestCase {
  func testDragUsesWindowLocationsWhenSyntheticDeltaIsZero() throws {
    let scene = try PreviewScene.decode(
      Data(#"{"version":1,"leaves":[],"nodes":[],"root":-1,"highlights":[],"backgrounds":[]}"#.utf8)
    )
    let view = OrbitView(scene: scene)
    let down = try XCTUnwrap(
      NSEvent.mouseEvent(
        with: .leftMouseDown, location: CGPoint(x: 10, y: 10), modifierFlags: [], timestamp: 0,
        windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
    let drag = try XCTUnwrap(
      NSEvent.mouseEvent(
        with: .leftMouseDragged, location: CGPoint(x: 60, y: 30), modifierFlags: [], timestamp: 1,
        windowNumber: 0, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
    let yaw = view.yaw
    view.mouseDown(with: down)
    view.mouseDragged(with: drag)
    XCTAssertNotEqual(view.yaw, yaw)
  }
}
