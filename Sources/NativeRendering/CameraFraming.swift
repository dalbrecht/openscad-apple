/// Camera framing shared by square and narrow preview panes.
enum CameraFraming {
  static func distance(radius: Float, zoom: Float, aspect: Float) -> Float {
    // The shader's horizontal field of view shrinks with the viewport aspect.
    radius * 3.2 * zoom / max(0.001, min(1, aspect))
  }
}
