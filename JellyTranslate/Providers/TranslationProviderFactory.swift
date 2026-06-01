import Foundation

enum TranslationProviderFactory {
    static func provider(for kind: TranslationProviderKind) -> TranslationProvider {
        switch kind {
        case .mock:
            return MockTranslationProvider()
        case .openAI:
            return OpenAITranslationProvider()
        case .customOpenAI:
            return CustomOpenAICompatibleProvider()
        case .libreTranslate:
            return LibreTranslateProvider()
        case .myMemory:
            return MyMemoryTranslationProvider()
        case .deepL:
            return DeepLTranslationProvider()
        }
    }
}
