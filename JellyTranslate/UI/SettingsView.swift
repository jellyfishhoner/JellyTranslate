import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    var onHotKeyChanged: (() -> Void)?
    var onLanguageChanged: (() -> Void)?
    var onClearHistory: (() -> Void)?

    @State private var openAIAPIKey: String = ""
    @State private var customAPIKey: String = ""
    @State private var libreTranslateAPIKey: String = ""
    @State private var keyStatusMessage: String = ""
    @State private var isAdvancedExpanded: Bool = false

    private var language: AppLanguage { settingsStore.settings.appLanguage }
    private var simpleProviderBinding: Binding<TranslationProviderKind> {
        Binding(
            get: {
                settingsStore.settings.provider == .openAI ? .openAI : .myMemory
            },
            set: { settingsStore.settings.provider = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                translationSection
                hotkeySection
                behaviorSection
                advancedSection
                privacySection
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 620, minHeight: 620)
        .onAppear {
            openAIAPIKey = settingsStore.apiKey(for: .openAI)
            customAPIKey = settingsStore.apiKey(for: .customOpenAI)
            libreTranslateAPIKey = settingsStore.apiKey(for: .libreTranslate)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("JellyTranslate")
                .font(.title2.weight(.semibold))
            Text(language == .russian ? "Выделите текст, нажмите хоткей, получите перевод." : "Select text, press the hotkey, get a translation.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 2)
    }

    private var translationSection: some View {
        settingsSection(L10n.t("translationSettings", language)) {
            settingsRow(L10n.t("provider", language)) {
                Picker(L10n.t("provider", language), selection: simpleProviderBinding) {
                    Text(L10n.t("myMemory", language)).tag(TranslationProviderKind.myMemory)
                    Text(L10n.t("openAI", language)).tag(TranslationProviderKind.openAI)
                }
                .labelsHidden()
                .frame(maxWidth: 260)
            }

            if ![TranslationProviderKind.myMemory, .openAI].contains(settingsStore.settings.provider) {
                helperText("\(L10n.t("currentAdvancedProvider", language)) \(settingsStore.settings.provider.displayName)")
            }

            simpleProviderDetails

            settingsRow(L10n.t("targetLanguage", language)) {
                Picker(L10n.t("targetLanguage", language), selection: $settingsStore.settings.targetLanguage) {
                    ForEach(LanguageOption.common.filter { $0.id != "auto" }) { option in
                        Text(LanguageOption.displayName(for: option.id, language: language)).tag(option.id)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 260)
            }

            helperText(language == .russian
                       ? "MyMemory работает без ключей. Если цель Русский, русский текст автоматически переводится на английский."
                       : "MyMemory works without keys. If the target is Russian, Russian text automatically translates to English.")

            settingsRow(L10n.t("appLanguage", language)) {
                Picker(L10n.t("appLanguage", language), selection: Binding(
                    get: { settingsStore.settings.appLanguage },
                    set: {
                        settingsStore.settings.appLanguage = $0
                        onLanguageChanged?()
                    }
                )) {
                    ForEach(AppLanguage.allCases) { appLanguage in
                        Text(appLanguage.displayName).tag(appLanguage)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 260)
            }
        }
    }

    @ViewBuilder
    private var simpleProviderDetails: some View {
        switch settingsStore.settings.provider {
        case .openAI:
            apiKeyEditor(title: L10n.t("openAIKey", language), text: $openAIAPIKey) {
                saveAPIKey(openAIAPIKey, for: .openAI)
            }
        case .myMemory:
            settingsRow(L10n.t("contactEmail", language)) {
                TextField(L10n.t("optional", language), text: $settingsStore.settings.myMemoryContactEmail)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
            }
            helperText(L10n.t("myMemoryHint", language))
        case .customOpenAI, .libreTranslate, .mock, .deepL:
            EmptyView()
        }
    }

    @ViewBuilder
    private var advancedProviderDetails: some View {
        switch settingsStore.settings.provider {
        case .customOpenAI:
            apiKeyEditor(title: language == .russian ? "API-ключ Custom Provider" : "Custom API key", text: $customAPIKey) {
                saveAPIKey(customAPIKey, for: .customOpenAI)
            }
        case .libreTranslate:
            apiKeyEditor(title: L10n.t("libreTranslateKey", language), text: $libreTranslateAPIKey) {
                saveAPIKey(libreTranslateAPIKey, for: .libreTranslate)
            }
            helperText(L10n.t("libreTranslateHint", language))
        case .mock:
            helperText(L10n.t("testMode", language))
        case .deepL:
            helperText(language == .russian ? "DeepL пока не реализован." : "DeepL is not implemented yet.")
        case .myMemory, .openAI:
            EmptyView()
        }
    }

    private var hotkeySection: some View {
        settingsSection(L10n.t("hotkey", language)) {
            settingsRow(L10n.t("primaryHotkey", language)) {
                hotkeyField(Binding(
                    get: { settingsStore.settings.hotkey },
                    set: {
                        settingsStore.settings.hotkey = $0
                        onHotKeyChanged?()
                    }
                ))
            }

            settingsRow(L10n.t("secondaryHotkey", language)) {
                hotkeyField(Binding(
                    get: { settingsStore.settings.secondaryHotkey },
                    set: {
                        settingsStore.settings.secondaryHotkey = $0
                        onHotKeyChanged?()
                    }
                ))
            }

            HStack {
                Button(L10n.t("resetHotkeys", language)) {
                    settingsStore.settings.hotkey = AppSettings().hotkey
                    settingsStore.settings.secondaryHotkey = AppSettings().secondaryHotkey
                    onHotKeyChanged?()
                }
                .buttonStyle(.bordered)
                Spacer()
            }

            helperText(language == .russian
                       ? "Первый хоткей показывает попап с переводом. Второй сразу заменяет выделенный текст переводом и может оставаться пустым."
                       : "The first hotkey shows the translation popup. The second one immediately replaces the selected text and can stay empty.")
        }
    }

    private var behaviorSection: some View {
        settingsSection(L10n.t("behavior", language)) {
            VStack(alignment: .leading, spacing: 9) {
                Toggle(L10n.t("saveHistory", language), isOn: $settingsStore.settings.saveTranslationHistory)
                Toggle(L10n.t("showPopupNearCursor", language), isOn: $settingsStore.settings.showPopupNearCursor)
                Toggle(L10n.t("closeAfterCopy", language), isOn: $settingsStore.settings.closePopupAfterCopy)
            }

            Divider()

            HStack {
                Button(L10n.t("clearTranslationHistory", language), role: .destructive) {
                    onClearHistory?()
                }
                .buttonStyle(.bordered)
                Spacer()
            }
        }
    }

    private var advancedSection: some View {
        DisclosureGroup(L10n.t("advanced", language), isExpanded: $isAdvancedExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                settingsRow(L10n.t("sourceLanguage", language)) {
                    Picker(L10n.t("sourceLanguage", language), selection: $settingsStore.settings.sourceLanguage) {
                        ForEach(LanguageOption.common) { option in
                            Text(LanguageOption.displayName(for: option.id, language: language)).tag(option.id)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 260)
                }

                Toggle(L10n.t("launchAtLogin", language), isOn: $settingsStore.settings.launchAtLogin)
                    .disabled(true)

                Divider()

                settingsRow(L10n.t("provider", language)) {
                    Picker(L10n.t("provider", language), selection: $settingsStore.settings.provider) {
                        Text(L10n.t("myMemory", language)).tag(TranslationProviderKind.myMemory)
                        Text(L10n.t("mock", language)).tag(TranslationProviderKind.mock)
                        Text(L10n.t("openAI", language)).tag(TranslationProviderKind.openAI)
                        Text(L10n.t("custom", language)).tag(TranslationProviderKind.customOpenAI)
                        Text(L10n.t("libreTranslate", language)).tag(TranslationProviderKind.libreTranslate)
                        Text(L10n.t("deepLComingSoon", language)).tag(TranslationProviderKind.deepL)
                    }
                    .labelsHidden()
                    .frame(maxWidth: 260)
                }

                advancedProviderDetails

                Divider()

                Text(L10n.t("customProvider", language))
                    .font(.subheadline.weight(.semibold))

                settingsRow(L10n.t("baseURL", language)) {
                    TextField(L10n.t("baseURL", language), text: $settingsStore.settings.customProviderBaseURL)
                        .textFieldStyle(.roundedBorder)
                }
                settingsRow(L10n.t("path", language)) {
                    TextField(L10n.t("path", language), text: $settingsStore.settings.customProviderPath)
                        .textFieldStyle(.roundedBorder)
                }
                settingsRow(L10n.t("model", language)) {
                    TextField(L10n.t("model", language), text: $settingsStore.settings.customProviderModel)
                        .textFieldStyle(.roundedBorder)
                }

                Text(customBaseURLValidationMessage)
                    .font(.caption)
                    .foregroundStyle(isCustomBaseURLValid ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.red))

                helperText(language == .russian ? "Настройки Custom Provider нужны для OpenAI-compatible сервисов. API-ключи остаются в Keychain." : "Custom provider settings are for OpenAI-compatible services. API keys stay in Keychain.")

                Divider()

                Text(L10n.t("libreTranslateProvider", language))
                    .font(.subheadline.weight(.semibold))

                settingsRow(L10n.t("baseURL", language)) {
                    TextField(L10n.t("baseURL", language), text: $settingsStore.settings.libreTranslateBaseURL)
                        .textFieldStyle(.roundedBorder)
                }

                helperText(L10n.t("libreTranslateHint", language))
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var privacySection: some View {
        settingsSection(L10n.t("privacy", language)) {
            VStack(alignment: .leading, spacing: 7) {
                Text(language == .russian ? "Выделенный текст отправляется только когда вы запускаете перевод." : "Selected text is sent only when you trigger translation.")
                Text(L10n.t("apiKeysKeychain", language))
                Text(L10n.t("historyLocal", language))
                Text(L10n.t("clipboardFallback", language))
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            if AnalyticsService.isConfiguredForCurrentBuild {
                Divider()

                Toggle(L10n.t("shareAnalytics", language), isOn: $settingsStore.settings.shareAnonymousAnalytics)
                helperText(L10n.t("analyticsPrivacy", language))
            }
        }
    }

    private func apiKeyEditor(title: String, text: Binding<String>, onSave: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SecureField(title, text: text)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button(L10n.t("saveKey", language), action: onSave)
                Button(language == .russian ? "Очистить" : "Clear", role: .destructive) {
                    text.wrappedValue = ""
                    onSave()
                }
                Spacer()
                if !keyStatusMessage.isEmpty {
                    Text(keyStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            helperText(L10n.t("keyStored", language))
        }
        .padding(.vertical, 2)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func settingsRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 150, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func helperText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func hotkeyField(_ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                HotKeyRecorderButton(value: text,
                                     emptyTitle: language == .russian ? "Назначить" : "Set shortcut",
                                     recordingTitle: L10n.t("recordHotkey", language)) {
                    onHotKeyChanged?()
                }
                .frame(width: 180, height: 30)

                Button {
                    text.wrappedValue = ""
                    onHotKeyChanged?()
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .help(language == .russian ? "Очистить" : "Clear")
            }

            if HotKeyShortcut.isSystemReserved(text.wrappedValue) {
                Text(L10n.t("reservedHotkeyWarning", language))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var isCustomBaseURLValid: Bool {
        customBaseURLValidationMessage == (language == .russian ? "Base URL выглядит корректно" : "Base URL looks valid")
    }

    private var customBaseURLValidationMessage: String {
        let value = settingsStore.settings.customProviderBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return language == .russian ? "Base URL нужен для Custom Provider" : "Base URL is required for Custom provider" }
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              components.host != nil else {
            return language == .russian ? "Введите корректный URL" : "Enter a valid URL"
        }

        #if DEBUG
        guard scheme == "https" || scheme == "http" else { return language == .russian ? "Используйте https:// или http:// в DEBUG" : "Use https://, or http:// in DEBUG" }
        #else
        guard scheme == "https" else { return language == .russian ? "Используйте https://" : "Use https://" }
        #endif

        return language == .russian ? "Base URL выглядит корректно" : "Base URL looks valid"
    }

    private func saveAPIKey(_ apiKey: String, for provider: TranslationProviderKind) {
        do {
            try settingsStore.saveAPIKey(apiKey, for: provider)
            keyStatusMessage = apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? L10n.t("keyCleared", language) : L10n.t("keySaved", language)
        } catch {
            keyStatusMessage = error.localizedDescription
        }
    }
}

private struct HotKeyRecorderButton: NSViewRepresentable {
    @Binding var value: String
    let emptyTitle: String
    let recordingTitle: String
    let onChange: () -> Void

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.target = context.coordinator
        button.action = #selector(Coordinator.startRecording)
        button.recordingTitle = recordingTitle
        button.onRecord = { newValue in
            value = newValue
            onChange()
        }
        button.updateTitle(value: value, emptyTitle: emptyTitle)
        context.coordinator.button = button
        return button
    }

    func updateNSView(_ nsView: RecorderButton, context: Context) {
        nsView.recordingTitle = recordingTitle
        nsView.updateTitle(value: value, emptyTitle: emptyTitle)
        nsView.onRecord = { newValue in
            value = newValue
            onChange()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        weak var button: RecorderButton?

        @objc func startRecording() {
            button?.beginRecording()
        }
    }
}

private final class RecorderButton: NSButton {
    var onRecord: ((String) -> Void)?
    var recordingTitle = "Press shortcut..."
    private var isRecording = false
    private var idleTitle = ""

    override var acceptsFirstResponder: Bool { true }

    func updateTitle(value: String, emptyTitle: String) {
        idleTitle = HotKeyShortcut.displayName(value, emptyTitle: emptyTitle)
        if !isRecording {
            title = idleTitle
        }
    }

    func beginRecording() {
        isRecording = true
        title = recordingTitle
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 {
            stopRecording()
            return
        }

        guard let value = HotKeyShortcut.normalized(keyCode: event.keyCode, modifiers: event.modifierFlags) else {
            NSSound.beep()
            return
        }

        onRecord?(value)
        stopRecording()
    }

    private func stopRecording() {
        isRecording = false
        title = idleTitle
        window?.makeFirstResponder(nil)
    }
}
