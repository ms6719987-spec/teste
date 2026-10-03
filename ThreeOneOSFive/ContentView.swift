import SwiftUI

struct ContentView: View {
    @State private var showSettings = false
    @State private var showLogs = false

    var body: some View {
        PatchProjectsView(
            onOpenSettings: { showSettings = true },
            onOpenLogs: { showLogs = true }
        )
        .tint(AppTheme.accent)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
    }
}
