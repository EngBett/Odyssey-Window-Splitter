import CoreGraphics

/// A plain description of a display, used to keep screen-selection logic
/// testable without constructing NSScreen instances.
struct DisplayDescriptor: Equatable {
    let frame: CGRect
    let visibleFrame: CGRect
}
