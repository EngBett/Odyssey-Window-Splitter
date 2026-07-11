import AppKit

/// Remembers the most recently active application other than this one, so that
/// layout commands can still target it if interacting with the menu bar has
/// shifted focus to this app.
final class PreviousAppTracker {
    private(set) var lastOtherAppPID: pid_t?
    private var observer: NSObjectProtocol?

    init() {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.processIdentifier != ownPID {
            lastOtherAppPID = frontmost.processIdentifier
        }
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.processIdentifier != ownPID else {
                return
            }
            self?.lastOtherAppPID = app.processIdentifier
        }
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
