import Foundation

enum TranslationProviderKind: String, Codable, CaseIterable, Identifiable {
    case mock = "Mock"
    case openAI = "OpenAI"
    case customOpenAI = "Custom"
    case libreTranslate = "LibreTranslate"
    case myMemory = "MyMemory"
    case deepL = "DeepL"

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "Mock", "Mock Provider":
            self = .mock
        case "OpenAI", "OpenAI Provider":
            self = .openAI
        case "Custom", "Custom OpenAI-Compatible API":
            self = .customOpenAI
        case "LibreTranslate", "LibreTranslate Provider":
            self = .libreTranslate
        case "MyMemory", "MyMemory Provider":
            self = .myMemory
        case "DeepL", "DeepL Provider":
            self = .deepL
        default:
            self = .mock
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var shortName: String {
        switch self {
        case .mock:
            return "Mock"
        case .openAI:
            return "OpenAI"
        case .customOpenAI:
            return "Custom"
        case .libreTranslate:
            return "LibreTranslate"
        case .myMemory:
            return "MyMemory"
        case .deepL:
            return "DeepL"
        }
    }

    var displayName: String {
        switch self {
        case .mock:
            return "Mock Provider"
        case .openAI:
            return "OpenAI Provider"
        case .customOpenAI:
            return "Custom OpenAI-Compatible API"
        case .libreTranslate:
            return "LibreTranslate Provider"
        case .myMemory:
            return "MyMemory Provider"
        case .deepL:
            return "DeepL Provider"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var sourceLanguage: String = "auto"
    var targetLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    var hotkey: String = "control+option+t"
    var secondaryHotkey: String = "control+option+r"
    var provider: TranslationProviderKind = .myMemory
    var appLanguage: AppLanguage = .systemDefault
    var myMemoryContactEmail: String = ""
    var customProviderBaseURL: String = ""
    var customProviderPath: String = "/v1/chat/completions"
    var customProviderModel: String = "gpt-4o-mini"
    var libreTranslateBaseURL: String = "https://libretranslate.com"
    var showPopupNearCursor: Bool = true
    var closePopupAfterCopy: Bool = false
    var launchAtLogin: Bool = false
    var saveTranslationHistory: Bool = true
    var shareAnonymousAnalytics: Bool = false

    enum CodingKeys: String, CodingKey {
        case sourceLanguage
        case targetLanguage
        case hotkey
        case secondaryHotkey
        case provider
        case appLanguage
        case myMemoryContactEmail
        case customProviderBaseURL
        case customProviderPath
        case customProviderModel
        case libreTranslateBaseURL
        case showPopupNearCursor
        case closePopupAfterCopy
        case launchAtLogin
        case saveTranslationHistory
        case shareAnonymousAnalytics
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()
        sourceLanguage = try container.decodeIfPresent(String.self, forKey: .sourceLanguage) ?? defaults.sourceLanguage
        targetLanguage = try container.decodeIfPresent(String.self, forKey: .targetLanguage) ?? defaults.targetLanguage
        hotkey = try container.decodeIfPresent(String.self, forKey: .hotkey) ?? defaults.hotkey
        secondaryHotkey = try container.decodeIfPresent(String.self, forKey: .secondaryHotkey) ?? defaults.secondaryHotkey
        provider = try container.decodeIfPresent(TranslationProviderKind.self, forKey: .provider) ?? defaults.provider
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? defaults.appLanguage
        myMemoryContactEmail = try container.decodeIfPresent(String.self, forKey: .myMemoryContactEmail) ?? defaults.myMemoryContactEmail
        customProviderBaseURL = try container.decodeIfPresent(String.self, forKey: .customProviderBaseURL) ?? defaults.customProviderBaseURL
        customProviderPath = try container.decodeIfPresent(String.self, forKey: .customProviderPath) ?? defaults.customProviderPath
        customProviderModel = try container.decodeIfPresent(String.self, forKey: .customProviderModel) ?? defaults.customProviderModel
        libreTranslateBaseURL = try container.decodeIfPresent(String.self, forKey: .libreTranslateBaseURL) ?? defaults.libreTranslateBaseURL
        showPopupNearCursor = try container.decodeIfPresent(Bool.self, forKey: .showPopupNearCursor) ?? defaults.showPopupNearCursor
        closePopupAfterCopy = try container.decodeIfPresent(Bool.self, forKey: .closePopupAfterCopy) ?? defaults.closePopupAfterCopy
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? defaults.launchAtLogin
        saveTranslationHistory = try container.decodeIfPresent(Bool.self, forKey: .saveTranslationHistory) ?? defaults.saveTranslationHistory
        shareAnonymousAnalytics = try container.decodeIfPresent(Bool.self, forKey: .shareAnonymousAnalytics) ?? defaults.shareAnonymousAnalytics
    }
}
