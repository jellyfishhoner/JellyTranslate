import SwiftUI

struct PopupView: View {
    static let preferredSize = CGSize(width: 520, height: 340)

    let state: PopupPresentationState
    let onCopy: () -> Void
    let onReplace: () -> Void
    let onSpeak: () -> Void
    let onHistory: () -> Void
    let onTargetLanguageChange: (String) -> Void
    let onRecoveryAction: (PopupRecoveryAction) -> Void
    let onClose: () -> Void
    let language: AppLanguage
    let targetLanguage: String
    let actionFeedback: String?

    @State private var isVisible = false

    var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)

            LinearGradient(colors: [
                Color.white.opacity(0.20),
                Color.cyan.opacity(0.08),
                Color.indigo.opacity(0.06)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .allowsHitTesting(false)

            content
        }
        .frame(width: Self.preferredSize.width, height: Self.preferredSize.height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(borderGradient, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 28, x: 0, y: 18)
        .scaleEffect(isVisible ? 1 : 0.965, anchor: .topTrailing)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            originalPreview
            translatedArea
            actionBar
        }
        .padding(20)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("JellyTranslate")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if let indicator = indicatorText {
                Text(indicator)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }

            targetLanguagePicker

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 24, height: 24)
            }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
                .background(.thinMaterial, in: Circle())
        }
    }

    private var targetLanguagePicker: some View {
        Picker(L10n.t("targetLanguage", language), selection: Binding(
            get: { targetLanguage },
            set: { onTargetLanguageChange($0) }
        )) {
            ForEach(LanguageOption.translationTargets) { option in
                Text(LanguageOption.displayName(for: option.id, language: language)).tag(option.id)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .controlSize(.small)
        .frame(width: 92)
        .help(L10n.t("targetLanguage", language))
    }

    private var originalPreview: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L10n.t("original", language))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            Text(state.originalText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var translatedArea: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(titleForTranslatedArea)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                Spacer()
                if case .loading = state {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ScrollView(.vertical) {
                Text(state.translatedText(language: language))
                    .font(translatedFont)
                    .foregroundStyle(translatedColor)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 4)
            }
            .scrollIndicators(.visible)
            .frame(maxHeight: 118)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150, alignment: .topLeading)
        .background(translatedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button(action: onCopy) {
                Label(L10n.t("copy", language), systemImage: "doc.on.doc")
            }
                .disabled(!state.isActionableResult)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(PrimaryPopupButtonStyle(isEnabled: state.isActionableResult))

            Button(action: onReplace) {
                Label(L10n.t("replace", language), systemImage: "text.cursor")
            }
                .disabled(!state.isActionableResult)
                .buttonStyle(PrimaryPopupButtonStyle(isEnabled: state.isActionableResult))

            Spacer()

            if let action = state.recoveryAction {
                Button(action.buttonTitle(language: language)) {
                    onRecoveryAction(action)
                }
                .buttonStyle(PrimaryPopupButtonStyle(isEnabled: true))
            }

            if let actionFeedback {
                Text(actionFeedback)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }

            Button(action: onSpeak) {
                Label(L10n.t("speak", language), systemImage: "speaker.wave.2")
            }
            .buttonStyle(SecondaryPopupButtonStyle())
            .help(L10n.t("speak", language))

            Button(action: onHistory) {
                Label(L10n.t("history", language), systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(SecondaryPopupButtonStyle())
            .help(L10n.t("history", language))
        }
        .controlSize(.small)
        .frame(height: 32)
    }

    private var indicatorText: String? {
        let provider = state.provider?.shortName
        let model = state.modelName
        let pair = state.languagePair
        switch (provider, model, pair) {
        case (.some("Mock"), _, .some(let pair)):
            return "\(provider ?? "Mock") · \(L10n.t("test", language)) · \(pair)"
        case (.some(let provider), .some(let model), .some(let pair)):
            return "\(provider) · \(model) · \(pair)"
        case (.some(let provider), .none, .some(let pair)):
            return "\(provider) · \(pair)"
        case (.some(let provider), .some(let model), .none):
            return "\(provider) · \(model)"
        case (.some(let provider), .none, .none):
            return provider
        case (.none, _, .some(let pair)):
            return pair
        case (.none, .some(let model), .none):
            return model
        case (.none, .none, .none):
            return nil
        }
    }

    private var titleForTranslatedArea: String {
        switch state {
        case .success:
            return L10n.t("translation", language)
        case .loading:
            return L10n.t("working", language)
        case .empty:
            return L10n.t("emptySelection", language)
        case .error:
            return L10n.t("needsAttention", language)
        }
    }

    private var translatedFont: Font {
        switch state {
        case .success:
            return .title3.weight(.semibold)
        default:
            return .body.weight(.medium)
        }
    }

    private var translatedColor: Color {
        switch state {
        case .error:
            return .red
        case .empty:
            return .secondary
        default:
            return .primary
        }
    }

    private var translatedBackground: some ShapeStyle {
        switch state {
        case .error:
            return AnyShapeStyle(Color.red.opacity(0.09))
        case .empty:
            return AnyShapeStyle(Color.secondary.opacity(0.08))
        case .loading:
            return AnyShapeStyle(Color.cyan.opacity(0.08))
        case .success:
            return AnyShapeStyle(.regularMaterial)
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(colors: [
            .white.opacity(0.34),
            .white.opacity(0.10),
            .cyan.opacity(0.18)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct PrimaryPopupButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.42)
    }
}

private struct SecondaryPopupButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .labelStyle(.iconOnly)
            .foregroundStyle(.secondary)
            .frame(width: 30, height: 30)
            .background(configuration.isPressed ? Color.primary.opacity(0.08) : Color.clear, in: Circle())
    }
}
