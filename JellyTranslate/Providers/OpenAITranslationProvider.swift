import Foundation

struct OpenAITranslationProvider: TranslationProvider {
    let name = "OpenAI"
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    func translate(text: String, configuration: ProviderConfiguration) async throws -> String {
        guard let apiKey = configuration.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw TranslationProviderError.missingAPIKey(provider: name)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(OpenAITranslationRequest(
            model: configuration.model,
            instructions: instructions(for: configuration),
            input: text
        ))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranslationProviderError.networkError(provider: name, message: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationProviderError.networkError(provider: name, message: "No HTTP response was received.")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            let decoded = try decodeResponse(data)
            let translated = decoded.bestText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !translated.isEmpty else {
                throw TranslationProviderError.malformedResponse(provider: name)
            }
            return translated
        case 401, 403:
            throw TranslationProviderError.invalidAPIKey(provider: name)
        default:
            let apiError = (try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data))?.error.message
            throw TranslationProviderError.networkError(
                provider: name,
                message: apiError ?? "HTTP \(httpResponse.statusCode)"
            )
        }
    }

    private func instructions(for configuration: ProviderConfiguration) -> String {
        let source = configuration.sourceLanguage == "auto"
            ? "auto-detect the source language"
            : LanguageOption.providerDescription(for: configuration.sourceLanguage)
        let target = LanguageOption.providerDescription(for: configuration.targetLanguage)
        return """
        You are JellyTranslate, a precise translation engine.
        Translate the user's text from \(source) to \(target).
        Return only the translated text. Do not add explanations, quotes, labels, or markdown.
        Preserve line breaks and basic punctuation.
        """
    }

    private func decodeResponse(_ data: Data) throws -> OpenAITranslationResponse {
        do {
            return try JSONDecoder().decode(OpenAITranslationResponse.self, from: data)
        } catch {
            throw TranslationProviderError.malformedResponse(provider: name)
        }
    }
}

private struct OpenAITranslationRequest: Encodable {
    let model: String
    let instructions: String
    let input: String
}

private struct OpenAITranslationResponse: Decodable {
    let outputText: String?
    let output: [OutputItem]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }

    var bestText: String {
        if let outputText, !outputText.isEmpty {
            return outputText
        }
        return output?
            .flatMap(\.content)
            .compactMap(\.text)
            .joined(separator: "\n") ?? ""
    }

    struct OutputItem: Decodable {
        let content: [ContentItem]
    }

    struct ContentItem: Decodable {
        let text: String?
    }
}

private struct OpenAIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
