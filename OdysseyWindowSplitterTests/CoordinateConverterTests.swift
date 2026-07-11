import XCTest
@testable import OdysseyWindowSplitter

final class CoordinateConverterTests: XCTestCase {
    func testAppKitToAccessibilityOnPrimaryDisplay() {
        let converter = CoordinateConverter(primaryScreenHeight: 1080)
        // A window whose top edge touches the top of the primary display.
        let appKit = CGRect(x: 100, y: 880, width: 300, height: 200)
        let ax = converter.appKitToAccessibility(appKit)
        XCTAssertEqual(ax, CGRect(x: 100, y: 0, width: 300, height: 200))
    }

    func testAccessibilityToAppKitOnPrimaryDisplay() {
        let converter = CoordinateConverter(primaryScreenHeight: 1080)
        let ax = CGRect(x: 100, y: 0, width: 300, height: 200)
        let appKit = converter.accessibilityToAppKit(ax)
        XCTAssertEqual(appKit, CGRect(x: 100, y: 880, width: 300, height: 200))
    }

    func testRoundTripWithNegativeOrigins() {
        let converter = CoordinateConverter(primaryScreenHeight: 1117)
        let original = CGRect(x: -5120, y: -323, width: 2560, height: 1440)
        let roundTripped = converter.accessibilityToAppKit(converter.appKitToAccessibility(original))
        XCTAssertEqual(roundTripped, original)
    }

    func testExternalDisplayLeftOfPrimaryWithVerticalOffset() {
        // MacBook primary display is 1117 points tall; the ultrawide sits to the
        // left and is vertically offset upward.
        let converter = CoordinateConverter(primaryScreenHeight: 1117)
        let appKit = CGRect(x: -5120, y: 100, width: 5120, height: 1440)
        let ax = converter.appKitToAccessibility(appKit)

        XCTAssertEqual(ax.minX, -5120, "X coordinates are shared between both systems")
        XCTAssertEqual(ax.minY, 1117 - 1540, "Areas above the primary top edge become negative AX y values")
        XCTAssertEqual(converter.accessibilityToAppKit(ax), appKit)
    }

    func testDisplayBelowPrimary() {
        let converter = CoordinateConverter(primaryScreenHeight: 1440)
        let appKit = CGRect(x: 200, y: -900, width: 800, height: 600)
        let ax = converter.appKitToAccessibility(appKit)

        XCTAssertEqual(ax.minY, 1440 - (-300), "Areas below the primary display have AX y beyond the primary height")
        XCTAssertEqual(converter.accessibilityToAppKit(ax), appKit)
    }
}
