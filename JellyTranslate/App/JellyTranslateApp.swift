import SwiftUI

@main
struct JellyTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(settingsStore: appDelegate.settingsStore)
        }
    }
}
