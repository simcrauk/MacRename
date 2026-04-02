import Cocoa
import FinderSync

class FinderSyncExtension: FIFinderSync {

    override init() {
        super.init()
        // Monitor all volumes so the context menu appears everywhere
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - Context Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems else { return nil }

        let menu = NSMenu(title: "MacRename")
        let item = NSMenuItem(
            title: "Rename with MacRename",
            action: #selector(renameWithMacRename(_:)),
            keyEquivalent: ""
        )
        item.image = NSImage(systemSymbolName: "pencil.and.list.clipboard", accessibilityDescription: "Rename")
        menu.addItem(item)
        return menu
    }

    @objc func renameWithMacRename(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(),
              !items.isEmpty else { return }

        // Encode file URLs as a comma-separated list of paths
        let paths = items.map { $0.absoluteString }.joined(separator: ",")

        // Launch the main app via URL scheme
        if let url = URL(string: "macrename://open?files=\(paths.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback: launch the app directly and pass paths via pasteboard
            launchAppWithPasteboard(items: items)
        }
    }

    private func launchAppWithPasteboard(items: [URL]) {
        let pasteboard = NSPasteboard(name: .init("com.macrename.files"))
        pasteboard.clearContents()
        pasteboard.writeObjects(items as [NSURL])

        // Find and launch the main app
        let bundleID = "com.macrename.app"
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: appURL, configuration: config)
        }
    }
}
