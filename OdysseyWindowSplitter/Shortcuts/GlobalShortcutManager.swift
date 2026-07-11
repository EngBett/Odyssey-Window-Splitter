import AppKit
import Carbon.HIToolbox
import OSLog

/// Registers system-wide hotkeys using the Carbon RegisterEventHotKey API, which
/// remains the supported native mechanism for global shortcuts and requires no
/// extra permissions or third-party dependencies.
@MainActor
final class GlobalShortcutManager {
    struct Definition {
        let layout: WindowLayout
        let keyCode: UInt32
        let keyLabel: String
    }

    /// All shortcuts use Control + Option, which avoids common system shortcuts.
    static let definitions: [Definition] = [
        Definition(layout: .leftThird, keyCode: UInt32(kVK_ANSI_1), keyLabel: "1"),
        Definition(layout: .centerThird, keyCode: UInt32(kVK_ANSI_2), keyLabel: "2"),
        Definition(layout: .rightThird, keyCode: UInt32(kVK_ANSI_3), keyLabel: "3"),
        Definition(layout: .quarter1, keyCode: UInt32(kVK_ANSI_4), keyLabel: "4"),
        Definition(layout: .quarter2, keyCode: UInt32(kVK_ANSI_5), keyLabel: "5"),
        Definition(layout: .quarter3, keyCode: UInt32(kVK_ANSI_6), keyLabel: "6"),
        Definition(layout: .quarter4, keyCode: UInt32(kVK_ANSI_7), keyLabel: "7"),
        Definition(layout: .leftHalf, keyCode: UInt32(kVK_LeftArrow), keyLabel: "←"),
        Definition(layout: .rightHalf, keyCode: UInt32(kVK_RightArrow), keyLabel: "→"),
        Definition(layout: .maximizeVisibleArea, keyCode: UInt32(kVK_UpArrow), keyLabel: "↑"),
    ]

    var handler: ((WindowLayout) -> Void)?
    private(set) var conflicts: [String] = []

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?

    private static let signature: OSType = {
        var result: OSType = 0
        for scalar in "OWSP".unicodeScalars {
            result = (result << 8) | OSType(scalar.value)
        }
        return result
    }()

    func register() {
        guard hotKeyRefs.isEmpty else { return }
        conflicts = []
        installEventHandlerIfNeeded()
        for (index, definition) in Self.definitions.enumerated() {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: UInt32(index))
            let status = RegisterEventHotKey(
                definition.keyCode,
                UInt32(controlKey | optionKey),
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )
            if status == noErr, let hotKeyRef {
                hotKeyRefs.append(hotKeyRef)
            } else {
                let description = "⌃⌥\(definition.keyLabel) (\(definition.layout.displayName))"
                conflicts.append(description)
                Logger.shortcuts.error("Failed to register \(description, privacy: .public): status \(status)")
            }
        }
        Logger.shortcuts.info("Registered \(self.hotKeyRefs.count) global shortcuts (\(self.conflicts.count) conflicts)")
    }

    func unregister() {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs = []
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        Logger.shortcuts.info("Unregistered all global shortcuts")
    }

    fileprivate func handleHotKey(id: UInt32) {
        guard Int(id) < Self.definitions.count else { return }
        handler?(Self.definitions[Int(id)].layout)
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            globalHotKeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        if status != noErr {
            Logger.shortcuts.error("Failed to install hotkey event handler: status \(status)")
        }
    }
}

private func globalHotKeyEventHandler(
    _ callRef: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else {
        return OSStatus(eventNotHandledErr)
    }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else {
        return status
    }
    let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
    // Carbon dispatches hotkey events on the main thread.
    MainActor.assumeIsolated {
        manager.handleHotKey(id: hotKeyID.id)
    }
    return noErr
}
