import ImageIO
import Metal
import PreviewModel
import UniformTypeIdentifiers
import XCTest

@testable import NativeRendering

/// Reproducible feasibility evidence using the production worker and Metal encoder.
@MainActor final class FeasibilityTests: XCTestCase {
  func testWorkerScenesRenderOnMetalAndRecordTiming() async throws {
    guard let path = ProcessInfo.processInfo.environment["OPENSCAD_TEST_WORKER"],
      let device = MTLCreateSystemDefaultDevice()
    else { throw XCTSkip("Requires actual worker and Metal device") }
    let compiler = PreviewCompiler(executable: URL(fileURLWithPath: path))
    let fixtures = [
      ("difference", "difference() { cube(20,center=true); sphere(12,$fn=24); }"),
      ("curved", "sphere(12,$fn=48);"),
      (
        "layers", "cube(15,center=true); #translate([12,0,0]) sphere(8,$fn=24); %sphere(20,$fn=24);"
      ),
    ]
    var results: [[String: Any]] = []
    let workloads = fixtures.flatMap { name, source in [256, 1024].map { (name, source, $0) } }
    for (name, source, dimension) in workloads {
      let scene = try await compiler.compile(source: source, documentURL: nil)
      let renderer = try SceneRenderer(device: device, scene: scene)
      let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm, width: dimension, height: dimension, mipmapped: false)
      descriptor.storageMode = .shared
      descriptor.usage = [.renderTarget]
      let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
      let pass = MTLRenderPassDescriptor()
      pass.colorAttachments[0].texture = texture
      pass.colorAttachments[0].loadAction = .clear
      pass.colorAttachments[0].storeAction = .store
      let camera = CameraGPU(
        eye: SIMD4(scene.center + SIMD3(0, 0, scene.radius * 3.2), 0),
        right: SIMD4(1, 0, 0, 0), up: SIMD4(0, 1, 0, 0), forward: SIMD4(0, 0, -1, 0),
        counts: SIMD4(
          UInt32(scene.triangleCount), UInt32(scene.nodes.count),
          UInt32(scene.highlights.count), UInt32(scene.highlights.count + scene.backgrounds.count)),
        options: SIMD4(1, 0, 0, 0), roots: SIMD4(scene.root, -1, -1, -1))
      var milliseconds: [Double] = []
      for iteration in 0..<12 {
        let command = try renderer.encode(pass: pass, camera: camera)
        await withCheckedContinuation { continuation in
          command.addCompletedHandler { _ in continuation.resume() }
          command.commit()
        }
        XCTAssertEqual(command.status, .completed, command.error?.localizedDescription ?? "")
        if iteration > 1 { milliseconds.append((command.gpuEndTime - command.gpuStartTime) * 1000) }
      }
      XCTAssertTrue(milliseconds.allSatisfy { $0 > 0 })
      var bytes = [UInt8](repeating: 0, count: dimension * dimension * 4)
      texture.getBytes(
        &bytes, bytesPerRow: dimension * 4, from: MTLRegionMake2D(0, 0, dimension, dimension),
        mipmapLevel: 0)
      XCTAssertTrue(stride(from: 0, to: bytes.count, by: 4).contains { bytes[$0] < 100 })
      milliseconds.sort()
      results.append([
        "fixture": name, "triangles": scene.triangleCount,
        "leaves": scene.leaves.count, "gpuMedianMs": milliseconds[5],
        "gpuMaxMs": milliseconds.last ?? 0, "width": dimension, "height": dimension,
      ])
      if let output = ProcessInfo.processInfo.environment["OPENSCAD_SPIKE_OUTPUT"] {
        let url = URL(fileURLWithPath: output).appendingPathComponent("\(name)-\(dimension).png")
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        let image = try XCTUnwrap(
          CGImage(
            width: dimension, height: dimension, bitsPerComponent: 8,
            bitsPerPixel: 32, bytesPerRow: dimension * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
              .union(.byteOrder32Little), provider: provider, decode: nil,
            shouldInterpolate: false, intent: .defaultIntent))
        let destination = try XCTUnwrap(
          CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
      }
    }
    if let output = ProcessInfo.processInfo.environment["OPENSCAD_SPIKE_OUTPUT"] {
      let report: [String: Any] = [
        "device": device.name, "samplesPerScene": 10,
        "warmupFrames": 2, "results": results,
        "limitations": "256/1024px; brute-force ray CSG; opaque background; not Qt parity",
      ]
      try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        .write(to: URL(fileURLWithPath: output).appendingPathComponent("metal.json"))
    }
  }
}
