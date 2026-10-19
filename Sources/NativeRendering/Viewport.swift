import AppKit
import MetalKit
import PreviewModel
import SwiftUI
import simd

struct TriangleGPU {
  var a, b, c, color: SIMD4<Float>
  var metadata: SIMD4<UInt32>
}
struct NodeGPU { var op, left, right, pad: Int32 }
struct CameraGPU {
  var eye, right, up, forward: SIMD4<Float>
  var counts: SIMD4<UInt32>
  var options: SIMD4<Float>
  var roots: SIMD4<Int32>
}
public struct PreviewViewport: NSViewRepresentable {
  public let scene: PreviewScene
  public let wireframe: Bool
  public let reset: Int
  public init(scene: PreviewScene, wireframe: Bool, reset: Int) {
    self.scene = scene
    self.wireframe = wireframe
    self.reset = reset
  }
  public func makeNSView(context: Context) -> OrbitView { OrbitView(scene: scene) }
  public func updateNSView(_ view: OrbitView, context: Context) {
    view.wireframe = wireframe
    if view.resetRevision != reset {
      view.resetRevision = reset
      view.yaw = 0.7
      view.pitch = 0.5
      view.zoom = 1
    }
    view.needsDisplay = true
  }
}
@MainActor
public final class OrbitView: MTKView {
  fileprivate(set) var yaw: Float = 0.7, pitch: Float = 0.5, zoom: Float = 1
  fileprivate var wireframe = false, resetRevision = 0
  private let scene: PreviewScene
  private var lastDragLocation: CGPoint?
  private var renderer: SceneRenderer?
  private var failure: String?
  init(scene: PreviewScene) {
    self.scene = scene
    super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
    colorPixelFormat = .bgra8Unorm
    isPaused = true
    enableSetNeedsDisplay = true
    setAccessibilityLabel("OpenSCAD fast CSG preview. Drag to orbit, scroll to zoom.")
    do {
      guard let device else { throw PreviewError.invalid("Metal unavailable") }
      renderer = try SceneRenderer(device: device, scene: scene)
    } catch {
      failure = error.localizedDescription
      let label = NSTextField(
        wrappingLabelWithString: "Metal preview failed: " + error.localizedDescription)
      label.frame = NSRect(x: 20, y: 20, width: 600, height: 120)
      label.autoresizingMask = [.width, .maxYMargin]
      addSubview(label)
    }
  }
  @available(*, unavailable)
  required init(coder: NSCoder) { fatalError("Use init(scene:); storyboards are unsupported") }
  public override var acceptsFirstResponder: Bool { true }
  public override func mouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    lastDragLocation = event.locationInWindow
  }
  public override func mouseDragged(with event: NSEvent) {
    let point = event.locationInWindow
    if let previous = lastDragLocation {
      yaw += Float(point.x - previous.x) * 0.01
      pitch = min(1.5, max(-1.5, pitch + Float(previous.y - point.y) * 0.01))
    }
    lastDragLocation = point
    needsDisplay = true
  }
  public override func mouseUp(with event: NSEvent) { lastDragLocation = nil }
  public override func scrollWheel(with event: NSEvent) {
    zoom = min(20, max(0.1, zoom * exp(Float(event.scrollingDeltaY) * 0.01)))
    needsDisplay = true
  }
  public override func draw(_ dirtyRect: NSRect) {
    guard let renderer, let pass = currentRenderPassDescriptor, let drawable = currentDrawable
    else { return }
    let offset = SIMD3(cos(pitch) * cos(yaw), cos(pitch) * sin(yaw), sin(pitch))
    let forward = -offset
    let right = simd_normalize(simd_cross(forward, SIMD3(0, 0, 1)))
    let up = simd_cross(right, forward)
    let aspect = Float(drawableSize.width / max(drawableSize.height, 1))
    let eye =
      scene.center + offset
      * CameraFraming.distance(
        radius: scene.radius, zoom: zoom, aspect: aspect)
    let camera = CameraGPU(
      eye: SIMD4(eye, 0), right: SIMD4(right, 0), up: SIMD4(up, 0), forward: SIMD4(forward, 0),
      counts: SIMD4(
        UInt32(scene.triangleCount), UInt32(scene.nodes.count), UInt32(scene.highlights.count),
        UInt32(scene.highlights.count + scene.backgrounds.count)),
      options: SIMD4(
        aspect, wireframe ? 1 : 0, 0, 0),
      roots: SIMD4(scene.root, -1, -1, -1))
    do {
      let command = try renderer.encode(pass: pass, camera: camera)
      command.present(drawable)
      command.commit()
    } catch { NSLog("Metal encoding: %@", error.localizedDescription) }
  }
}
