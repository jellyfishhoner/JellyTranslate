import SwiftUI

struct ProviderDisplayItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let isAvailable: Bool
    let badge: String
}

extension ProviderDisplayItem {
    static func translationProviders(language: AppLanguage) -> [ProviderDisplayItem] {
        [
            ProviderDisplayItem(
                id: TranslationProviderKind.myMemory.rawValue,
                title: "MyMemory",
                subtitle: language == .russian
                    ? "Работает сейчас. Настройка не нужна."
                    : "Available now. No setup needed.",
                isAvailable: true,
                badge: language == .russian ? "Готово" : "Ready"
            ),
            ProviderDisplayItem(
                id: "DeepL",
                title: "DeepL",
                subtitle: language == .russian
                    ? "Добавим как более точный переводчик."
                    : "Coming later as a more precise translator.",
                isAvailable: false,
                badge: "Soon..."
            ),
            ProviderDisplayItem(
                id: "YandexTranslate",
                title: "Yandex Translate",
                subtitle: language == .russian
                    ? "Добавим отдельным вариантом перевода."
                    : "Coming later as another translation option.",
                isAvailable: false,
                badge: "Soon..."
            ),
            ProviderDisplayItem(
                id: "GoogleTranslate",
                title: "Google Translate",
                subtitle: language == .russian
                    ? "Добавим после базовой стабильной версии."
                    : "Coming after the stable base version.",
                isAvailable: false,
                badge: "Soon..."
            ),
            ProviderDisplayItem(
                id: "OpenAI",
                title: "OpenAI",
                subtitle: language == .russian
                    ? "Для умного перевода и будущих режимов."
                    : "For smarter translation and future modes.",
                isAvailable: false,
                badge: "Soon..."
            )
        ]
    }
}

struct ProviderOptionCard: View {
    let item: ProviderDisplayItem
    let isSelected: Bool
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        Group {
            if item.isAvailable {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .opacity(item.isAvailable ? 1 : 0.72)
        .accessibilityLabel(accessibilityLabel)
    }

    private var cardContent: some View {
        HStack(spacing: isCompact ? 9 : 12) {
            Image(systemName: item.isAvailable ? "checkmark.circle.fill" : "lock.fill")
                .font((isCompact ? Font.callout : Font.title3).weight(.semibold))
                .foregroundStyle(item.isAvailable ? Color.accentColor : Color.secondary)
                .frame(width: isCompact ? 18 : 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font((isCompact ? Font.caption : Font.callout).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(item.badge)
                        .font((isCompact ? Font.caption2 : Font.caption).weight(.semibold))
                        .padding(.horizontal, isCompact ? 6 : 7)
                        .padding(.vertical, isCompact ? 2 : 3)
                        .foregroundStyle(item.isAvailable ? Color.accentColor : Color.secondary)
                        .background(
                            Capsule()
                                .fill(item.isAvailable ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.12))
                        )
                }

                if !isCompact {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(isCompact ? 10 : 12)
        .frame(minHeight: isCompact ? 48 : nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundShape)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        }
    }

    private var backgroundShape: some ShapeStyle {
        isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.45)
        }
        return Color.secondary.opacity(0.14)
    }

    private var accessibilityLabel: String {
        item.isAvailable ? "\(item.title), \(item.badge)" : "\(item.title), locked, \(item.badge)"
    }
}
