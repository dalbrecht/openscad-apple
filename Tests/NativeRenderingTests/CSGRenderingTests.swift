import Metal
import PreviewModel
import XCTest

@testable import NativeRendering

@MainActor final class CSGRenderingTests: XCTestCase {
  private func cube(_ size: Float, depth: Float = 1) -> [[Float]] {
    let vertices: [[Float]] = [
      [-size, -size, -depth], [size, -size, -depth], [size, size, -depth], [-size, size, -depth],
      [-size, -size, depth], [size, -size, depth], [size, size, depth], [-size, size, depth],
    ]
    let faces = [
      [0, 2, 1], [0, 3, 2], [4, 5, 6], [4, 6, 7], [0, 1, 5], [0, 5, 4], [1, 2, 6], [1, 6, 5],
      [2, 3, 7], [2, 7, 6], [3, 0, 4], [3, 4, 7],
    ]
    return faces.map { $0.flatMap { vertices[$0] } }
  }
  private func render(operation: Int, wireframe: Bool = false, eyeDepth: Float = 5) throws
    -> [UInt8]
  {
    guard let device = MTLCreateSystemDefaultDevice() else { throw XCTSkip("Metal unavailable") }
    let object: [String: Any] = [
      "version": 1,
      "leaves": [
        ["triangles": cube(1), "color": [1, 0.8, 0.1, 1]],
        ["triangles": cube(0.45, depth: 2), "color": [1, 0.8, 0.1, 1]],
      ],
      "nodes": [
        ["op": 0, "left": 0, "right": -1], ["op": 0, "left": 1, "right": -1],
        ["op": operation, "left": 0, "right": 1],
      ], "root": 2, "highlights": [], "backgrounds": [],
    ]
    let scene = try PreviewScene.decode(JSONSerialization.data(withJSONObject: object))
    let renderer = try SceneRenderer(device: device, scene: scene)
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm, width: 64, height: 64, mipmapped: false)
    descriptor.storageMode = .shared
    descriptor.usage = [.renderTarget]
    let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = texture
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].storeAction = .store
    let camera = CameraGPU(
      eye: SIMD4(0, 0, eyeDepth, 0), right: SIMD4(1, 0, 0, 0), up: SIMD4(0, 1, 0, 0),
      forward: SIMD4(0, 0, -1, 0),
      counts: SIMD4(UInt32(scene.triangleCount), UInt32(scene.nodes.count), 0, 0),
      options: SIMD4(1, wireframe ? 1 : 0, 0, 0), roots: SIMD4(scene.root, -1, -1, -1))
    let command = try renderer.encode(pass: pass, camera: camera)
    command.commit()
    command.waitUntilCompleted()
    XCTAssertEqual(command.status, .completed, command.error?.localizedDescription ?? "")
    var bytes = [UInt8](repeating: 0, count: 64 * 64 * 4)
    texture.getBytes(
      &bytes, bytesPerRow: 64 * 4, from: MTLRegionMake2D(0, 0, 64, 64), mipmapLevel: 0)
    return bytes
  }
  func testDifferenceShowsHoleWhileUnionIsSolid() throws {
    let difference = try render(operation: 3)
    let union = try render(operation: 1)
    let center = (32 * 64 + 32) * 4
    XCTAssertGreaterThan(difference[center], 220)  // background blue
    XCTAssertLessThan(union[center], 80)  // yellow solid has little blue
    let wall = (32 * 64 + 44) * 4
    XCTAssertLessThan(difference[wall], 80)
  }
  func testIntersectionRemainsVisibleFromInsideOneOperand() throws {
    let intersection = try render(operation: 2, eyeDepth: 1.5)
    XCTAssertLessThan(intersection[(32 * 64 + 32) * 4], 80)
  }
  func testIntersectionAndWireframeRenderOnGPU() throws {
    let intersection = try render(operation: 2)
    XCTAssertLessThan(intersection[(32 * 64 + 32) * 4], 80)
    XCTAssertGreaterThan(intersection[(32 * 64 + 44) * 4], 220)
    XCTAssertNotEqual(try render(operation: 1, wireframe: true), try render(operation: 1))
  }
}
