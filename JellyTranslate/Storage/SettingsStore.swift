import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet { save() }
    }

    private let defaultsKey = "JellyTranslate.settings"
    private let keychainService: KeychainService

    init(keychainService: KeychainService = .shared) {
        self.keychainService = keychainService
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = Self.migrateSettings(decoded)
        } else {
            settings = AppSettings()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    func apiKey(for provider: TranslationProviderKind) -> String {
        (try? keychainService.readAPIKey(for: provider)) ?? ""
    }

    func saveAPIKey(_ apiKey: String, for provider: TranslationProviderKind) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            try keychainService.deleteAPIKey(for: provider)
        } else {
            try keychainService.saveAPIKey(trimmed, for: provider)
        }
        objectWillChange.send()
    }

    private static func migrateSettings(_ settings: AppSettings) -> AppSettings {
        var migrated = settings
        if migrated.hotkey == "control+option+t", migrated.secondaryHotkey.isEmpty {
            migrated.hotkey = AppSettings().hotkey
            migrated.secondaryHotkey = AppSettings().secondaryHotkey
        }
        if migrated.provider == .mock {
            migrated.provider = .myMemory
        }
        return migrated
    }
}
