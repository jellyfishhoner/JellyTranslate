import Foundation

struct ProviderConfiguration {
    let sourceLanguage: String
    let targetLanguage: String
    let apiKey: String?
    let model: String
    let baseURL: String?
    let path: String?
    let contactEmail: String?

    init(sourceLanguage: String,
         targetLanguage: String,
         apiKey: String?,
         model: String = "gpt-5.2",
         baseURL: String? = nil,
         path: String? = nil,
         contactEmail: String? = nil) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.path = path
        self.contactEmail = contactEmail
    }
}
