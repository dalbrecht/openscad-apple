import MetalKit
import PreviewModel

@MainActor final class SceneRenderer {
  private let pipeline: any MTLRenderPipelineState
  private let queue: any MTLCommandQueue
  private let triangles: any MTLBuffer
  private let nodes: any MTLBuffer
  private let roots: any MTLBuffer
  init(device: any MTLDevice, scene: PreviewScene) throws {
    guard let queue = device.makeCommandQueue() else {
      throw PreviewError.invalid("Metal command queue unavailable")
    }
    self.queue = queue
    guard let shaderURL = Bundle.module.url(forResource: "Preview", withExtension: "metal") else {
      throw PreviewError.invalid("Missing Metal shader")
    }
    let source = try String(contentsOf: shaderURL, encoding: .utf8)
    let library = try device.makeLibrary(source: source, options: nil)
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = library.makeFunction(name: "fullscreen")
    descriptor.fragmentFunction = library.makeFunction(name: "preview")
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    self.pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    var data: [TriangleGPU] = []
    for (index, leaf) in scene.leaves.enumerated() {
      for t in leaf.triangles {
        data.append(
          TriangleGPU(
            a: SIMD4(t[0], t[1], t[2], 0), b: SIMD4(t[3], t[4], t[5], 0),
            c: SIMD4(t[6], t[7], t[8], 0),
            color: SIMD4(leaf.color[0], leaf.color[1], leaf.color[2], leaf.color[3]),
            metadata: SIMD4(UInt32(index), 0, 0, 0)))
      }
    }
    var nodeData = scene.nodes.map { NodeGPU(op: $0.op, left: $0.left, right: $0.right, pad: 0) }
    if data.isEmpty {
      data.append(TriangleGPU(a: .zero, b: .zero, c: .zero, color: .zero, metadata: .zero))
    }
    if nodeData.isEmpty { nodeData.append(NodeGPU(op: 0, left: 0, right: -1, pad: 0)) }
    self.triangles = try Self.buffer(device: device, values: data)
    self.nodes = try Self.buffer(device: device, values: nodeData)
    let layerRoots = scene.highlights + scene.backgrounds + [-1]
    self.roots = try Self.buffer(device: device, values: layerRoots)
  }
  private static func buffer<T>(device: any MTLDevice, values: [T]) throws -> any MTLBuffer {
    try values.withUnsafeBytes { bytes in
      guard let address = bytes.baseAddress,
        let buffer = device.makeBuffer(bytes: address, length: bytes.count)
      else {
        throw PreviewError.invalid("Metal buffer allocation failed")
      }
      return buffer
    }
  }
  func encode(pass: MTLRenderPassDescriptor, camera: CameraGPU) throws -> any MTLCommandBuffer {
    guard let command = queue.makeCommandBuffer(),
      let encoder = command.makeRenderCommandEncoder(descriptor: pass)
    else {
      throw PreviewError.invalid("Metal command encoding failed")
    }
    var camera = camera
    encoder.setRenderPipelineState(pipeline)
    encoder.setFragmentBuffer(triangles, offset: 0, index: 0)
    encoder.setFragmentBuffer(nodes, offset: 0, index: 1)
    encoder.setFragmentBytes(&camera, length: MemoryLayout<CameraGPU>.stride, index: 2)
    encoder.setFragmentBuffer(roots, offset: 0, index: 3)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    encoder.endEncoding()
    return command
  }
}
