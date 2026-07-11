import AppKit
import ApplicationServices
import OSLog

protocol FocusedWindowProviding {
    func focusedWindow() throws -> AXUIElement
}

final class FocusedWindowProvider: FocusedWindowProviding {
    /// Supplies the PID of the most recently active regular application other than
    /// this one, used when interacting with the menu bar has made this app the
    /// "focused" application.
    var fallbackAppPID: (() -> pid_t?)?

    func focusedWindow() throws -> AXUIElement {
        let application = try focusedApplicationElement()
        var windowValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(application, kAXFocusedWindowAttribute as CFString, &windowValue)
        guard error == .success, let windowValue, CFGetTypeID(windowValue) == AXUIElementGetTypeID() else {
            Logger.accessibility.error("Focused window lookup failed with AXError \(error.rawValue)")
            throw WindowManagerError.focusedWindowNotFound
        }
        // Safe: the type ID was checked above.
        return (windowValue as! AXUIElement)
    }

    private func focusedApplicationElement() throws -> AXUIElement {
        let systemWide = AXUIElementCreateSystemWide()
        var appValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &appValue)
        if error == .success, let appValue, CFGetTypeID(appValue) == AXUIElementGetTypeID() {
            // Safe: the type ID was checked above.
            let element = appValue as! AXUIElement
            var pid: pid_t = 0
            if AXUIElementGetPid(element, &pid) == .success,
               pid == ProcessInfo.processInfo.processIdentifier,
               let fallback = fallbackAppPID?() {
                Logger.accessibility.debug("Focused application is ourselves; targeting previous app pid \(fallback)")
                return AXUIElementCreateApplication(fallback)
            }
            return element
        }
        if let fallback = fallbackAppPID?() {
            Logger.accessibility.debug("No focused application; targeting previous app pid \(fallback)")
            return AXUIElementCreateApplication(fallback)
        }
        Logger.accessibility.error("Focused application lookup failed with AXError \(error.rawValue)")
        throw WindowManagerError.focusedApplicationNotFound
    }
}
