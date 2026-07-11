import CoreGraphics

protocol LayoutCalculating {
    func frame(for layout: WindowLayout, in visibleFrame: CGRect, gap: CGFloat) -> CGRect
}

/// Pure layout mathematics. Column boundaries are computed first and each frame is
/// derived from its adjacent boundaries, so columns never overlap and never leave a
/// stray unallocated strip when the width does not divide evenly.
///
/// Spacing model: the configured gap is used as an outer margin against the display
/// edges, and half of it is applied to each side of an internal boundary, so the
/// visual spacing between any two adjacent windows equals the spacing to the edges.
struct LayoutCalculator: LayoutCalculating {
    func frame(for layout: WindowLayout, in visibleFrame: CGRect, gap: CGFloat) -> CGRect {
        let margin = max(0, gap)
        let innerMinX = visibleFrame.minX + margin
        let innerMaxX = visibleFrame.maxX - margin
        let innerWidth = max(0, innerMaxX - innerMinX)
        let innerMinY = visibleFrame.minY + margin
        let innerHeight = max(0, visibleFrame.height - 2 * margin)

        let region = layout.region

        func boundary(_ fraction: CGFloat) -> CGFloat {
            (innerMinX + innerWidth * fraction).rounded()
        }

        let leftEdge = region.start <= 0 ? innerMinX : boundary(region.start) + gap / 2
        let rightEdge = region.end >= 1 ? innerMaxX : boundary(region.end) - gap / 2

        return CGRect(
            x: leftEdge,
            y: innerMinY,
            width: max(0, rightEdge - leftEdge),
            height: innerHeight
        )
    }
}
