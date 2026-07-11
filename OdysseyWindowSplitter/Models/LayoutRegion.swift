import CoreGraphics

/// A horizontal region expressed as fractions (0...1) of a display's usable width.
struct LayoutRegion: Equatable {
    let start: CGFloat
    let end: CGFloat
}
