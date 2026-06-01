import Foundation

struct LanguageOption: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let openAIDescription: String

    static let common: [LanguageOption] = [
        LanguageOption(id: "auto", name: "Auto Detect", openAIDescription: "auto-detect the source language"),
        LanguageOption(id: "en", name: "English", openAIDescription: "English"),
        LanguageOption(id: "ru", name: "Russian", openAIDescription: "Russian"),
        LanguageOption(id: "sr", name: "Serbian", openAIDescription: "Serbian"),
        LanguageOption(id: "es", name: "Spanish", openAIDescription: "Spanish"),
        LanguageOption(id: "de", name: "German", openAIDescription: "German"),
        LanguageOption(id: "fr", name: "French", openAIDescription: "French"),
        LanguageOption(id: "it", name: "Italian", openAIDescription: "Italian"),
        LanguageOption(id: "pt", name: "Portuguese", openAIDescription: "Portuguese"),
        LanguageOption(id: "tr", name: "Turkish", openAIDescription: "Turkish"),
        LanguageOption(id: "uk", name: "Ukrainian", openAIDescription: "Ukrainian"),
        LanguageOption(id: "zh", name: "Chinese", openAIDescription: "Chinese"),
        LanguageOption(id: "ja", name: "Japanese", openAIDescription: "Japanese"),
        LanguageOption(id: "ko", name: "Korean", openAIDescription: "Korean")
    ]

    static var translationTargets: [LanguageOption] {
        common.filter { $0.id != "auto" }
    }

    static func displayName(for id: String) -> String {
        common.first { $0.id == id }?.name ?? id.uppercased()
    }

    static func displayName(for id: String, language: AppLanguage) -> String {
        guard language == .russian else { return displayName(for: id) }
        let names = [
            "auto": "Автоопределение",
            "en": "Английский",
            "ru": "Русский",
            "sr": "Сербский",
            "es": "Испанский",
            "de": "Немецкий",
            "fr": "Французский",
            "it": "Итальянский",
            "pt": "Португальский",
            "tr": "Турецкий",
            "uk": "Украинский",
            "zh": "Китайский",
            "ja": "Японский",
            "ko": "Корейский"
        ]
        return names[id] ?? displayName(for: id)
    }

    static func providerDescription(for id: String) -> String {
        common.first { $0.id == id }?.openAIDescription ?? id
    }

    static func badgeCode(for id: String) -> String {
        id == "auto" ? "Auto" : id.uppercased()
    }
}
