import Foundation
import simd

public enum PreviewError: Error, LocalizedError, Sendable {
  case invalid(String)
  public var errorDescription: String? {
    if case .invalid(let text) = self { return text }
    return nil
  }
}
public struct PreviewLeaf: Codable, Sendable {
  public let triangles: [[Float]]
  public let color: [Float]
}
public struct PreviewNode: Codable, Sendable {
  public let op: Int32
  public let left: Int32
  public let right: Int32
}
/// Owned immutable snapshot. All JSON buffers are copied before the worker is reaped.
private struct ScenePayload: Decodable {
  let version: Int
  let leaves: [PreviewLeaf]
  let nodes: [PreviewNode]
  let root: Int32
  let highlights: [Int32]
  let backgrounds: [Int32]
  let diagnostics: [String]?
}
public struct PreviewScene: Sendable {
  public let version: Int
  public let leaves: [PreviewLeaf]
  public let nodes: [PreviewNode]
  public let root: Int32
  public let highlights: [Int32]
  public let backgrounds: [Int32]
  public let diagnostics: [String]
  public static func decode(_ data: Data) throws -> Self {
    guard data.count <= 64 * 1024 * 1024 else {
      throw PreviewError.invalid("Preview exceeds 64 MiB")
    }
    let scene = try JSONDecoder().decode(ScenePayload.self, from: data)
    guard scene.version == 1, scene.leaves.count <= 64, scene.nodes.count <= 127,
      scene.highlights.count + scene.backgrounds.count <= 127
    else {
      throw PreviewError.invalid("Unsupported preview version or resource limit")
    }
    let diagnostics = scene.diagnostics ?? []
    guard diagnostics.count <= 128, diagnostics.allSatisfy({ $0.utf8.count <= 8192 }) else {
      throw PreviewError.invalid("Diagnostic quota exceeded")
    }
    var count = 0
    for leaf in scene.leaves {
      guard leaf.color.count == 4, leaf.color.allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= 1 })
      else {
        throw PreviewError.invalid("Invalid preview color")
      }
      for triangle in leaf.triangles {
        count += 1
        guard count <= 100_000, triangle.count == 9,
          triangle.allSatisfy({ $0.isFinite && abs($0) <= 1e12 })
        else {
          throw PreviewError.invalid("Invalid preview triangle or quota exceeded")
        }
      }
    }
    for (index, node) in scene.nodes.enumerated() {
      guard (0...3).contains(node.op) else { throw PreviewError.invalid("Unknown CSG operation") }
      if node.op == 0 {
        guard node.left >= 0, node.left < scene.leaves.count, node.right == -1 else {
          throw PreviewError.invalid("Invalid leaf")
        }
      } else {
        guard node.left >= -1, node.right >= -1, node.left < index, node.right < index else {
          throw PreviewError.invalid("Invalid CSG topology")
        }
      }
    }
    for root in [scene.root] + scene.highlights + scene.backgrounds {
      guard root >= -1, root < scene.nodes.count else { throw PreviewError.invalid("Invalid root") }
    }
    return Self(
      version: scene.version, leaves: scene.leaves, nodes: scene.nodes, root: scene.root,
      highlights: scene.highlights, backgrounds: scene.backgrounds, diagnostics: diagnostics)
  }
  public var triangleCount: Int { leaves.reduce(0) { $0 + $1.triangles.count } }
  public var bounds: (SIMD3<Float>, SIMD3<Float>) {
    var minimum = SIMD3<Float>(repeating: .infinity)
    var maximum = SIMD3<Float>(repeating: -.infinity)
    for leaf in leaves {
      for triangle in leaf.triangles {
        for i in stride(from: 0, to: 9, by: 3) {
          let point = SIMD3(triangle[i], triangle[i + 1], triangle[i + 2])
          minimum = simd_min(minimum, point)
          maximum = simd_max(maximum, point)
        }
      }
    }
    return triangleCount == 0 ? (SIMD3(repeating: -1), SIMD3(repeating: 1)) : (minimum, maximum)
  }
  public var center: SIMD3<Float> { (bounds.0 + bounds.1) * 0.5 }
  public var radius: Float {
    triangleCount == 0 ? 1 : max(simd_length(bounds.1 - bounds.0) * 0.5, 0.001)
  }
}
