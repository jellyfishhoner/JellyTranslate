import Foundation
import Combine

final class HistoryStore: ObservableObject {
    @Published private(set) var items: [TranslationHistoryItem] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isCorrupted: Bool = false

    private let fileURL: URL
    private let fileManager: FileManager
    private let duplicateWindow: TimeInterval = 4

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("JellyTranslate", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("history.json")
        load()
    }

    func add(_ item: TranslationHistoryItem) {
        guard !item.originalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !item.translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        guard !isRecentDuplicate(item) else { return }
        items.insert(item, at: 0)
        save()
    }

    func clear() {
        items.removeAll()
        errorMessage = nil
        isCorrupted = false
        save()
    }

    func delete(_ item: TranslationHistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func cachedItem(originalText: String,
                    sourceLanguage: String,
                    targetLanguage: String,
                    provider: TranslationProviderKind) -> TranslationHistoryItem? {
        let normalizedOriginal = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedOriginal.isEmpty else { return nil }

        return items.first { item in
            item.originalText == normalizedOriginal
                && item.sourceLanguage == sourceLanguage
                && item.targetLanguage == targetLanguage
                && item.providerName == provider.rawValue
                && !item.translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            items = try JSONDecoder.historyDecoder.decode([TranslationHistoryItem].self, from: data)
            errorMessage = nil
            isCorrupted = false
        } catch {
            items = []
            errorMessage = "History file could not be read. It may be corrupted. You can clear history to recover."
            isCorrupted = true
            backupCorruptedHistoryFile()
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder.prettyHistoryEncoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
            errorMessage = nil
            isCorrupted = false
        } catch {
            errorMessage = "History could not be saved: \(error.localizedDescription)"
        }
    }

    private func isRecentDuplicate(_ item: TranslationHistoryItem) -> Bool {
        items.prefix(20).contains { existing in
            existing.originalText == item.originalText
                && existing.translatedText == item.translatedText
                && existing.sourceLanguage == item.sourceLanguage
                && existing.targetLanguage == item.targetLanguage
                && existing.providerName == item.providerName
                && (existing.id == item.id || abs(existing.createdAt.timeIntervalSince(item.createdAt)) <= duplicateWindow)
        }
    }

    private func backupCorruptedHistoryFile() {
        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("history.corrupted.\(Int(Date().timeIntervalSince1970)).json")
        try? fileManager.copyItem(at: fileURL, to: backupURL)
    }
}

private extension JSONEncoder {
    static var prettyHistoryEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var historyDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
