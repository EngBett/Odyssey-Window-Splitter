import AppKit
import OSLog
import SwiftUI

enum SettingsKeys {
    static let gapSize = "gapSize"
    static let shortcutsEnabled = "shortcutsEnabled"
    static let defaultGap: Double = 6
    static let gapOptions: [Double] = [0, 4, 6, 8, 12, 16]
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isTrusted: Bool
    @Published private(set) var lastMessage: String?
    @Published private(set) var shortcutConflicts: [String] = []

    let permission: AccessibilityPermissionProviding
    let launchAtLogin: LaunchAtLoginProviding

    private let windowManager: WindowManaging
    private let shortcutManager: GlobalShortcutManager
    private let previousAppTracker = PreviousAppTracker()
    private var permissionTimer: Timer?

    init() {
        let permission = AccessibilityPermission()
        self.permission = permission
        self.launchAtLogin = LaunchAtLoginService()
        self.isTrusted = permission.isTrusted

        let focusedWindowProvider = FocusedWindowProvider()
        let tracker = previousAppTracker
        focusedWindowProvider.fallbackAppPID = { tracker.lastOtherAppPID }

        self.windowManager = WindowManager(
            permission: permission,
            focusedWindowProvider: focusedWindowProvider,
            screenProvider: NSScreenProvider(),
            layoutCalculator: LayoutCalculator(),
            gapProvider: {
                CGFloat(UserDefaults.standard.object(forKey: SettingsKeys.gapSize) as? Double ?? SettingsKeys.defaultGap)
            }
        )

        let shortcutManager = GlobalShortcutManager()
        self.shortcutManager = shortcutManager
        shortcutManager.handler = { [weak self] layout in
            self?.apply(layout)
        }
        if UserDefaults.standard.object(forKey: SettingsKeys.shortcutsEnabled) as? Bool ?? true {
            registerShortcuts()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                shortcutManager.unregister()
            }
        }

        startPermissionMonitoringIfNeeded()
        Logger.application.info("Odyssey Window Splitter started. Accessibility trusted: \(self.isTrusted)")
    }

    func apply(_ layout: WindowLayout) {
        Task { @MainActor in
            let result = await windowManager.apply(layout)
            lastMessage = result.message
            if !result.wasSuccessful {
                presentFailure(result.message)
            }
        }
    }

    func refreshPermission() {
        isTrusted = permission.isTrusted
        if isTrusted {
            permissionTimer?.invalidate()
            permissionTimer = nil
        }
    }

    func requestPermission() {
        permission.requestPermission()
        startPermissionMonitoringIfNeeded()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func setShortcutsEnabled(_ enabled: Bool) {
        if enabled {
            registerShortcuts()
        } else {
            shortcutManager.unregister()
            shortcutConflicts = []
        }
    }

    private func registerShortcuts() {
        shortcutManager.register()
        shortcutConflicts = shortcutManager.conflicts
    }

    private func startPermissionMonitoringIfNeeded() {
        guard !isTrusted, permissionTimer == nil else { return }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.refreshPermission()
            }
        }
    }

    private func presentFailure(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Odyssey Window Splitter"
        alert.informativeText = message
        alert.alertStyle = .warning
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
