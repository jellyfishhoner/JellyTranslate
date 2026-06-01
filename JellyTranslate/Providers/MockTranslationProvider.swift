import Foundation

struct MockTranslationProvider: TranslationProvider {
    let name = "Mock"

    func translate(text: String, configuration: ProviderConfiguration) async throws -> String {
        "[\(configuration.targetLanguage)] " + text
    }
}
