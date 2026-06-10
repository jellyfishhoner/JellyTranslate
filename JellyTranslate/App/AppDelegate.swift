import AppKit
import SwiftUI

enum DirectReplacementError: LocalizedError {
    case frontmostApplicationChanged

    var errorDescription: String? {
        switch self {
        case .frontmostApplicationChanged:
            return "The active app changed before JellyTranslate could replace the selected text. Select the text again and use the replace hotkey without switching apps."
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = SettingsStore()
    private let historyStore = HistoryStore()
    private let onboardingStore = OnboardingStore()
    private let clipboardService = ClipboardService()
    private let selectionReader = SelectionReader()
    private let replacementService = ReplacementService()
    private let speechService = SpeechService()
    private let analyticsService = AnalyticsService.shared
    private var availableUpdate: AppUpdate?

    private var statusItem: NSStatusItem?
    private var hotKeyManager: HotKeyManager?
    private var popupController: PopupWindowController?
    private var historyWindowController: NSWindowController?
    private var settingsWindowController: NSWindowController?
    private var onboardingWindowController: NSWindowController?
    private var currentPopupState: PopupPresentationState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenuBar()
        configureHotKey()
        showOnboardingIfNeeded()
        analyticsService.signal(.appLaunched, settings: settingsStore.settings)
        checkForUpdates()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.unregister()
    }

    private func configureMenuBar() {
        let item = statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let icon = NSApp.applicationIconImage.copy() as? NSImage
            icon?.size = NSSize(width: 22, height: 22)
            button.image = icon
            button.imagePosition = .imageOnly
            button.title = ""
            button.toolTip = "JellyTranslate"
        }

        let menu = NSMenu()
        let language = settingsStore.settings.appLanguage
        menu.addItem(NSMenuItem(title: L10n.t("quickStart", language), action: #selector(openOnboardingFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n.t("settings", language), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: L10n.t("history", language), action: #selector(openHistory), keyEquivalent: "h"))
        if let availableUpdate {
            let updateItem = NSMenuItem(title: "\(L10n.t("updateAvailable", language)) \(availableUpdate.version)",
                                        action: #selector(openAvailableUpdate),
                                        keyEquivalent: "")
            updateItem.target = self
            menu.addItem(.separator())
            menu.addItem(updateItem)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L10n.t("quit", language), action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    private func checkForUpdates() {
        Task { [weak self] in
            let update = await UpdateService.checkForUpdate()
            await MainActor.run {
                guard let self else { return }
                availableUpdate = update
                configureMenuBar()
            }
        }
    }

    private func configureHotKey() {
        hotKeyManager = HotKeyManager(settingsStore: settingsStore) { [weak self] action in
            Task { @MainActor in
                switch action {
                case .showPopup:
                    await self?.translateSelectedText()
                case .translateAndReplace:
                    await self?.translateAndReplaceSelectedText()
                }
            }
        }
        hotKeyManager?.register()
    }

    private func showOnboardingIfNeeded() {
        guard !onboardingStore.isCompleted else { return }
        DispatchQueue.main.async { [weak self] in
            self?.openOnboarding(markAsManual: false)
        }
    }

    @MainActor
    private func translateSelectedText() async {
        do {
            let selectedText = try await selectionReader.readSelectedTextWithFallback(clipboardService: clipboardService)
            let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                showPopup(state: .empty(message: L10n.t("emptySelection", settingsStore.settings.appLanguage)))
                return
            }

            analyticsService.signal(.translationRequested,
                                    settings: settingsStore.settings,
                                    metadata: analyticsMetadata(characterCount: trimmed.count, mode: "popup"))
            showPopup(state: .loading(message: L10n.t("translating", settingsStore.settings.appLanguage)))

            let item = try await translate(trimmed)
            if settingsStore.settings.saveTranslationHistory {
                historyStore.add(item)
            }
            analyticsService.signal(.translationSucceeded,
                                    settings: settingsStore.settings,
                                    metadata: analyticsMetadata(for: item, mode: "popup"))
            showPopup(state: .success(item))
        } catch {
            analyticsService.signal(.translationFailed,
                                    settings: settingsStore.settings,
                                    metadata: ["mode": "popup", "error_kind": analyticsErrorKind(error)])
            showPopup(state: errorState(for: error))
        }
    }

    @MainActor
    private func translateAndReplaceSelectedText() async {
        let sourceApplication = NSWorkspace.shared.frontmostApplication

        do {
            let selectedText = try await selectionReader.readSelectedTextWithFallback(clipboardService: clipboardService)
            let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                showPopup(state: .empty(message: L10n.t("emptySelection", settingsStore.settings.appLanguage)))
                return
            }

            analyticsService.signal(.translationRequested,
                                    settings: settingsStore.settings,
                                    metadata: analyticsMetadata(characterCount: trimmed.count, mode: "replace"))
            let item = try await translate(trimmed)
            try ensureFrontmostApplicationDidNotChange(from: sourceApplication)
            replacementService.replaceSelection(with: item.translatedText, clipboardService: clipboardService)

            if settingsStore.settings.saveTranslationHistory {
                historyStore.add(item)
            }
            analyticsService.signal(.translationSucceeded,
                                    settings: settingsStore.settings,
                                    metadata: analyticsMetadata(for: item, mode: "replace"))
            analyticsService.signal(.replacementUsed,
                                    settings: settingsStore.settings,
                                    metadata: analyticsMetadata(for: item, mode: "replace"))
        } catch {
            analyticsService.signal(.translationFailed,
                                    settings: settingsStore.settings,
                                    metadata: ["mode": "replace", "error_kind": analyticsErrorKind(error)])
            showPopup(state: errorState(for: error))
        }
    }

    private func translate(_ trimmed: String) async throws -> TranslationHistoryItem {
        let languagePair = effectiveLanguagePair(for: trimmed)
        let sourceLanguage = languagePair.source
        let targetLanguage = languagePair.target
        if settingsStore.settings.provider == .myMemory,
           settingsStore.settings.saveTranslationHistory,
           let cachedItem = historyStore.cachedItem(originalText: trimmed,
                                                    sourceLanguage: sourceLanguage,
                                                    targetLanguage: targetLanguage,
                                                    provider: .myMemory) {
            return cachedItem
        }

        let apiKey = settingsStore.apiKey(for: settingsStore.settings.provider)
        let provider = TranslationProviderFactory.provider(for: settingsStore.settings.provider)
        let model = modelForSelectedProvider()
        let configuration = ProviderConfiguration(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            apiKey: apiKey,
            model: model,
            baseURL: baseURLForSelectedProvider(),
            path: settingsStore.settings.provider == .customOpenAI ? settingsStore.settings.customProviderPath : nil,
            contactEmail: settingsStore.settings.provider == .myMemory ? settingsStore.settings.myMemoryContactEmail : nil
        )
        let translated = try await withTimeout(seconds: 12) {
            try await provider.translate(
                text: trimmed,
                configuration: configuration
            )
        }

        return TranslationHistoryItem(
            originalText: trimmed,
            translatedText: translated,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            provider: settingsStore.settings.provider,
            providerModel: settingsStore.settings.provider == .customOpenAI ? model : nil
        )
    }

    private func ensureFrontmostApplicationDidNotChange(from sourceApplication: NSRunningApplication?) throws {
        guard let sourceApplication,
              let currentApplication = NSWorkspace.shared.frontmostApplication else {
            return
        }

        if sourceApplication.processIdentifier != currentApplication.processIdentifier {
            throw DirectReplacementError.frontmostApplicationChanged
        }
    }

    private func effectiveLanguagePair(for text: String) -> (source: String, target: String) {
        let source = settingsStore.settings.sourceLanguage
        let target = settingsStore.settings.targetLanguage

        guard source == "auto" else {
            return (source, target)
        }

        if looksCyrillic(text), target == "ru" {
            return ("ru", "en")
        }

        if looksMostlyLatin(text), target == "en" {
            return ("en", "ru")
        }

        return (source, target)
    }

    private func looksCyrillic(_ text: String) -> Bool {
        text.range(of: "\\p{Cyrillic}", options: .regularExpression) != nil
    }

    private func looksMostlyLatin(_ text: String) -> Bool {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard !letters.isEmpty else { return false }
        let latinLetters = letters.filter { scalar in
            (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
        }
        return Double(latinLetters.count) / Double(letters.count) > 0.7
    }

    private func modelForSelectedProvider() -> String {
        switch settingsStore.settings.provider {
        case .customOpenAI:
            let customModel = settingsStore.settings.customProviderModel.trimmingCharacters(in: .whitespacesAndNewlines)
            return customModel.isEmpty ? "gpt-4o-mini" : customModel
        case .openAI:
            return "gpt-5.2"
        case .mock, .libreTranslate, .myMemory, .deepL:
            return ""
        }
    }

    private func baseURLForSelectedProvider() -> String? {
        switch settingsStore.settings.provider {
        case .customOpenAI:
            return settingsStore.settings.customProviderBaseURL
        case .libreTranslate:
            return settingsStore.settings.libreTranslateBaseURL
        case .mock, .openAI, .myMemory, .deepL:
            return nil
        }
    }

    private func errorState(for error: Error) -> PopupPresentationState {
        let nsError = error as NSError
        let message = nsError.localizedRecoverySuggestion.map { "\(error.localizedDescription)\n\($0)" } ?? error.localizedDescription
        let action: PopupRecoveryAction?
        let title: String

        if let selectionError = error as? SelectionReaderError,
           selectionError == .clipboardDidNotChange,
           !PermissionService.isAccessibilityTrusted {
            title = "Permission needed"
            action = .accessibilitySettings
        } else if let selectionError = error as? SelectionReaderError,
                  selectionError == .clipboardDidNotChange {
            title = "Copy fallback did not work"
            action = .inputMonitoringSettings
        } else if let selectionError = error as? SelectionReaderError,
                  selectionError == .noSelectedText {
            title = "No selected text"
            action = nil
        } else if error is TranslationRuntimeError {
            title = "Provider timeout"
            action = nil
        } else if error is TranslationProviderError {
            title = "Provider needs setup"
            action = nil
        } else {
            title = "Translation failed"
            action = nil
        }

        return .error(
                title: localizedErrorTitle(title),
                message: title == "Permission needed"
                    ? L10n.t("permissionNeededMessage", settingsStore.settings.appLanguage)
                    : message,
                sourceLanguage: settingsStore.settings.sourceLanguage,
                targetLanguage: settingsStore.settings.targetLanguage,
                provider: settingsStore.settings.provider,
                action: action
        )
    }

    private func showPopup(state: PopupPresentationState) {
        currentPopupState = state
        if let popupController {
            popupController.update(state: state, targetLanguage: settingsStore.settings.targetLanguage)
            if settingsStore.settings.showPopupNearCursor {
                popupController.showNearCursor()
            }
            return
        }

        let controller = PopupWindowController(state: state,
                                               clipboardService: clipboardService,
                                               replacementService: replacementService,
                                               speechService: speechService,
                                               language: settingsStore.settings.appLanguage,
                                               targetLanguage: settingsStore.settings.targetLanguage,
                                               closeAfterCopy: settingsStore.settings.closePopupAfterCopy,
                                               onHistory: { [weak self] in self?.openHistory() },
                                               onTargetLanguageChange: { [weak self] targetLanguage in
                                                   Task { @MainActor in
                                                       await self?.changeTargetLanguageFromPopup(targetLanguage)
                                                   }
                                               },
                                               onRecoveryAction: { action in
                                                   switch action {
                                                   case .accessibilitySettings:
                                                       PermissionService.openAccessibilitySettings()
                                                   case .inputMonitoringSettings:
                                                       PermissionService.openInputMonitoringSettings()
                                                   }
                                               },
                                               onClose: { [weak self] in self?.popupController = nil })
        popupController = controller
        if settingsStore.settings.showPopupNearCursor {
            controller.showNearCursor()
        } else {
            controller.showCentered()
        }
    }

    @MainActor
    private func changeTargetLanguageFromPopup(_ targetLanguage: String) async {
        guard settingsStore.settings.targetLanguage != targetLanguage else { return }
        settingsStore.settings.targetLanguage = targetLanguage
        analyticsService.signal(.targetLanguageChanged,
                                settings: settingsStore.settings,
                                metadata: ["target_language": targetLanguage])

        guard case .success(let currentItem) = currentPopupState else {
            popupController?.update(state: currentPopupState ?? .loading(message: L10n.t("translating", settingsStore.settings.appLanguage)),
                                    targetLanguage: targetLanguage)
            return
        }

        showPopup(state: .loading(message: L10n.t("translating", settingsStore.settings.appLanguage)))

        do {
            let item = try await translate(currentItem.originalText)
            if settingsStore.settings.saveTranslationHistory {
                historyStore.add(item)
            }
            showPopup(state: .success(item))
        } catch {
            showPopup(state: errorState(for: error))
        }
    }

    private func localizedErrorTitle(_ title: String) -> String {
        let language = settingsStore.settings.appLanguage
        switch title {
        case "Permission needed":
            return L10n.t("permissionNeeded", language)
        case "Copy fallback did not work":
            return L10n.t("copyFallbackFailed", language)
        case "No selected text":
            return L10n.t("noSelectedText", language)
        case "Provider timeout":
            return L10n.t("providerTimeout", language)
        case "Provider needs setup":
            return L10n.t("providerSetup", language)
        default:
            return L10n.t("translationFailed", language)
        }
    }

    private func analyticsMetadata(for item: TranslationHistoryItem, mode: String) -> [String: String] {
        var metadata = analyticsMetadata(characterCount: item.characterCount, mode: mode)
        metadata["source_language"] = item.sourceLanguage
        metadata["target_language"] = item.targetLanguage
        metadata["provider"] = item.providerName
        if let modelName = item.modelName, !modelName.isEmpty {
            metadata["model"] = modelName
        }
        return metadata
    }

    private func analyticsMetadata(characterCount: Int, mode: String) -> [String: String] {
        [
            "mode": mode,
            "character_bucket": characterBucket(for: characterCount)
        ]
    }

    private func characterBucket(for count: Int) -> String {
        switch count {
        case 0:
            return "empty"
        case 1...80:
            return "1-80"
        case 81...240:
            return "81-240"
        case 241...1000:
            return "241-1000"
        default:
            return "1000+"
        }
    }

    private func analyticsErrorKind(_ error: Error) -> String {
        if error is TranslationRuntimeError {
            return "timeout"
        }
        if error is TranslationProviderError {
            return "provider"
        }
        if error is SelectionReaderError {
            return "selection"
        }
        if error is DirectReplacementError {
            return "replacement"
        }
        return "unknown"
    }

    @objc private func openSettings() {
        analyticsService.signal(.settingsOpened, settings: settingsStore.settings)
        let view = SettingsView(settingsStore: settingsStore) { [weak self] in
            self?.hotKeyManager?.reregister()
        } onLanguageChanged: { [weak self] in
            self?.configureMenuBar()
        } onClearHistory: { [weak self] in
            self?.historyStore.clear()
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 580, height: 660),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        window.title = "JellyTranslate \(L10n.t("settings", settingsStore.settings.appLanguage))"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openOnboardingFromMenu() {
        openOnboarding(markAsManual: true)
    }

    private func openOnboarding(markAsManual: Bool) {
        analyticsService.signal(.quickStartOpened,
                                settings: settingsStore.settings,
                                metadata: ["manual": markAsManual ? "true" : "false"])
        if let onboardingWindowController {
            onboardingWindowController.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = OnboardingView(settingsStore: settingsStore,
                                  onOpenSettings: { [weak self] in self?.openSettings() },
                                  onFinish: { [weak self] in
                                      self?.onboardingStore.markCompleted()
                                      self?.onboardingWindowController?.close()
                                      self?.onboardingWindowController = nil
                                  },
                                  onLanguageChanged: { [weak self] in
                                      self?.configureMenuBar()
                                      self?.onboardingWindowController?.window?.title = "JellyTranslate \(L10n.t("quickStart", self?.settingsStore.settings.appLanguage ?? .english))"
                                  })
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        window.title = "JellyTranslate \(L10n.t("quickStart", settingsStore.settings.appLanguage))"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        let controller = NSWindowController(window: window)
        onboardingWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openHistory() {
        analyticsService.signal(.historyOpened, settings: settingsStore.settings)
        let view = HistoryView(historyStore: historyStore,
                               clipboardService: clipboardService,
                               isHistoryEnabled: settingsStore.settings.saveTranslationHistory,
                               language: settingsStore.settings.appLanguage)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 500),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered,
                              defer: false)
        window.title = "JellyTranslate \(L10n.t("history", settingsStore.settings.appLanguage))"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        let controller = NSWindowController(window: window)
        historyWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openAvailableUpdate() {
        guard let availableUpdate else { return }
        NSWorkspace.shared.open(availableUpdate.url)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
