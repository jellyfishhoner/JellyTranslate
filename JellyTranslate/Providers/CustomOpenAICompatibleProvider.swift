import Foundation

struct CustomOpenAICompatibleProvider: TranslationProvider {
    let name = "Custom Provider"

    func translate(text: String, configuration: ProviderConfiguration) async throws -> String {
        guard let apiKey = configuration.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw TranslationProviderError.missingAPIKey(provider: name)
        }

        let endpoint = try endpointURL(from: configuration)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(ChatCompletionRequest(
            model: configuration.model,
            messages: [
                ChatMessage(role: "system", content: instructions(for: configuration)),
                ChatMessage(role: "user", content: text)
            ],
            temperature: 0
        ))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranslationProviderError.unreachable(provider: name, message: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationProviderError.unreachable(provider: name, message: "No HTTP response was received.")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            let translated = try decodeText(from: data).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !translated.isEmpty else {
                throw TranslationProviderError.unsupportedResponseFormat(provider: name)
            }
            return translated
        case 401:
            throw TranslationProviderError.invalidAPIKey(provider: name)
        case 403:
            throw TranslationProviderError.forbidden(provider: name)
        default:
            let apiError = (try? JSONDecoder().decode(ProviderErrorResponse.self, from: data))?.error.message
            throw TranslationProviderError.networkError(provider: name, message: apiError ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    private func endpointURL(from configuration: ProviderConfiguration) throws -> URL {
        let rawBaseURL = configuration.baseURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawBaseURL.isEmpty else {
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "Base URL must not be empty.")
        }
        guard var components = URLComponents(string: rawBaseURL),
              let scheme = components.scheme?.lowercased(),
              components.host != nil else {
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "Enter a valid URL such as https://api.example.com.")
        }

        #if !DEBUG
        guard scheme == "https" else {
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "HTTPS is required outside DEBUG builds.")
        }
        #else
        guard scheme == "https" || scheme == "http" else {
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "URL must use https://, or http:// in DEBUG builds.")
        }
        #endif

        let path = normalizedPath(configuration.path)
        components.path = joinedPath(basePath: components.path, customPath: path)
        guard let url = components.url else {
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "Could not build the provider endpoint URL.")
        }
        return url
    }

    private func normalizedPath(_ path: String?) -> String {
        let trimmed = path?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "/v1/chat/completions" : trimmed
    }

    private func joinedPath(basePath: String, customPath: String) -> String {
        let cleanBase = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanCustom = customPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if cleanBase.isEmpty {
            return "/" + cleanCustom
        }
        if cleanCustom.isEmpty {
            return "/" + cleanBase
        }
        return "/" + cleanBase + "/" + cleanCustom
    }

    private func instructions(for configuration: ProviderConfiguration) -> String {
        let source = configuration.sourceLanguage == "auto"
            ? "auto-detect the source language"
            : LanguageOption.providerDescription(for: configuration.sourceLanguage)
        let target = LanguageOption.providerDescription(for: configuration.targetLanguage)
        return """
        Translate the user's text from \(source) to \(target).
        Return only the translated text. Do not add explanations, labels, markdown, or quotes.
        Preserve line breaks and basic punctuation.
        """
    }

    private func decodeText(from data: Data) throws -> String {
        if let chatResponse = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
           let text = chatResponse.bestText,
           !text.isEmpty {
            return text
        }
        if let response = try? JSONDecoder().decode(ResponsesStyleFallback.self, from: data),
           let text = response.outputText,
           !text.isEmpty {
            return text
        }
        throw TranslationProviderError.malformedResponse(provider: name)
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    var bestText: String? {
        choices.first?.message?.content ?? choices.first?.text
    }

    struct Choice: Decodable {
        let message: ChatMessage?
        let text: String?
    }
}

private struct ResponsesStyleFallback: Decodable {
    let outputText: String?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
    }
}

private struct ProviderErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
