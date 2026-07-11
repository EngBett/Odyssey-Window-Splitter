import SwiftUI

struct PermissionHelpView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                appState.isTrusted ? "Accessibility permission granted" : "Accessibility permission required",
                systemImage: appState.isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .foregroundStyle(appState.isTrusted ? .green : .orange)

            if !appState.isTrusted {
                Text("Odyssey Window Splitter needs Accessibility permission to move and resize windows from other applications. Enable it in System Settings → Privacy & Security → Accessibility. You may need to quit and reopen the app after enabling it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("Request Permission") {
                        appState.requestPermission()
                    }
                    Button("Open Accessibility Settings") {
                        appState.openAccessibilitySettings()
                    }
                }
            }
        }
    }
}
