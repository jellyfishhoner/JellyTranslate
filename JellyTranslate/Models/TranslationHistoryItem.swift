import Foundation

struct TranslationHistoryItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var originalText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var providerName: String
    var modelName: String?
    var characterCount: Int
    var isFavorite: Bool

    var provider: TranslationProviderKind {
        TranslationProviderKind(rawValue: providerName) ?? .mock
    }

    var providerModel: String? {
        modelName
    }

    init(id: UUID = UUID(),
         createdAt: Date = Date(),
         originalText: String,
         translatedText: String,
         sourceLanguage: String,
         targetLanguage: String,
         providerName: String,
         modelName: String? = nil,
         characterCount: Int? = nil,
         isFavorite: Bool = false) {
        self.id = id
        self.createdAt = createdAt
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.providerName = providerName
        self.modelName = modelName
        self.characterCount = characterCount ?? originalText.count
        self.isFavorite = isFavorite
    }

    init(id: UUID = UUID(),
         createdAt: Date = Date(),
         originalText: String,
         translatedText: String,
         sourceLanguage: String,
         targetLanguage: String,
         provider: TranslationProviderKind,
         providerModel: String? = nil,
         isFavorite: Bool = false) {
        self.init(id: id,
                  createdAt: createdAt,
                  originalText: originalText,
                  translatedText: translatedText,
                  sourceLanguage: sourceLanguage,
                  targetLanguage: targetLanguage,
                  providerName: provider.rawValue,
                  modelName: providerModel,
                  characterCount: originalText.count,
                  isFavorite: isFavorite)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case originalText
        case translatedText
        case sourceLanguage
        case targetLanguage
        case providerName
        case modelName
        case characterCount
        case isFavorite
        case legacyProvider = "provider"
        case legacyProviderModel = "providerModel"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        originalText = try container.decode(String.self, forKey: .originalText)
        translatedText = try container.decode(String.self, forKey: .translatedText)
        sourceLanguage = try container.decode(String.self, forKey: .sourceLanguage)
        targetLanguage = try container.decode(String.self, forKey: .targetLanguage)

        if let providerName = try container.decodeIfPresent(String.self, forKey: .providerName) {
            self.providerName = providerName
        } else if let legacyProvider = try container.decodeIfPresent(TranslationProviderKind.self, forKey: .legacyProvider) {
            providerName = legacyProvider.rawValue
        } else {
            providerName = TranslationProviderKind.mock.rawValue
        }

        modelName = try container.decodeIfPresent(String.self, forKey: .modelName)
            ?? container.decodeIfPresent(String.self, forKey: .legacyProviderModel)
        characterCount = try container.decodeIfPresent(Int.self, forKey: .characterCount) ?? originalText.count
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(originalText, forKey: .originalText)
        try container.encode(translatedText, forKey: .translatedText)
        try container.encode(sourceLanguage, forKey: .sourceLanguage)
        try container.encode(targetLanguage, forKey: .targetLanguage)
        try container.encode(providerName, forKey: .providerName)
        try container.encodeIfPresent(modelName, forKey: .modelName)
        try container.encode(characterCount, forKey: .characterCount)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
}
