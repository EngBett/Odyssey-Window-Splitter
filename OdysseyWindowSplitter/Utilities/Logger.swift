import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.bett.OdysseyWindowSplitter"

    static let accessibility = Logger(subsystem: subsystem, category: "accessibility")
    static let windowManagement = Logger(subsystem: subsystem, category: "window-management")
    static let layout = Logger(subsystem: subsystem, category: "layout")
    static let screenSelection = Logger(subsystem: subsystem, category: "screen-selection")
    static let shortcuts = Logger(subsystem: subsystem, category: "shortcuts")
    static let application = Logger(subsystem: subsystem, category: "application")
}
