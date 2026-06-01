import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .russian:
            return "Русский"
        }
    }

    static var systemDefault: AppLanguage {
        let code = Locale.current.language.languageCode?.identifier.lowercased()
        return code == "ru" ? .russian : .english
    }
}
