import Foundation
import XCTest

@testable import PreviewModel

@MainActor final class SourceFileTests: XCTestCase {
  func testRoundTripPreservesSourceText() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("model.scad")
    let service = SourceFileService()
    let source = "// π\ntranslate([1,2,3]) cube(4);\n"
    try await service.save(source: source, to: url)
    let loaded = try await service.load(url: url)
    XCTAssertEqual(loaded, source)
  }
  func testMalformedUTF8AndSourceLimitAreRejected() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    try Data([255, 254, 253]).write(to: url)
    do {
      _ = try await SourceFileService().load(url: url)
      XCTFail()
    } catch { XCTAssertTrue(error.localizedDescription.contains("UTF-8")) }
    do {
      try await SourceFileService().save(
        source: String(repeating: " ", count: 4 * 1024 * 1024 + 1), to: url)
      XCTFail()
    } catch { XCTAssertTrue(error.localizedDescription.contains("4 MiB")) }
  }
}
extension SourceFileTests {
  func testOversizedSnapshotAndMissingFileKeepBoundaryErrors() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    try Data(count: 4 * 1024 * 1024 + 1).write(to: url)
    do {
      _ = try await SourceFileService().load(url: url)
      XCTFail()
    } catch { XCTAssertTrue(error.localizedDescription.contains("4 MiB")) }
    try FileManager.default.removeItem(at: url)
    do {
      _ = try await SourceFileService().load(url: url)
      XCTFail()
    } catch { XCTAssertFalse(error.localizedDescription.isEmpty) }
  }
}
