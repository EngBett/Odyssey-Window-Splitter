import AppKit

protocol ScreenProviding {
    var screens: [NSScreen] { get }
    func screen(containing windowFrame: CGRect) -> NSScreen?
}

/// Pure screen-selection logic, kept free of NSScreen so it can be unit-tested.
enum ScreenSelection {
    /// Picks the display with the largest intersection area; if no display
    /// intersects the window, falls back to the display containing the window's
    /// centre point. Returns nil when neither rule resolves a display.
    static func bestIndex(for windowFrame: CGRect, in displayFrames: [CGRect]) -> Int? {
        var bestIndex: Int?
        var bestArea: CGFloat = 0
        for (index, frame) in displayFrames.enumerated() {
            let intersection = frame.intersection(windowFrame)
            guard !intersection.isNull else { continue }
            let area = intersection.width * intersection.height
            if area > bestArea {
                bestArea = area
                bestIndex = index
            }
        }
        if let bestIndex {
            return bestIndex
        }
        let center = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        return displayFrames.firstIndex { $0.contains(center) }
    }

    static func best(for windowFrame: CGRect, in displays: [DisplayDescriptor]) -> DisplayDescriptor? {
        bestIndex(for: windowFrame, in: displays.map(\.frame)).map { displays[$0] }
    }
}

final class NSScreenProvider: ScreenProviding {
    var screens: [NSScreen] {
        NSScreen.screens
    }

    func screen(containing windowFrame: CGRect) -> NSScreen? {
        let screens = self.screens
        if let index = ScreenSelection.bestIndex(for: windowFrame, in: screens.map(\.frame)) {
            return screens[index]
        }
        return NSScreen.main
    }
}
