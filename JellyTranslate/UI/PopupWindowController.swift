import AppKit
import SwiftUI

final class PopupWindowController: NSWindowController {
    private let hostingView: NSHostingView<PopupView>
    private let clipboardService: ClipboardService
    private let replacementService: ReplacementService
    private let speechService: SpeechService
    private let language: AppLanguage
    private let closeAfterCopy: Bool
    private let onHistory: () -> Void
    private let onTargetLanguageChange: (String) -> Void
    private let onRecoveryAction: (PopupRecoveryAction) -> Void
    private let onClose: () -> Void
    private var state: PopupPresentationState
    private var targetLanguage: String
    private var actionFeedback: String?
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?
    private var globalMouseMonitor: Any?
    private var isClosing = false

    init(state: PopupPresentationState,
         clipboardService: ClipboardService,
         replacementService: ReplacementService,
         speechService: SpeechService,
         language: AppLanguage,
         targetLanguage: String,
         closeAfterCopy: Bool,
         onHistory: @escaping () -> Void,
         onTargetLanguageChange: @escaping (String) -> Void,
         onRecoveryAction: @escaping (PopupRecoveryAction) -> Void,
         onClose: @escaping () -> Void) {
        self.state = state
        self.clipboardService = clipboardService
        self.replacementService = replacementService
        self.speechService = speechService
        self.language = language
        self.targetLanguage = targetLanguage
        self.closeAfterCopy = closeAfterCopy
        self.onHistory = onHistory
        self.onTargetLanguageChange = onTargetLanguageChange
        self.onRecoveryAction = onRecoveryAction
        self.onClose = onClose

        let view = PopupView(state: state,
                             onCopy: {},
                             onReplace: {},
                             onSpeak: {},
                             onHistory: {},
                             onTargetLanguageChange: { _ in },
                             onRecoveryAction: { _ in },
                             onClose: {},
                             language: language,
                             targetLanguage: targetLanguage,
                             actionFeedback: nil)
        hostingView = DraggableHostingView(rootView: view)
        let window = NSPanel(contentRect: NSRect(x: 0,
                                                 y: 0,
                                                 width: PopupView.preferredSize.width,
                                                 height: PopupView.preferredSize.height),
                             styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                             backing: .buffered,
                             defer: false)
        window.contentView = hostingView
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        super.init(window: window)
        update(state: state)
        installCloseMonitors()
    }

    deinit {
        removeCloseMonitors()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func showNearCursor() {
        guard let window else { return }
        let cursor = NSEvent.mouseLocation
        let frame = window.frame
        let screenFrame = screenContaining(point: cursor)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let x = min(max(cursor.x + 12, screenFrame.minX), screenFrame.maxX - frame.width)
        let y = min(max(cursor.y - frame.height - 12, screenFrame.minY), screenFrame.maxY - frame.height)
        window.setFrameOrigin(NSPoint(x: x, y: y))
        window.alphaValue = 0
        showWindow(nil)
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
    }

    func showCentered() {
        guard let window else { return }
        window.center()
        window.alphaValue = 0
        showWindow(nil)
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
    }

    func update(state: PopupPresentationState, targetLanguage: String? = nil) {
        self.state = state
        if let targetLanguage {
            self.targetLanguage = targetLanguage
        }
        hostingView.rootView = PopupView(
            state: state,
            onCopy: { [weak self] in self?.copyTranslation() },
            onReplace: { [weak self] in self?.replaceSelection() },
            onSpeak: { [weak self] in self?.speakCurrentContent() },
            onHistory: onHistory,
            onTargetLanguageChange: { [weak self] targetLanguage in
                self?.targetLanguage = targetLanguage
                self?.onTargetLanguageChange(targetLanguage)
            },
            onRecoveryAction: { [weak self] action in self?.onRecoveryAction(action) },
            onClose: { [weak self] in self?.closeAnimated() },
            language: language,
            targetLanguage: self.targetLanguage,
            actionFeedback: actionFeedback
        )
    }

    private func copyTranslation() {
        guard case .success(let item) = state else { return }
        clipboardService.copy(item.translatedText)
        showActionFeedback(L10n.t("copied", language))
        if closeAfterCopy {
            closeAnimated()
        }
    }

    private func replaceSelection() {
        guard case .success(let item) = state else { return }
        replacementService.replaceSelection(with: item.translatedText, clipboardService: clipboardService)
        showActionFeedback(L10n.t("replaced", language))
    }

    private func showActionFeedback(_ message: String) {
        actionFeedback = message
        update(state: state)

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard self?.actionFeedback == message else { return }
            self?.actionFeedback = nil
            if let state = self?.state {
                self?.update(state: state)
            }
        }
    }

    private func speakCurrentContent() {
        switch state {
        case .success(let item):
            speechService.speak(item.translatedText)
        case .error(_, let message, _, _, _, _):
            speechService.speak(message)
        case .loading(let message), .empty(let message):
            speechService.speak(message)
        }
    }

    private func closeAnimated() {
        guard !isClosing else { return }
        isClosing = true
        guard let window else {
            onClose()
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.close()
            self?.onClose()
        }
    }

    private func screenContaining(point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { screen in
            screen.frame.contains(point)
        }
    }

    private func installCloseMonitors() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.closeAnimated()
                return nil
            }
            return event
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                DispatchQueue.main.async { self?.closeAnimated() }
            }
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let window = self.window else { return }
            if !window.frame.contains(NSEvent.mouseLocation) {
                DispatchQueue.main.async { self.closeAnimated() }
            }
        }
    }

    private func removeCloseMonitors() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
    }
}

private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool {
        true
    }
}
