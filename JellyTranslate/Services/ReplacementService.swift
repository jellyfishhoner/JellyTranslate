import AppKit

final class ReplacementService {
    func replaceSelection(with text: String, clipboardService: ClipboardService) {
        let snapshot = clipboardService.snapshot()
        clipboardService.copy(text)
        simulatePasteShortcut()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            clipboardService.restore(snapshot)
        }
    }

    private func simulatePasteShortcut() {
        // Permission commonly required: Input Monitoring.
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let vKeyCode: CGKeyCode = 9
        let flags: CGEventFlags = .maskCommand
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = flags
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
