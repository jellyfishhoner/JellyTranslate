import AppKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settingsStore: SettingsStore
    let onOpenSettings: () -> Void
    let onFinish: () -> Void
    let onLanguageChanged: () -> Void

    @State private var step = 0
    @State private var selectedProvider: TranslationProviderKind
    @State private var isAccessibilityTrusted: Bool = PermissionService.isAccessibilityTrusted
    @State private var animatedWelcomeIndex = 0
    @State private var hasPlayedWelcomeAnimation = false
    @State private var isPlayingWelcomeAnimation = false
    @State private var didManuallySelectLanguage = false

    private let permissionRefreshTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private var language: AppLanguage { settingsStore.settings.appLanguage }
    private var visibleWelcome: AnimatedWelcomeCopy {
        if didManuallySelectLanguage || !isPlayingWelcomeAnimation {
            return AnimatedWelcomeCopy.copy(for: language)
        }
        return AnimatedWelcomeCopy.sequence[animatedWelcomeIndex]
    }

    init(settingsStore: SettingsStore,
         onOpenSettings: @escaping () -> Void,
         onFinish: @escaping () -> Void,
         onLanguageChanged: @escaping () -> Void = {}) {
        self.settingsStore = settingsStore
        self.onOpenSettings = onOpenSettings
        self.onFinish = onFinish
        self.onLanguageChanged = onLanguageChanged
        _selectedProvider = State(initialValue: settingsStore.settings.provider)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            progress
            content
            Spacer()
            footer
        }
        .padding(28)
        .frame(width: 540, height: 430)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: selectedProvider) { _, provider in
            settingsStore.settings.provider = provider
        }
        .onAppear {
            refreshPermissionStatus()
        }
        .task {
            await playWelcomeAnimationIfNeeded()
        }
        .onChange(of: step) { _, _ in
            refreshPermissionStatus()
        }
        .onReceive(permissionRefreshTimer) { _ in
            guard step == 1 else { return }
            refreshPermissionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            guard step == 1 else { return }
            refreshPermissionStatus()
        }
    }

    private var progress: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: index == step ? 28 : 18, height: 5)
                }
            }
            Spacer()
            Text("\(step + 1)/4")
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            welcomeStep
        case 1:
            permissionsStep
        case 2:
            providerStep
        default:
            tryItStep
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(visibleWelcome.title)
                .font(.title.weight(.semibold))
                .contentTransition(.opacity)
            Text(visibleWelcome.text)
                .font(.title3)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
            Text(visibleWelcome.note)
                .font(.callout)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
                .contentTransition(.opacity)
        }
        .id(visibleWelcome.id)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut(duration: 0.28), value: visibleWelcome.id)
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("permissions", language))
                .font(.title.weight(.semibold))
            Text(L10n.t("permissionsText", language))
                .foregroundStyle(.secondary)

            HStack {
                Text(L10n.t("accessibility", language))
                Spacer()
                Text(isAccessibilityTrusted ? L10n.t("granted", language) : L10n.t("notGranted", language))
                    .foregroundStyle(isAccessibilityTrusted ? .green : .orange)
                    .font(.callout.weight(.medium))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }

            HStack(spacing: 10) {
                Button(L10n.t("openPrivacy", language)) {
                    PermissionService.openAccessibilitySettings()
                    refreshPermissionStatus()
                }
                .buttonStyle(.bordered)

                Button(L10n.t("checkAgain", language)) {
                    refreshPermissionStatus()
                }
                .buttonStyle(.bordered)
            }

            if !isAccessibilityTrusted {
                Text(L10n.t("permissionRefreshHint", language))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var providerStep: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(L10n.t("provider", language))
                .font(.title.weight(.semibold))
            Text(L10n.t("providerText", language))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ProviderDisplayItem.translationProviders(language: language)) { item in
                    ProviderOptionCard(item: item,
                                       isSelected: item.id == TranslationProviderKind.myMemory.rawValue,
                                       isCompact: true,
                                       action: {
                                           selectedProvider = .myMemory
                                           settingsStore.settings.provider = .myMemory
                                       })
                }
            }

            Text(L10n.t("myMemoryHint", language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tryItStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("tryIt", language))
                .font(.title.weight(.semibold))
            Text(L10n.t("tryItText", language))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                shortcutRow(title: language == .russian ? "Показать перевод" : "Show translation",
                            shortcut: "Control + Option + T")
                shortcutRow(title: language == .russian ? "Перевести и заменить" : "Translate and replace",
                            shortcut: "Control + Option + R")
            }

            Text(language == .russian
                 ? "Всё просто: выделите текст, нажмите хоткей — JellyTranslate сделает остальное. Хоткеи можно изменить в настройках."
                 : "Simple: select text, press a shortcut, and JellyTranslate handles the rest. You can change shortcuts in Settings.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(L10n.t("privacyShort", language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private func shortcutRow(title: String, shortcut: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 160, alignment: .leading)
            Text(shortcut)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                }
        }
    }

    private var footer: some View {
        HStack {
            if step == 0 {
                appLanguagePicker
            } else {
                Button(L10n.t("back", language)) {
                    step -= 1
                }
            }

            Spacer()

            if step == 3 {
                Button(L10n.t("openSettings", language), action: onOpenSettings)
                    .buttonStyle(.bordered)
                Button(L10n.t("finish", language)) {
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            } else {
                Button(L10n.t("continue", language)) {
                    step += 1
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var appLanguagePicker: some View {
        Picker(L10n.t("appLanguage", language), selection: Binding(
            get: { settingsStore.settings.appLanguage == .russian ? AppLanguage.russian : AppLanguage.english },
            set: { newLanguage in
                withAnimation(.easeInOut(duration: 0.22)) {
                    didManuallySelectLanguage = true
                    isPlayingWelcomeAnimation = false
                    settingsStore.settings.appLanguage = newLanguage
                    animatedWelcomeIndex = AnimatedWelcomeCopy.index(for: newLanguage)
                }
                onLanguageChanged()
            }
        )) {
            Text("English").tag(AppLanguage.english)
            Text("Русский").tag(AppLanguage.russian)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 170)
        .help(L10n.t("appLanguage", language))
    }

    private func refreshPermissionStatus() {
        let trusted = PermissionService.currentAccessibilityTrust
        guard trusted != isAccessibilityTrusted else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            isAccessibilityTrusted = trusted
        }
    }

    private func playWelcomeAnimationIfNeeded() async {
        guard !hasPlayedWelcomeAnimation else { return }
        hasPlayedWelcomeAnimation = true
        isPlayingWelcomeAnimation = true

        for index in AnimatedWelcomeCopy.sequence.indices {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard step == 0, !didManuallySelectLanguage else { return }
                withAnimation(.easeInOut(duration: 0.28)) {
                    animatedWelcomeIndex = index
                }
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.28)) {
                animatedWelcomeIndex = AnimatedWelcomeCopy.index(for: language)
                isPlayingWelcomeAnimation = false
            }
        }
    }
}

private struct AnimatedWelcomeCopy: Identifiable {
    let id: String
    let title: String
    let text: String
    let note: String

    static let sequence: [AnimatedWelcomeCopy] = [
        AnimatedWelcomeCopy(
            id: "ru",
            title: "Добро пожаловать в JellyTranslate",
            text: "Выделите текст в любом приложении, нажмите хоткей и сразу получите перевод.",
            note: "Просто, быстро и без лишних шагов."
        ),
        AnimatedWelcomeCopy(
            id: "zh",
            title: "欢迎使用 JellyTranslate",
            text: "在 Mac 上选中文本，按下快捷键，即可立即翻译。",
            note: "简单、快速，没有多余步骤。"
        ),
        AnimatedWelcomeCopy(
            id: "de",
            title: "Willkommen bei JellyTranslate",
            text: "Text markieren, Kurzbefehl drücken und sofort die Übersetzung sehen.",
            note: "Einfach, schnell und ohne Umwege."
        ),
        AnimatedWelcomeCopy(
            id: "es",
            title: "Bienvenido a JellyTranslate",
            text: "Selecciona texto, pulsa el atajo y recibe la traducción al instante.",
            note: "Simple, rápido y sin pasos innecesarios."
        ),
        AnimatedWelcomeCopy(
            id: "fr",
            title: "Bienvenue dans JellyTranslate",
            text: "Sélectionnez du texte, appuyez sur le raccourci et obtenez la traduction.",
            note: "Simple, rapide, sans détour."
        ),
        AnimatedWelcomeCopy(
            id: "en",
            title: "Welcome to JellyTranslate",
            text: "Select text anywhere on your Mac, press the shortcut, and get an instant translation.",
            note: "Simple, fast, and out of your way."
        )
    ]

    static func copy(for language: AppLanguage) -> AnimatedWelcomeCopy {
        sequence[index(for: language)]
    }

    static func index(for language: AppLanguage) -> Int {
        switch language {
        case .english:
            return sequence.firstIndex { $0.id == "en" } ?? 0
        case .russian:
            return sequence.firstIndex { $0.id == "ru" } ?? 0
        }
    }
}
