import AppKit
import ApplicationServices
import os

enum SelectionReaderError: LocalizedError, Equatable {
    case noSelectedText
    case accessibilityPermissionMissing
    case clipboardDidNotChange

    var errorDescription: String? {
        switch self {
        case .noSelectedText:
            return "No selected text was found. Some apps expose text only through copy fallback, and some protected views do not expose selection at all."
        case .accessibilityPermissionMissing:
            return "Accessibility permission is not enabled. JellyTranslate needs it to read selected text reliably from other apps."
        case .clipboardDidNotChange:
            return "Copy fallback did not produce text. The current app may block copy, or no text was selected."
        }
    }

    var recoverySuggestion: String? {
        "No selected text was found. Grant Accessibility/Input Monitoring permissions or select text before using the hotkey."
    }
}

final class SelectionReader {
    private let logger = Logger(subsystem: "app.jellytranslate.JellyTranslate", category: "capture")

    var isAccessibilityTrusted: Bool {
        PermissionService.isAccessibilityTrusted
    }

    func readSelectedTextWithFallback(clipboardService: ClipboardService) async throws -> String {
        if let accessibilityText = readSelectedTextViaAccessibility(), !accessibilityText.isEmpty {
            return accessibilityText
        }

        return try await readSelectedTextViaClipboardFallback(clipboardService: clipboardService)
    }

    private func readSelectedTextViaAccessibility() -> String? {
        // Permission required: Accessibility.
        // Users must allow JellyTranslate in System Settings > Privacy & Security > Accessibility.
        guard PermissionService.isAccessibilityTrusted else {
            logger.debug("capture_blocked_by_missing_permission")
            return nil
        }

        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var focusedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedValue) == .success,
              let focusedElement = focusedValue else {
            return nil
        }

        let focusedAXElement = focusedElement as! AXUIElement

        if let selectedText = stringAttribute(kAXSelectedTextAttribute as CFString, from: focusedAXElement),
           !selectedText.isEmpty {
            return selectedText
        }

        // Many input fields expose the full value plus a selected text range rather than AXSelectedText.
        if let value = stringAttribute(kAXValueAttribute as CFString, from: focusedAXElement),
           let range = selectedRange(from: focusedAXElement),
           range.length > 0,
           let swiftRange = Range(NSRange(location: range.location, length: range.length), in: value) {
            return String(value[swiftRange])
        }

        return nil
    }

    private func readSelectedTextViaClipboardFallback(clipboardService: ClipboardService) async throws -> String {
        // Permission commonly required: Input Monitoring.
        // The fallback simulates Cmd+C, so macOS may require permission in
        // System Settings > Privacy & Security > Input Monitoring.
        let snapshot = clipboardService.snapshot()
        defer { clipboardService.restore(snapshot) }

        simulateCopyShortcut()
        let didChange = await waitForClipboardChange(from: snapshot.changeCount, clipboardService: clipboardService)
        guard didChange else {
            throw SelectionReaderError.clipboardDidNotChange
        }

        let copied = clipboardService.readString()
        guard let copied, !copied.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SelectionReaderError.noSelectedText
        }
        return copied
    }

    private func waitForClipboardChange(from previousChangeCount: Int, clipboardService: ClipboardService) async -> Bool {
        for _ in 0..<12 {
            if clipboardService.changeCount != previousChangeCount {
                return true
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return false
    }

    private func stringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return value as? String
    }

    private func selectedRange(from element: AXUIElement) -> CFRange? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &value) == .success,
              let axValue = value,
              CFGetTypeID(axValue) == AXValueGetTypeID() else {
            return nil
        }

        var range = CFRange()
        guard AXValueGetValue(axValue as! AXValue, .cfRange, &range) else { return nil }
        return range
    }

    private func simulateCopyShortcut() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let cKeyCode: CGKeyCode = 8
        let flags: CGEventFlags = .maskCommand

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: true)
        keyDown?.flags = flags
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: false)
        keyUp?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
