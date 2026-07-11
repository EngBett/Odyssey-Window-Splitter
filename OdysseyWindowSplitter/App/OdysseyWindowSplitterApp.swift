import SwiftUI

@main
struct OdysseyWindowSplitterApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Odyssey Window Splitter", systemImage: "rectangle.split.3x1") {
            SplitterMenuView()
                .environmentObject(appState)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
