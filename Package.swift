// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "OpenSCADApple", platforms: [.macOS(.v14)],
  products: [
    .executable(name: "OpenSCADViewer", targets: ["OpenSCADViewer"]),
    .executable(name: "OpenSCADEditor", targets: ["OpenSCADEditor"]),
  ],
  targets: [
    .target(name: "PreviewModel"),
    .target(
      name: "NativeRendering", dependencies: ["PreviewModel"], resources: [.copy("Preview.metal")]),
    .executableTarget(name: "OpenSCADViewer", dependencies: ["NativeRendering", "PreviewModel"]),
    .executableTarget(name: "OpenSCADEditor", dependencies: ["NativeRendering", "PreviewModel"]),
    .testTarget(name: "PreviewModelTests", dependencies: ["PreviewModel"]),
    .testTarget(name: "NativeRenderingTests", dependencies: ["NativeRendering", "PreviewModel"]),
  ])
