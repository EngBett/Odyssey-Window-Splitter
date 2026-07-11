import ApplicationServices
import Foundation

enum WindowManagerError: LocalizedError {
    case accessibilityPermissionDenied
    case focusedApplicationNotFound
    case focusedWindowNotFound
    case positionUnavailable
    case sizeUnavailable
    case screenNotFound
    case windowNotMovable
    case windowNotResizable
    case fullScreenWindowUnsupported
    case failedToSetPosition(AXError)
    case failedToSetSize(AXError)

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "Odyssey Window Splitter needs Accessibility permission to move and resize windows from other applications."
        case .focusedApplicationNotFound:
            return "No focused application could be found."
        case .focusedWindowNotFound:
            return "The focused application does not have a window that can be rearranged."
        case .positionUnavailable:
            return "The window's position could not be read."
        case .sizeUnavailable:
            return "The window's size could not be read."
        case .screenNotFound:
            return "No display could be matched to the focused window."
        case .windowNotMovable:
            return "This window does not allow its position to be changed."
        case .windowNotResizable:
            return "This window does not allow its size to be changed."
        case .fullScreenWindowUnsupported:
            return "Full-screen windows cannot be rearranged. Exit full screen and try again."
        case .failedToSetPosition(let error):
            return "The window position could not be set (AXError \(error.rawValue))."
        case .failedToSetSize(let error):
            return "The window size could not be set (AXError \(error.rawValue))."
        }
    }
}
