import AppKit
import ImageIO
import QuickLookThumbnailing
import UniformTypeIdentifiers

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let request = QLThumbnailGenerator.Request(fileAt: input, size: CGSize(width: 256, height: 256),
  scale: 1, representationTypes: .thumbnail)
QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
  guard let representation else {
    print("Thumbnail failed: \(String(describing: error))")
    exit(1)
  }
  guard let destination = CGImageDestinationCreateWithURL(output as CFURL,
    UTType.png.identifier as CFString, 1, nil) else { exit(2) }
  CGImageDestinationAddImage(destination, representation.cgImage, nil)
  guard CGImageDestinationFinalize(destination) else { exit(3) }
  print("Thumbnail representation: \(representation.type.rawValue)")
  exit(0)
}
RunLoop.main.run(until: Date().addingTimeInterval(30))
print("Thumbnail request timed out after 30 seconds")
exit(4)
