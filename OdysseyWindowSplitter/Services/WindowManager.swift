import AppKit
import ApplicationServices
import OSLog

protocol WindowManaging {
    func apply(_ layout: WindowLayout) async -> WindowMoveResult
}

struct WindowMoveResult {
    let requestedFrame: CGRect
    let actualFrame: CGRect?
    let wasSuccessful: Bool
    let message: String
}

@MainActor
final class WindowManager: WindowManaging {
    private let permission: AccessibilityPermissionProviding
    private let focusedWindowProvider: FocusedWindowProviding
    private let screenProvider: ScreenProviding
    private let layoutCalculator: LayoutCalculating
    private let gapProvider: () -> CGFloat

    /// Tolerance in points before the final frame is considered materially different
    /// from the requested one.
    private static let frameTolerance: CGFloat = 2

    init(
        permission: AccessibilityPermissionProviding,
        focusedWindowProvider: FocusedWindowProviding,
        screenProvider: ScreenProviding,
        layoutCalculator: LayoutCalculating,
        gapProvider: @escaping () -> CGFloat
    ) {
        self.permission = permission
        self.focusedWindowProvider = focusedWindowProvider
        self.screenProvider = screenProvider
        self.layoutCalculator = layoutCalculator
        self.gapProvider = gapProvider
    }

    func apply(_ layout: WindowLayout) async -> WindowMoveResult {
        do {
            return try applyNow(layout)
        } catch let error as WindowManagerError {
            let message = error.errorDescription ?? "The window could not be moved."
            Logger.windowManagement.error("Applying \(layout.rawValue, privacy: .public) failed: \(message, privacy: .public)")
            return WindowMoveResult(requestedFrame: .zero, actualFrame: nil, wasSuccessful: false, message: message)
        } catch {
            Logger.windowManagement.error("Applying \(layout.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return WindowMoveResult(requestedFrame: .zero, actualFrame: nil, wasSuccessful: false, message: error.localizedDescription)
        }
    }

    private func applyNow(_ layout: WindowLayout) throws -> WindowMoveResult {
        guard permission.isTrusted else {
            throw WindowManagerError.accessibilityPermissionDenied
        }

        let window = try focusedWindowProvider.focusedWindow()

        if AXWindow.isFullScreen(window) {
            throw WindowManagerError.fullScreenWindowUnsupported
        }
        if AXWindow.isMinimized(window) {
            AXWindow.setMinimized(false, on: window)
        }
        guard AXWindow.isSettable(kAXPositionAttribute, on: window) else {
            throw WindowManagerError.windowNotMovable
        }
        guard AXWindow.isSettable(kAXSizeAttribute, on: window) else {
            throw WindowManagerError.windowNotResizable
        }

        let axFrame = try AXWindow.frame(of: window)
        guard let converter = CoordinateConverter(screens: screenProvider.screens) else {
            throw WindowManagerError.screenNotFound
        }
        let appKitFrame = converter.accessibilityToAppKit(axFrame)
        guard let screen = screenProvider.screen(containing: appKitFrame) else {
            throw WindowManagerError.screenNotFound
        }
        Logger.screenSelection.debug("Selected display \(screen.localizedName, privacy: .public) for window at \(String(describing: appKitFrame), privacy: .public)")

        let target = layoutCalculator.frame(for: layout, in: screen.visibleFrame, gap: gapProvider())
        let axTarget = converter.appKitToAccessibility(target)
        Logger.windowManagement.info("Applying \(layout.rawValue, privacy: .public): requested frame \(String(describing: target), privacy: .public)")

        try AXWindow.setFrame(axTarget, on: window)

        let finalAppKitFrame = (try? AXWindow.frame(of: window)).map(converter.accessibilityToAppKit)
        if let finalAppKitFrame, framesDifferMaterially(finalAppKitFrame, target) {
            Logger.windowManagement.warning("Actual frame \(String(describing: finalAppKitFrame), privacy: .public) differs from requested \(String(describing: target), privacy: .public)")
            return WindowMoveResult(
                requestedFrame: target,
                actualFrame: finalAppKitFrame,
                wasSuccessful: true,
                message: "\(layout.displayName) applied, but the application adjusted the frame (likely a minimum-size constraint)."
            )
        }
        return WindowMoveResult(
            requestedFrame: target,
            actualFrame: finalAppKitFrame,
            wasSuccessful: true,
            message: "\(layout.displayName) applied."
        )
    }

    private func framesDifferMaterially(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) > Self.frameTolerance
            || abs(a.minY - b.minY) > Self.frameTolerance
            || abs(a.width - b.width) > Self.frameTolerance
            || abs(a.height - b.height) > Self.frameTolerance
    }
}

/// Low-level Accessibility attribute helpers with defensive type checks. Values
/// returned by the AX APIs are validated with CFGetTypeID/AXValueGetType before use.
enum AXWindow {
    static func frame(of window: AXUIElement) throws -> CGRect {
        var origin = CGPoint.zero
        var size = CGSize.zero
        try readValue(kAXPositionAttribute, of: window, type: .cgPoint, into: &origin, failure: .positionUnavailable)
        try readValue(kAXSizeAttribute, of: window, type: .cgSize, into: &size, failure: .sizeUnavailable)
        return CGRect(origin: origin, size: size)
    }

    static func setFrame(_ frame: CGRect, on window: AXUIElement) throws {
        var origin = frame.origin
        var size = frame.size
        guard let positionValue = AXValueCreate(.cgPoint, &origin) else {
            throw WindowManagerError.failedToSetPosition(.failure)
        }
        guard let sizeValue = AXValueCreate(.cgSize, &size) else {
            throw WindowManagerError.failedToSetSize(.failure)
        }

        let positionError = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        guard positionError == .success else {
            throw WindowManagerError.failedToSetPosition(positionError)
        }
        let sizeError = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        guard sizeError == .success else {
            throw WindowManagerError.failedToSetSize(sizeError)
        }
        // Some applications apply the size relative to the old position; setting the
        // position a second time keeps the window anchored to the requested origin.
        _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    }

    static func isSettable(_ attribute: String, on element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        let error = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        return error == .success && settable.boolValue
    }

    static func isMinimized(_ window: AXUIElement) -> Bool {
        boolValue(kAXMinimizedAttribute, of: window)
    }

    static func isFullScreen(_ window: AXUIElement) -> Bool {
        boolValue("AXFullScreen", of: window)
    }

    /// Best effort: if un-minimizing fails the subsequent move reports the error.
    static func setMinimized(_ minimized: Bool, on window: AXUIElement) {
        _ = AXUIElementSetAttributeValue(
            window,
            kAXMinimizedAttribute as CFString,
            minimized ? kCFBooleanTrue : kCFBooleanFalse
        )
    }

    private static func readValue<T>(
        _ attribute: String,
        of element: AXUIElement,
        type: AXValueType,
        into result: inout T,
        failure: WindowManagerError
    ) throws {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success,
              let raw, CFGetTypeID(raw) == AXValueGetTypeID() else {
            throw failure
        }
        // Safe: the type ID was checked above.
        let axValue = raw as! AXValue
        guard AXValueGetType(axValue) == type, AXValueGetValue(axValue, type, &result) else {
            throw failure
        }
    }

    private static func boolValue(_ attribute: String, of element: AXUIElement) -> Bool {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success,
              let number = raw as? NSNumber else {
            return false
        }
        return number.boolValue
    }
}
