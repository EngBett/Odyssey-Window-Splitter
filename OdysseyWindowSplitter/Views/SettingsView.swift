import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage(SettingsKeys.gapSize) private var gapSize: Double = SettingsKeys.defaultGap
    @AppStorage(SettingsKeys.shortcutsEnabled) private var shortcutsEnabled = true
    @State private var launchAtLogin = false
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Section("Accessibility") {
                PermissionHelpView()
            }

            Section("Layout") {
                Picker("Gap size", selection: $gapSize) {
                    ForEach(SettingsKeys.gapOptions, id: \.self) { value in
                        Text("\(Int(value)) points").tag(value)
                    }
                }
            }

            Section("Global Shortcuts") {
                Toggle("Enable global shortcuts", isOn: $shortcutsEnabled)
                    .onChange(of: shortcutsEnabled) { _, enabled in
                        appState.setShortcutsEnabled(enabled)
                    }
                if !appState.shortcutConflicts.isEmpty {
                    Text("Could not register: \(appState.shortcutConflicts.joined(separator: ", "))")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                ForEach(GlobalShortcutManager.definitions, id: \.layout) { definition in
                    HStack {
                        Text("⌃⌥\(definition.keyLabel)")
                            .monospaced()
                        Spacer()
                        Text(definition.layout.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        updateLaunchAtLogin(enabled)
                    }
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }

            Section("About") {
                LabeledContent("Odyssey Window Splitter", value: "Version \(appVersion)")
                Text("Moves and resizes the focused window into column layouts designed for ultrawide displays.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .onAppear {
            appState.refreshPermission()
            launchAtLogin = appState.launchAtLogin.isEnabled
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        guard enabled != appState.launchAtLogin.isEnabled else { return }
        do {
            try appState.launchAtLogin.setEnabled(enabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "Launch at login could not be updated: \(error.localizedDescription)"
            launchAtLogin = appState.launchAtLogin.isEnabled
        }
    }
}
