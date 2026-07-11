import XCTest
@testable import OdysseyWindowSplitter

final class ScreenSelectionTests: XCTestCase {
    // Samsung Odyssey ultrawide to the left of the MacBook primary display.
    private let ultrawide = CGRect(x: -5120, y: 0, width: 5120, height: 1440)
    private let macbook = CGRect(x: 0, y: 0, width: 1728, height: 1117)

    private var displays: [CGRect] { [ultrawide, macbook] }

    func testWindowFullyOnUltrawide() {
        let window = CGRect(x: -3000, y: 200, width: 1200, height: 800)
        XCTAssertEqual(ScreenSelection.bestIndex(for: window, in: displays), 0)
    }

    func testWindowFullyOnMacBookDisplay() {
        let window = CGRect(x: 100, y: 100, width: 800, height: 600)
        XCTAssertEqual(ScreenSelection.bestIndex(for: window, in: displays), 1)
    }

    func testWindowOverlappingBothPicksLargestIntersection() {
        // 400 points on the ultrawide, 600 points on the MacBook display.
        let mostlyMacBook = CGRect(x: -400, y: 100, width: 1000, height: 500)
        XCTAssertEqual(ScreenSelection.bestIndex(for: mostlyMacBook, in: displays), 1)

        // 600 points on the ultrawide, 400 points on the MacBook display.
        let mostlyUltrawide = CGRect(x: -600, y: 100, width: 1000, height: 500)
        XCTAssertEqual(ScreenSelection.bestIndex(for: mostlyUltrawide, in: displays), 0)
    }

    func testWindowOutsideAllDisplaysReturnsNil() {
        let window = CGRect(x: 10000, y: 10000, width: 100, height: 100)
        XCTAssertNil(ScreenSelection.bestIndex(for: window, in: displays))
    }

    func testEmptyDisplayListReturnsNil() {
        let window = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertNil(ScreenSelection.bestIndex(for: window, in: []))
    }

    func testZeroAreaIntersectionFallsBackToCenterContainment() {
        // A zero-width window intersects with zero area, so the centre rule decides.
        let window = CGRect(x: 50, y: 50, width: 0, height: 100)
        XCTAssertEqual(ScreenSelection.bestIndex(for: window, in: displays), 1)
    }

    func testDisplayDescriptorConvenience() {
        let descriptors = [
            DisplayDescriptor(frame: ultrawide, visibleFrame: ultrawide),
            DisplayDescriptor(frame: macbook, visibleFrame: macbook.insetBy(dx: 0, dy: 20)),
        ]
        let window = CGRect(x: -3000, y: 200, width: 1200, height: 800)
        XCTAssertEqual(ScreenSelection.best(for: window, in: descriptors), descriptors[0])
    }
}
