import ApplicationServices

protocol AccessibilityPermissionProviding {
    var isTrusted: Bool { get }
    func requestPermission()
}

struct AccessibilityPermission: AccessibilityPermissionProviding {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
