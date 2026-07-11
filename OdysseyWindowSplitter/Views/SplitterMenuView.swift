import SwiftUI

struct SplitterMenuView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage(SettingsKeys.gapSize) private var gapSize: Double = SettingsKeys.defaultGap

    var body: some View {
        if !appState.isTrusted {
            Text("Accessibility permission required")
            Button("Request Accessibility Permission") {
                appState.requestPermission()
            }
            Button("Open Accessibility Settings") {
                appState.openAccessibilitySettings()
            }
            Divider()
        }

        Menu("Three Columns") {
            layoutButton(.leftThird)
            layoutButton(.centerThird)
            layoutButton(.rightThird)
        }
        Menu("Four Columns") {
            layoutButton(.quarter1)
            layoutButton(.quarter2)
            layoutButton(.quarter3)
            layoutButton(.quarter4)
        }
        Menu("Wide Layouts") {
            layoutButton(.leftTwoThirds)
            layoutButton(.rightTwoThirds)
            Divider()
            layoutButton(.twentyFiveFiftyTwentyFiveLeft)
            layoutButton(.twentyFiveFiftyTwentyFiveCenter)
            layoutButton(.twentyFiveFiftyTwentyFiveRight)
        }
        Menu("Other") {
            layoutButton(.leftHalf)
            layoutButton(.rightHalf)
            layoutButton(.centerHalf)
            layoutButton(.maximizeVisibleArea)
        }

        Divider()

        Menu("Settings") {
            Picker("Gap Size", selection: $gapSize) {
                ForEach(SettingsKeys.gapOptions, id: \.self) { value in
                    Text("\(Int(value)) pt").tag(value)
                }
            }
            SettingsLink {
                Text("All Settings…")
            }
            Divider()
            Button("Request Accessibility Permission") {
                appState.requestPermission()
            }
            Button("Open Accessibility Settings") {
                appState.openAccessibilitySettings()
            }
        }

        if let message = appState.lastMessage {
            Divider()
            Text(message)
        }

        Divider()

        Button("Quit Odyssey Window Splitter") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func layoutButton(_ layout: WindowLayout) -> some View {
        Button(layout.displayName) {
            appState.apply(layout)
        }
    }
}
