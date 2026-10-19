import Foundation
import PreviewModel
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  /// OpenSCAD source, registered as an imported source-code type by the app bundle.
  public static let openSCADSource = UTType(
    importedAs: "org.openscad.source", conformingTo: .sourceCode)
}

/// Value snapshots for macOS document saving, autosaving and recovery.
/// Compilation never determines whether source text can be saved.
public struct SourceDocument: FileDocument, Sendable {
  public static var readableContentTypes: [UTType] { [.openSCADSource] }
  public var source: String

  /// Creates a new untitled document. Source may be incomplete or invalid SCAD.
  public init(source: String = "") { self.source = source }

  /// Decodes a bounded UTF-8 file or recovery snapshot; throws without changing any existing document.
  public init(data: Data) throws {
    guard data.count <= 4 * 1024 * 1024 else { throw PreviewError.invalid("Source exceeds 4 MiB") }
    guard let source = String(data: data, encoding: .utf8) else {
      throw PreviewError.invalid("Source is not UTF-8")
    }
    self.source = source
  }

  public init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw PreviewError.invalid("OpenSCAD source must be a regular file")
    }
    try self.init(data: data)
  }

  /// Returns an owned UTF-8 snapshot, or throws while retaining the current edits for retry/recovery.
  public func encodedSource() throws -> Data {
    guard source.utf8.count <= 4 * 1024 * 1024 else {
      throw PreviewError.invalid("Source exceeds 4 MiB")
    }
    return Data(source.utf8)
  }

  public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: try encodedSource())
  }
}
