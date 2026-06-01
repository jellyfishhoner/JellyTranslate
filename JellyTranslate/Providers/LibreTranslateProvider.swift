import Foundation

struct LibreTranslateProvider: TranslationProvider {
    let name = "LibreTranslate"

    func translate(text: String, configuration: ProviderConfiguration) async throws -> String {
        let endpoint = try endpointURL(from: configuration)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LibreTranslateRequest(
            q: text,
            source: configuration.sourceLanguage,
            target: configuration.targetLanguage,
            format: "text",
            apiKey: normalizedAPIKey(configuration.apiKey)
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
            do {
                let decoded = try JSONDecoder().decode(LibreTranslateResponse.self, from: data)
                let translated = decoded.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !translated.isEmpty else {
                    throw TranslationProviderError.malformedResponse(provider: name)
                }
                return translated
            } catch let providerError as TranslationProviderError {
                throw providerError
            } catch {
                throw TranslationProviderError.malformedResponse(provider: name)
            }
        case 401:
            throw TranslationProviderError.invalidAPIKey(provider: name)
        case 403:
            throw TranslationProviderError.forbidden(provider: name)
        default:
            let apiError = (try? JSONDecoder().decode(LibreTranslateErrorResponse.self, from: data))?.error
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
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "Enter a valid LibreTranslate URL.")
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

        components.path = joinedPath(basePath: components.path, customPath: "/translate")
        guard let url = components.url else {
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "Could not build the LibreTranslate endpoint URL.")
        }
        return url
    }

    private func joinedPath(basePath: String, customPath: String) -> String {
        let cleanBase = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanCustom = customPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if cleanBase.isEmpty {
            return "/" + cleanCustom
        }
        return "/" + cleanBase + "/" + cleanCustom
    }

    private func normalizedAPIKey(_ apiKey: String?) -> String? {
        let trimmed = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct LibreTranslateRequest: Encodable {
    let q: String
    let source: String
    let target: String
    let format: String
    let apiKey: String?

    enum CodingKeys: String, CodingKey {
        case q
        case source
        case target
        case format
        case apiKey = "api_key"
    }
}

private struct LibreTranslateResponse: Decodable {
    let translatedText: String
}

private struct LibreTranslateErrorResponse: Decodable {
    let error: String
}
