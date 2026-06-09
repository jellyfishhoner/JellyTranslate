import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    var onHotKeyChanged: (() -> Void)?
    var onLanguageChanged: (() -> Void)?
    var onClearHistory: (() -> Void)?

    @State private var isAdvancedExpanded: Bool = false

    private var language: AppLanguage { settingsStore.settings.appLanguage }
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
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.t("providerText", language))
                    .font(.callout)
                    .foregroundStyle(.secondary)

                ForEach(ProviderDisplayItem.translationProviders(language: language)) { item in
                    ProviderOptionCard(item: item,
                                       isSelected: item.id == TranslationProviderKind.myMemory.rawValue,
                                       action: {
                                           settingsStore.settings.provider = .myMemory
                                       })
                }
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
                       ? "MyMemory работает без аккаунта. Если выбран русский язык, русский текст автоматически переводится на английский."
                       : "MyMemory works without an account. If the target is Russian, Russian text automatically translates to English.")

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
        case .myMemory:
            settingsRow(L10n.t("contactEmail", language)) {
                TextField(L10n.t("optional", language), text: $settingsStore.settings.myMemoryContactEmail)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
            }
            helperText(L10n.t("myMemoryHint", language))
        case .openAI, .customOpenAI, .libreTranslate, .mock, .deepL:
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
                       ? "Первый хоткей показывает окно перевода. Второй сразу заменяет выделенный текст переводом и может оставаться пустым."
                       : "The first shortcut shows the translation window. The second one immediately replaces the selected text and can stay empty.")
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
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var privacySection: some View {
        settingsSection(L10n.t("privacy", language)) {
            VStack(alignment: .leading, spacing: 7) {
                Text(language == .russian ? "Выделенный текст отправляется только когда вы сами запускаете перевод." : "Selected text is sent only when you ask JellyTranslate to translate it.")
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
