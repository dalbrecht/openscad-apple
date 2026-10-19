import Darwin
import Foundation

/// Each invocation owns a separate process and output files; inherited globals are never shared.
public protocol PreviewCompiling: Sendable {
  func compile(source: String, documentURL: URL?) async throws -> PreviewScene
}
public actor PreviewCompiler: PreviewCompiling {
  public let executable: URL
  private let timeout: Duration
  private let maximumOutputBytes: Int
  public init(
    executable: URL, timeout: Duration = .seconds(30), maximumOutputBytes: Int = 64 * 1024 * 1024
  ) {
    self.executable = executable
    self.timeout = timeout
    self.maximumOutputBytes = maximumOutputBytes
  }
  public func compile(source: String, documentURL: URL? = nil) async throws -> PreviewScene {
    guard maximumOutputBytes > 0, maximumOutputBytes <= 64 * 1024 * 1024 else {
      throw PreviewError.invalid("Invalid output quota")
    }
    guard source.utf8.count <= 4 * 1024 * 1024 else {
      throw PreviewError.invalid("Source exceeds 4 MiB")
    }
    try Task.checkCancellation()
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let input = directory.appendingPathComponent("snapshot.scad")
    try source.write(to: input, atomically: true, encoding: .utf8)
    let output = directory.appendingPathComponent("preview.json")
    let diagnostic = directory.appendingPathComponent("diagnostic.txt")
    FileManager.default.createFile(atPath: output.path, contents: nil)
    FileManager.default.createFile(atPath: diagnostic.path, contents: nil)
    let stdout = try FileHandle(forWritingTo: output)
    let stderr = try FileHandle(forWritingTo: diagnostic)
    defer {
      try? stdout.close()
      try? stderr.close()
    }
    let process = Process()
    process.executableURL = executable
    process.arguments = [input.path, (documentURL ?? input).path]
    process.standardOutput = stdout
    process.standardError = stderr
    try process.run()
    defer {
      if process.isRunning {
        _ = kill(process.processIdentifier, SIGKILL)
      }
    }
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while process.isRunning {
      try Task.checkCancellation()
      guard ContinuousClock.now < deadline else {
        throw PreviewError.invalid("Compilation exceeded 30 seconds")
      }
      try checkOutputFiles([output, diagnostic])
      try await Task.sleep(for: .milliseconds(25))
    }
    try Task.checkCancellation()
    try checkOutputFiles([output, diagnostic])
    guard process.terminationStatus == 0 else {
      let message = try String(contentsOf: diagnostic, encoding: .utf8)
      throw PreviewError.invalid(
        message.isEmpty
          ? "Preview worker failed (\(process.terminationStatus))" : String(message.prefix(8192)))
    }
    return try PreviewScene.decode(Data(contentsOf: output))
  }
  private func checkOutputFiles(_ files: [URL]) throws {
    for file in files {
      let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
      guard let size = attributes[.size] as? NSNumber,
        size.uint64Value <= UInt64(maximumOutputBytes)
      else {
        throw PreviewError.invalid("Worker output quota exceeded")
      }
    }
  }

}
