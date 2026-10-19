import Foundation
import XCTest

@testable import PreviewModel

@MainActor final class CompilerTests: XCTestCase {
  func testRealWorkerPreservesSceneAfterSecondCompilation() async throws {
    guard let path = ProcessInfo.processInfo.environment["OPENSCAD_TEST_WORKER"] else {
      throw XCTSkip("Set OPENSCAD_TEST_WORKER for engine integration")
    }
    let compiler = PreviewCompiler(executable: URL(fileURLWithPath: path))
    let first = try await compiler.compile(source: "cube(1);")
    _ = try await compiler.compile(source: "sphere(2);")
    XCTAssertEqual(first.triangleCount, 12)
    XCTAssertEqual(first.radius, sqrt(3) / 2, accuracy: 0.001)
  }
  func testSourceLimitRejectsBeforeLaunch() async {
    let compiler = PreviewCompiler(executable: URL(fileURLWithPath: "/does/not/exist"))
    do {
      _ = try await compiler.compile(source: String(repeating: " ", count: 4 * 1024 * 1024 + 1))
      XCTFail()
    } catch { XCTAssertTrue(error.localizedDescription.contains("4 MiB")) }
  }
  func testCancellationBeforeLaunch() async {
    let task = Task {
      try Task.checkCancellation()
      return try await PreviewCompiler(executable: URL(fileURLWithPath: "/does/not/exist")).compile(
        source: "cube(1);")
    }
    task.cancel()
    do {
      _ = try await task.value
      XCTFail()
    } catch { XCTAssertTrue(error is CancellationError) }
  }
  func testMissingWorkerPreservesOriginalError() async {
    do {
      _ = try await PreviewCompiler(executable: URL(fileURLWithPath: "/does/not/exist")).compile(
        source: "cube(1);")
      XCTFail()
    } catch { XCTAssertFalse(error.localizedDescription.isEmpty) }
  }
}
extension CompilerTests {
  private func workerScript(_ body: String) throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let path = directory.appendingPathComponent("worker")
    try ("#!/bin/sh\n" + body).write(to: path, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: path.path)
    return path
  }
  func testCancellationTerminatesRunningWorker() async throws {
    let worker = try workerScript("exec /bin/sleep 30\n")
    defer { try? FileManager.default.removeItem(at: worker.deletingLastPathComponent()) }
    let compiler = PreviewCompiler(executable: worker)
    let task = Task { try await compiler.compile(source: "cube(1);") }
    try await Task.sleep(for: .milliseconds(100))
    let start = ContinuousClock.now
    task.cancel()
    do {
      _ = try await task.value
      XCTFail()
    } catch { XCTAssertTrue(error is CancellationError) }
    XCTAssertLessThan(start.duration(to: .now), .seconds(2))
  }
  func testTimeoutAndWorkerFailureRetainDiagnostics() async throws {
    let worker = try workerScript("echo specific-native-error >&2\nexit 1\n")
    defer { try? FileManager.default.removeItem(at: worker.deletingLastPathComponent()) }
    do {
      _ = try await PreviewCompiler(executable: worker).compile(source: "")
      XCTFail()
    } catch { XCTAssertTrue(error.localizedDescription.contains("specific-native-error")) }
    let slow = try workerScript("exec /bin/sleep 30\n")
    defer { try? FileManager.default.removeItem(at: slow.deletingLastPathComponent()) }
    do {
      _ = try await PreviewCompiler(executable: slow, timeout: .milliseconds(75)).compile(
        source: "")
      XCTFail()
    } catch { XCTAssertTrue(error.localizedDescription.contains("exceeded")) }
  }
  func testSuccessfulEmptyWorkerResponse() async throws {
    let worker = try workerScript(
      "echo '{\"version\":1,\"leaves\":[],\"nodes\":[],\"root\":-1,\"highlights\":[],\"backgrounds\":[]}'\n"
    )
    defer { try? FileManager.default.removeItem(at: worker.deletingLastPathComponent()) }
    let scene = try await PreviewCompiler(executable: worker).compile(source: "")
    XCTAssertEqual(scene.triangleCount, 0)
  }
}
extension CompilerTests {
  func testOutputQuotaAlsoAppliesToAnAlreadyExitedWorker() async throws {
    let worker = try workerScript("printf '0123456789012345678901234567890123456789'\n")
    defer { try? FileManager.default.removeItem(at: worker.deletingLastPathComponent()) }
    do {
      _ = try await PreviewCompiler(executable: worker, maximumOutputBytes: 16).compile(source: "")
      XCTFail()
    } catch { XCTAssertTrue(error.localizedDescription.contains("Worker output quota")) }
  }
}
