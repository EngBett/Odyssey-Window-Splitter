import XCTest
@testable import OdysseyWindowSplitter

final class LayoutCalculatorTests: XCTestCase {
    private let calculator = LayoutCalculator()

    // MARK: - 9.1 Three columns

    func testThreeColumnsZeroGap() {
        let visible = CGRect(x: 0, y: 0, width: 3000, height: 1200)
        XCTAssertEqual(
            calculator.frame(for: .leftThird, in: visible, gap: 0),
            CGRect(x: 0, y: 0, width: 1000, height: 1200)
        )
        XCTAssertEqual(
            calculator.frame(for: .centerThird, in: visible, gap: 0),
            CGRect(x: 1000, y: 0, width: 1000, height: 1200)
        )
        XCTAssertEqual(
            calculator.frame(for: .rightThird, in: visible, gap: 0),
            CGRect(x: 2000, y: 0, width: 1000, height: 1200)
        )
    }

    // MARK: - 9.2 Four columns

    func testFourColumnsZeroGapWithOffsetOrigin() {
        let visible = CGRect(x: 100, y: 50, width: 4000, height: 1300)
        let expectedXs: [CGFloat] = [100, 1100, 2100, 3100]
        let quarters: [WindowLayout] = [.quarter1, .quarter2, .quarter3, .quarter4]
        for (layout, expectedX) in zip(quarters, expectedXs) {
            let frame = calculator.frame(for: layout, in: visible, gap: 0)
            XCTAssertEqual(frame, CGRect(x: expectedX, y: 50, width: 1000, height: 1300), "\(layout)")
        }
    }

    // MARK: - 9.3 Two-thirds

    func testTwoThirdsZeroGap() {
        let visible = CGRect(x: 0, y: 0, width: 3000, height: 1200)
        let left = calculator.frame(for: .leftTwoThirds, in: visible, gap: 0)
        let right = calculator.frame(for: .rightTwoThirds, in: visible, gap: 0)

        XCTAssertEqual(left.minX, visible.minX)
        XCTAssertEqual(left.width, 2000)
        XCTAssertEqual(right.minX, 1000)
        XCTAssertEqual(right.width, 2000)
        XCTAssertEqual(right.maxX, visible.maxX)
    }

    // MARK: - 9.4 25 / 50 / 25

    func testTwentyFiveFiftyTwentyFiveCoversFullWidthWithoutOverlap() {
        let visible = CGRect(x: 0, y: 0, width: 2000, height: 1000)
        let left = calculator.frame(for: .twentyFiveFiftyTwentyFiveLeft, in: visible, gap: 0)
        let center = calculator.frame(for: .twentyFiveFiftyTwentyFiveCenter, in: visible, gap: 0)
        let right = calculator.frame(for: .twentyFiveFiftyTwentyFiveRight, in: visible, gap: 0)

        XCTAssertEqual(left.width, 500)
        XCTAssertEqual(center.width, 1000)
        XCTAssertEqual(right.width, 500)
        XCTAssertEqual(left.minX, visible.minX)
        XCTAssertEqual(left.maxX, center.minX)
        XCTAssertEqual(center.maxX, right.minX)
        XCTAssertEqual(right.maxX, visible.maxX)
    }

    // MARK: - Centre half

    func testCenterHalfStartsAtQuarterOfWidth() {
        let visible = CGRect(x: 0, y: 0, width: 4000, height: 1000)
        let frame = calculator.frame(for: .centerHalf, in: visible, gap: 0)
        XCTAssertEqual(frame, CGRect(x: 1000, y: 0, width: 2000, height: 1000))
    }

    // MARK: - Maximize

    func testMaximizeUsesFullVisibleFrameWhenGapIsZero() {
        let visible = CGRect(x: 100, y: 50, width: 5120, height: 1415)
        XCTAssertEqual(calculator.frame(for: .maximizeVisibleArea, in: visible, gap: 0), visible)
    }

    // MARK: - 9.5 Gaps

    func testThreeColumnsWithGapHaveConsistentSpacing() {
        let visible = CGRect(x: 0, y: 0, width: 3000, height: 1200)
        let gap: CGFloat = 6
        let left = calculator.frame(for: .leftThird, in: visible, gap: gap)
        let center = calculator.frame(for: .centerThird, in: visible, gap: gap)
        let right = calculator.frame(for: .rightThird, in: visible, gap: gap)

        // Outer margins.
        XCTAssertEqual(left.minX, visible.minX + gap)
        XCTAssertEqual(right.maxX, visible.maxX - gap)
        XCTAssertEqual(left.minY, visible.minY + gap)
        XCTAssertEqual(left.height, visible.height - 2 * gap)

        // Internal spacing equals the selected gap.
        XCTAssertEqual(center.minX - left.maxX, gap, accuracy: 0.001)
        XCTAssertEqual(right.minX - center.maxX, gap, accuracy: 0.001)

        // No overlap and no spill past the visible frame.
        XCTAssertFalse(left.intersects(center))
        XCTAssertFalse(center.intersects(right))
        XCTAssertLessThanOrEqual(right.maxX, visible.maxX)
    }

    func testOversizedGapNeverProducesNegativeSize() {
        let visible = CGRect(x: 0, y: 0, width: 100, height: 40)
        for layout in WindowLayout.allCases {
            let frame = calculator.frame(for: layout, in: visible, gap: 60)
            XCTAssertGreaterThanOrEqual(frame.width, 0, "\(layout)")
            XCTAssertGreaterThanOrEqual(frame.height, 0, "\(layout)")
        }
    }

    // MARK: - 9.6 Non-zero screen origins

    func testNegativeScreenOriginIsPreserved() {
        let visible = CGRect(x: -5120, y: 100, width: 5120, height: 1440)
        let left = calculator.frame(for: .leftThird, in: visible, gap: 0)
        let center = calculator.frame(for: .centerThird, in: visible, gap: 0)
        let right = calculator.frame(for: .rightThird, in: visible, gap: 0)

        XCTAssertEqual(left.minX, -5120)
        XCTAssertEqual(right.maxX, 0)
        XCTAssertEqual(left.minY, 100)
        XCTAssertEqual(left.height, 1440)
        XCTAssertEqual(left.maxX, center.minX)
        XCTAssertEqual(center.maxX, right.minX)
    }

    // MARK: - 9.7 Rounding

    func testThirdsOfIndivisibleWidthAreContiguousAndPixelSafe() {
        let visible = CGRect(x: 0, y: 0, width: 5120, height: 1440)
        let left = calculator.frame(for: .leftThird, in: visible, gap: 0)
        let center = calculator.frame(for: .centerThird, in: visible, gap: 0)
        let right = calculator.frame(for: .rightThird, in: visible, gap: 0)

        XCTAssertEqual(left.minX, visible.minX)
        XCTAssertEqual(right.maxX, visible.maxX, "No unallocated strip may remain at the far right")
        XCTAssertEqual(left.maxX, center.minX, "Adjacent regions must share a boundary")
        XCTAssertEqual(center.maxX, right.minX, "Adjacent regions must share a boundary")

        for frame in [left, center, right] {
            XCTAssertEqual(frame.minX, frame.minX.rounded(), "Boundaries must be point-safe")
            XCTAssertEqual(frame.maxX, frame.maxX.rounded(), "Boundaries must be point-safe")
        }
    }

    func testQuartersOfIndivisibleWidthAreContiguous() {
        let visible = CGRect(x: 0, y: 0, width: 4002, height: 1000)
        let quarters: [WindowLayout] = [.quarter1, .quarter2, .quarter3, .quarter4]
        let frames = quarters.map { calculator.frame(for: $0, in: visible, gap: 0) }

        XCTAssertEqual(frames[0].minX, visible.minX)
        XCTAssertEqual(frames[3].maxX, visible.maxX)
        for index in 0..<3 {
            XCTAssertEqual(frames[index].maxX, frames[index + 1].minX, "Quarter \(index + 1) and \(index + 2) must be contiguous")
        }
    }
}
