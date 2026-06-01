import Carbon
import Foundation
import AppKit

final class HotKeyManager {
    private let settingsStore: SettingsStore
    private let action: (HotKeyAction) -> Void
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private let signature = OSType(0x51544D31)

    init(settingsStore: SettingsStore, action: @escaping (HotKeyAction) -> Void) {
        self.settingsStore = settingsStore
        self.action = action
    }

    func register() {
        installHandlerIfNeeded()
        registerHotKey(settingsStore.settings.hotkey, id: 1)
        registerHotKey(settingsStore.settings.secondaryHotkey, id: 2)
    }

    func unregister() {
        unregisterHotKeys()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    func reregister() {
        unregisterHotKeys()
        register()
    }

    private func registerHotKey(_ value: String, id: UInt32) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let parsed = HotKeyShortcut.parse(trimmed) else { return }
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        let status = RegisterEventHotKey(parsed.keyCode,
                                         parsed.modifiers,
                                         hotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        if status == noErr, let hotKeyRef {
            hotKeyRefs.append(hotKeyRef)
        }
    }

    private func unregisterHotKeys() {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hotKeyID)
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            switch hotKeyID.id {
            case 1:
                manager.action(.showPopup)
            case 2:
                manager.action(.translateAndReplace)
            default:
                break
            }
            return noErr
        }, 1, &eventType, selfPointer, &eventHandler)
    }
}

enum HotKeyAction {
    case showPopup
    case translateAndReplace
}

enum HotKeyShortcut {
    static func parse(_ value: String) -> (keyCode: UInt32, modifiers: UInt32)? {
        let parts = value.lowercased().split(separator: "+").map(String.init)
        var modifiers: UInt32 = 0
        if parts.contains("command") || parts.contains("cmd") { modifiers |= UInt32(cmdKey) }
        if parts.contains("control") || parts.contains("ctrl") { modifiers |= UInt32(controlKey) }
        if parts.contains("option") || parts.contains("alt") { modifiers |= UInt32(optionKey) }
        if parts.contains("shift") { modifiers |= UInt32(shiftKey) }

        let key = parts.last ?? "t"
        guard let keyCode = keyCode(for: key), modifiers != 0 else { return nil }
        return (keyCode, modifiers)
    }

    static func normalized(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String? {
        guard let key = keyName(for: UInt32(keyCode)) else { return nil }

        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("command") }
        if modifiers.contains(.control) { parts.append("control") }
        if modifiers.contains(.option) { parts.append("option") }
        if modifiers.contains(.shift) { parts.append("shift") }
        guard !parts.isEmpty else { return nil }
        parts.append(key)
        return parts.joined(separator: "+")
    }

    static func displayName(_ value: String, emptyTitle: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return emptyTitle }

        let parts = trimmed.lowercased().split(separator: "+").map(String.init)
        let key = parts.last.map(displayKeyName) ?? ""
        var symbols = ""
        if parts.contains("command") || parts.contains("cmd") { symbols += "⌘" }
        if parts.contains("control") || parts.contains("ctrl") { symbols += "⌃" }
        if parts.contains("option") || parts.contains("alt") { symbols += "⌥" }
        if parts.contains("shift") { symbols += "⇧" }
        return symbols + key
    }

    private static func keyCode(for key: String) -> UInt32? {
        keyCodeTable[key]
    }

    private static func keyName(for keyCode: UInt32) -> String? {
        keyCodeTable.first { $0.value == keyCode }?.key
    }

    private static func displayKeyName(_ key: String) -> String {
        key == "space" ? "Space" : key.uppercased()
    }

    private static let keyCodeTable: [String: UInt32] = [
            "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
            "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
            "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
            "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
            "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37,
            "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44,
            "n": 45, "m": 46, ".": 47, "space": 49
    ]
}
