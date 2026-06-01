import Foundation

struct DeepLTranslationProvider: TranslationProvider {
    let name = "DeepL"

    func translate(text: String, configuration: ProviderConfiguration) async throws -> String {
        // TODO: Implement real DeepL API support after the OpenAI provider is validated.
        throw TranslationProviderError.notImplemented(provider: name)
    }
}
