import Foundation

protocol TranslationProvider {
    var name: String { get }

    func translate(
        text: String,
        configuration: ProviderConfiguration
    ) async throws -> String
}

enum TranslationProviderError: LocalizedError {
    case missingAPIKey(provider: String)
    case invalidBaseURL(provider: String, message: String)
    case invalidAPIKey(provider: String)
    case forbidden(provider: String)
    case unreachable(provider: String, message: String)
    case networkError(provider: String, message: String)
    case malformedResponse(provider: String)
    case unsupportedResponseFormat(provider: String)
    case notImplemented(provider: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "\(provider) API key is missing."
        case .invalidBaseURL(let provider, let message):
            return "\(provider) base URL is invalid: \(message)"
        case .invalidAPIKey(let provider):
            return "\(provider) API key was rejected. Check the key and try again."
        case .forbidden(let provider):
            return "\(provider) request was forbidden. Check account access, model permissions, or provider policy."
        case .unreachable(let provider, let message):
            return "\(provider) is unreachable: \(message)"
        case .networkError(let provider, let message):
            return "\(provider) network error: \(message)"
        case .malformedResponse(let provider):
            return "\(provider) returned an unexpected response."
        case .unsupportedResponseFormat(let provider):
            return "\(provider) returned a response format JellyTranslate does not support yet."
        case .notImplemented(let provider):
            return "\(provider) is coming soon."
        }
    }
}
