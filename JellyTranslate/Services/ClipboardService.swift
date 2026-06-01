import AppKit

struct ClipboardSnapshot {
    let string: String?
    let items: [NSPasteboardItem]
    let changeCount: Int
}

final class ClipboardService {
    private let pasteboard = NSPasteboard.general

    func snapshot() -> ClipboardSnapshot {
        let copiedItems = pasteboard.pasteboardItems?.compactMap { item -> NSPasteboardItem? in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        } ?? []
        return ClipboardSnapshot(string: pasteboard.string(forType: .string), items: copiedItems, changeCount: pasteboard.changeCount)
    }

    func restore(_ snapshot: ClipboardSnapshot) {
        pasteboard.clearContents()
        if snapshot.items.isEmpty, let string = snapshot.string {
            pasteboard.setString(string, forType: .string)
        } else {
            pasteboard.writeObjects(snapshot.items)
        }
    }

    func copy(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    func readString() -> String? {
        pasteboard.string(forType: .string)
    }

    var changeCount: Int {
        pasteboard.changeCount
    }
}
