import AppKit
import ApplicationServices
import os

enum PermissionService {
    private static let logger = Logger(subsystem: "app.jellytranslate.JellyTranslate", category: "permissions")

    static var isAccessibilityTrusted: Bool {
        let trusted = AXIsProcessTrusted()
        #if DEBUG
        logger.debug("current bundleIdentifier=\(Bundle.main.bundleIdentifier ?? "unknown", privacy: .public)")
        logger.debug("current executable path=\(Bundle.main.executablePath ?? "unknown", privacy: .public)")
        #endif
        logger.debug("\(trusted ? "accessibility_trusted_true" : "accessibility_trusted_false")")
        return trusted
    }

    static var currentAccessibilityTrust: Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func promptForAccessibilityIfNeeded() {
        if AXIsProcessTrusted() {
            logger.debug("accessibility_prompt_skipped")
            return
        }

        logger.debug("accessibility_prompt_requested_manually")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        promptForAccessibilityIfNeeded()
        openPrivacyPane(anchor: "Privacy_Accessibility")
    }

    static func openInputMonitoringSettings() {
        openPrivacyPane(anchor: "Privacy_ListenEvent")
    }

    private static func openPrivacyPane(anchor: String) {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?\(anchor)"
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
