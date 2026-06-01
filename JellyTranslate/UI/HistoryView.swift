import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyStore: HistoryStore
    let clipboardService: ClipboardService
    let isHistoryEnabled: Bool
    let language: AppLanguage

    @State private var searchText: String = ""

    private var filteredItems: [TranslationHistoryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return historyStore.items }
        return historyStore.items.filter { item in
            item.originalText.lowercased().contains(query)
                || item.translatedText.lowercased().contains(query)
                || item.providerName.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let errorMessage = historyStore.errorMessage {
                warningBanner(errorMessage)
            }

            if !isHistoryEnabled {
                emptyState(L10n.t("historyOff", language), L10n.t("historyOffHelp", language))
            } else if historyStore.items.isEmpty {
                emptyState(L10n.t("noRecentTranslations", language), L10n.t("noRecentTranslationsHelp", language))
            } else if filteredItems.isEmpty {
                emptyState(L10n.t("noResults", language), L10n.t("noResultsHelp", language))
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredItems) { item in
                            historyRow(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(22)
        .frame(minWidth: 660, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.t("history", language))
                    .font(.title2.weight(.semibold))
                Spacer()
                Button(L10n.t("clearAll", language), role: .destructive) {
                    historyStore.clear()
                }
                .disabled(historyStore.items.isEmpty)
            }

            TextField(L10n.t("searchHistory", language), text: $searchText)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func historyRow(_ item: TranslationHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.translatedText)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)
                        .textSelection(.enabled)

                    Text(item.originalText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    clipboardService.copy(item.translatedText)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help(L10n.t("copy", language))

                Button(role: .destructive) {
                    historyStore.delete(item)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help(L10n.t("delete", language))
            }

            HStack(spacing: 8) {
                Text(historyBadge(for: item))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.thinMaterial, in: Capsule())
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func warningBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button(language == .russian ? "Очистить" : "Clear") {
                historyStore.clear()
            }
            .controlSize(.small)
        }
        .padding(10)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func emptyState(_ title: String, _ message: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline.weight(.semibold))
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func historyBadge(for item: TranslationHistoryItem) -> String {
        let pair = "\(LanguageOption.badgeCode(for: item.sourceLanguage)) → \(LanguageOption.badgeCode(for: item.targetLanguage))"
        if let modelName = item.modelName, !modelName.isEmpty {
            return "\(item.provider.shortName) · \(modelName) · \(pair)"
        }
        return "\(item.provider.shortName) · \(pair)"
    }
}
