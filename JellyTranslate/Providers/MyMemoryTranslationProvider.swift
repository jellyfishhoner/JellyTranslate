import Foundation

struct MyMemoryTranslationProvider: TranslationProvider {
    let name = "MyMemory"
    private let maxRequestBytes = 480

    func translate(text: String, configuration: ProviderConfiguration) async throws -> String {
        let chunks = chunksForTranslation(text)
        guard !chunks.isEmpty else {
            throw TranslationProviderError.malformedResponse(provider: name)
        }

        var translatedChunks: [String] = []
        for chunk in chunks {
            let translated = try await translateChunk(chunk, configuration: configuration)
            translatedChunks.append(translated)
        }

        return translatedChunks.joined(separator: " ")
            .replacingOccurrences(of: " \n ", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func translateChunk(_ text: String, configuration: ProviderConfiguration) async throws -> String {
        let endpoint = try endpointURL(text: text, configuration: configuration)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 12

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

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TranslationProviderError.networkError(provider: name, message: "HTTP \(httpResponse.statusCode)")
        }

        do {
            let decoded = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
            let status = decoded.responseStatus?.value ?? 200
            if status == 401 {
                throw TranslationProviderError.invalidAPIKey(provider: name)
            }
            if status == 403 {
                throw TranslationProviderError.forbidden(provider: name)
            }
            if status == 429 || decoded.responseDetails?.string.localizedCaseInsensitiveContains("quota") == true {
                throw TranslationProviderError.networkError(provider: name, message: "Free MyMemory quota is reached. Add a contact email in Settings to raise the free daily limit, or try again later.")
            }
            if status != 200 {
                throw TranslationProviderError.networkError(provider: name, message: decoded.responseDetails?.string ?? "Unexpected MyMemory status \(status).")
            }

            let translated = bestTranslation(from: decoded)
            guard !translated.isEmpty else {
                throw TranslationProviderError.malformedResponse(provider: name)
            }
            return translated
        } catch let providerError as TranslationProviderError {
            throw providerError
        } catch {
            throw TranslationProviderError.malformedResponse(provider: name)
        }
    }

    private func endpointURL(text: String, configuration: ProviderConfiguration) throws -> URL {
        guard var components = URLComponents(string: "https://api.mymemory.translated.net/get") else {
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "Could not build MyMemory endpoint.")
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "\(sourceLanguage(for: configuration.sourceLanguage, text: text))|\(configuration.targetLanguage)"),
            URLQueryItem(name: "mt", value: "1")
        ]
        if let email = configuration.contactEmail?.trimmingCharacters(in: .whitespacesAndNewlines),
           !email.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "de", value: email))
        }

        guard let url = components.url else {
            throw TranslationProviderError.invalidBaseURL(provider: name, message: "Could not encode MyMemory request.")
        }
        return url
    }

    private func sourceLanguage(for language: String, text: String) -> String {
        guard language == "auto" else { return language }
        return text.range(of: "\\p{Cyrillic}", options: .regularExpression) == nil ? "en" : "ru"
    }

    private func bestTranslation(from response: MyMemoryResponse) -> String {
        let responseTranslation = response.responseData.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let bestMatch = response.matches?
            .compactMap { match -> (translation: String, score: Double)? in
                let translation = match.translation.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !translation.isEmpty else { return nil }
                let quality = Double(match.quality?.value ?? 0) / 100.0
                let score = max(match.match?.value ?? 0, quality)
                return (translation, score)
            }
            .sorted { $0.score > $1.score }
            .first

        if let bestMatch, bestMatch.score >= 0.75 {
            return bestMatch.translation
        }
        return responseTranslation
    }

    private func chunksForTranslation(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        if trimmed.utf8.count <= maxRequestBytes {
            return [trimmed]
        }

        var chunks: [String] = []
        for paragraph in trimmed.components(separatedBy: .newlines) {
            let cleanParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanParagraph.isEmpty else {
                chunks.append("\n")
                continue
            }
            chunks.append(contentsOf: wordChunks(cleanParagraph))
            chunks.append("\n")
        }
        if chunks.last == "\n" {
            chunks.removeLast()
        }
        return chunks
    }

    private func wordChunks(_ text: String) -> [String] {
        var chunks: [String] = []
        var current = ""
        for word in text.split(separator: " ", omittingEmptySubsequences: false).map(String.init) {
            let candidate = current.isEmpty ? word : "\(current) \(word)"
            if candidate.utf8.count <= maxRequestBytes {
                current = candidate
            } else {
                if !current.isEmpty {
                    chunks.append(current)
                }
                current = word.utf8.count <= maxRequestBytes ? word : String(word.prefix(maxRequestBytes / 2))
            }
        }
        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks
    }
}

private struct MyMemoryResponse: Decodable {
    let responseData: MyMemoryResponseData
    let responseStatus: FlexibleInt?
    let responseDetails: FlexibleString?
    let matches: [MyMemoryMatch]?
}

private struct MyMemoryResponseData: Decodable {
    let translatedText: String
}

private struct MyMemoryMatch: Decodable {
    let translation: String
    let match: FlexibleDouble?
    let quality: FlexibleInt?
}

private struct FlexibleInt: Decodable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let string = try? container.decode(String.self), let int = Int(string) {
            value = int
        } else {
            value = 0
        }
    }
}

private struct FlexibleDouble: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self), let double = Double(string) {
            value = double
        } else {
            value = 0
        }
    }
}

private struct FlexibleString: Decodable {
    let string: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self.string = string
        } else if let int = try? container.decode(Int.self) {
            string = String(int)
        } else {
            string = ""
        }
    }
}
