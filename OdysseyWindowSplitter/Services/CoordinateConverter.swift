import AppKit

protocol CoordinateConverting {
    func appKitToAccessibility(_ frame: CGRect) -> CGRect
    func accessibilityToAppKit(_ frame: CGRect) -> CGRect
}

/// Converts between AppKit coordinates (origin at the bottom-left of the primary
/// display, y grows upward) and Accessibility coordinates (origin at the top-left
/// of the primary display, y grows downward).
///
/// Both systems share the same x axis, and both are anchored to the primary
/// display, so the conversion only depends on the primary display's height. This
/// holds regardless of where secondary displays are arranged (left, right, above,
/// below, or vertically offset) and regardless of scaling, because NSScreen frames
/// are already expressed in points.
struct CoordinateConverter: CoordinateConverting {
    let primaryScreenHeight: CGFloat

    init(primaryScreenHeight: CGFloat) {
        self.primaryScreenHeight = primaryScreenHeight
    }

    /// The primary display is the one whose AppKit frame origin is (0, 0).
    init?(screens: [NSScreen]) {
        guard let primary = screens.first(where: { $0.frame.origin == .zero }) ?? screens.first else {
            return nil
        }
        self.init(primaryScreenHeight: primary.frame.maxY)
    }

    func appKitToAccessibility(_ frame: CGRect) -> CGRect {
        CGRect(
            x: frame.minX,
            y: primaryScreenHeight - frame.maxY,
            width: frame.width,
            height: frame.height
        )
    }

    func accessibilityToAppKit(_ frame: CGRect) -> CGRect {
        CGRect(
            x: frame.minX,
            y: primaryScreenHeight - frame.minY - frame.height,
            width: frame.width,
            height: frame.height
        )
    }
}
