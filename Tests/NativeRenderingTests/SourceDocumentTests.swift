import Foundation
import XCTest

@testable import NativeRendering

final class SourceDocumentTests: XCTestCase {
  func testEditedAndRecoverySnapshotsRemainIndependent() throws {
    let original = "// π\ncube(4);\n"
    var document = try SourceDocument(data: Data(original.utf8))
    let recovered = try document.encodedSource()
    document.source = "sphere(2);"
    XCTAssertEqual(try SourceDocument(data: recovered).source, original)
    XCTAssertEqual(String(data: try document.encodedSource(), encoding: .utf8), "sphere(2);")
    XCTAssertNotEqual(try document.encodedSource(), recovered)
  }
  func testMalformedAndOversizedFilesFailWithoutProducingPartialDocument() {
    XCTAssertThrowsError(try SourceDocument(data: Data([255, 254])))
    XCTAssertThrowsError(try SourceDocument(data: Data(count: 4 * 1024 * 1024 + 1)))
  }
  func testFailedSaveKeepsUnsavedSourceForRecovery() throws {
    var document = SourceDocument()
    let source = String(repeating: "x", count: 4 * 1024 * 1024 + 1)
    document.source = source
    XCTAssertThrowsError(try document.encodedSource())
    XCTAssertEqual(document.source, source)
  }
  func testEmptyAndInvalidScadTextRemainSaveable() throws {
    for source in ["", "cube( ;", "// unsaved text\n"] {
      let document = SourceDocument(source: source)
      XCTAssertEqual(try SourceDocument(data: document.encodedSource()).source, source)
    }
  }
}
