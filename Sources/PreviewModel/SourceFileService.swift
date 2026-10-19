import Foundation

/// Bounded UTF-8 snapshots and atomic saves, isolated from presentation and compilation.
public actor SourceFileService {
  public init() {}
  public func load(url: URL) throws -> String {
    try Task.checkCancellation()
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    let bytes = try handle.read(upToCount: 4 * 1024 * 1024 + 1) ?? Data()
    guard bytes.count <= 4 * 1024 * 1024 else { throw PreviewError.invalid("Source exceeds 4 MiB") }
    guard let source = String(data: bytes, encoding: .utf8) else {
      throw PreviewError.invalid("Source is not UTF-8")
    }
    try Task.checkCancellation()
    return source
  }
  public func save(source: String, to url: URL) throws {
    try Task.checkCancellation()
    guard source.utf8.count <= 4 * 1024 * 1024 else {
      throw PreviewError.invalid("Source exceeds 4 MiB")
    }
    try source.write(to: url, atomically: true, encoding: .utf8)
  }
}
