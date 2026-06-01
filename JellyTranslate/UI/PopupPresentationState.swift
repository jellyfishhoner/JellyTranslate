import Foundation

enum PopupPresentationState: Equatable {
    case loading(message: String)
    case success(TranslationHistoryItem)
    case empty(message: String)
    case error(title: String, message: String, sourceLanguage: String, targetLanguage: String, provider: TranslationProviderKind, action: PopupRecoveryAction?)
}

enum PopupRecoveryAction: String, Equatable {
    case accessibilitySettings
    case inputMonitoringSettings

    func buttonTitle(language: AppLanguage) -> String {
        switch self {
        case .accessibilitySettings:
            return L10n.t("openSettings", language)
        case .inputMonitoringSettings:
            return L10n.t("openSettings", language)
        }
    }
}

extension PopupPresentationState {
    var provider: TranslationProviderKind? {
        switch self {
        case .success(let item):
            return item.provider
        case .error(_, _, _, _, let provider, _):
            return provider
        case .loading, .empty:
            return nil
        }
    }

    var languagePair: String? {
        switch self {
        case .success(let item):
            return "\(LanguageOption.badgeCode(for: item.sourceLanguage)) → \(LanguageOption.badgeCode(for: item.targetLanguage))"
        case .error(_, _, let sourceLanguage, let targetLanguage, _, _):
            return "\(LanguageOption.badgeCode(for: sourceLanguage)) → \(LanguageOption.badgeCode(for: targetLanguage))"
        case .loading, .empty:
            return nil
        }
    }

    var modelName: String? {
        switch self {
        case .success(let item):
            return item.providerModel
        case .loading, .empty, .error:
            return nil
        }
    }

    var originalText: String {
        switch self {
        case .success(let item):
            return item.originalText
        case .error(let title, _, _, _, _, _):
            return title
        case .loading(let message), .empty(let message):
            return message
        }
    }

    var translatedText: String {
        translatedText(language: .english)
    }

    func translatedText(language: AppLanguage) -> String {
        switch self {
        case .success(let item):
            return item.translatedText
        case .error(_, let message, _, _, _, _):
            return message
        case .loading:
            return L10n.t("translating", language)
        case .empty:
            return L10n.t("emptySelectionHelp", language)
        }
    }

    var isActionableResult: Bool {
        if case .success = self { return true }
        return false
    }

    var recoveryAction: PopupRecoveryAction? {
        if case .error(_, _, _, _, _, let action) = self { return action }
        return nil
    }
}
