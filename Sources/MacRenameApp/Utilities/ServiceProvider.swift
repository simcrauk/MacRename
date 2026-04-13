import AppKit

/// Handles the "Rename with MacRename" Services-menu invocation.
/// macOS surfaces this in Finder's right-click menu (under Services on
/// most files; promoted to the main menu after first use on macOS 14+).
final class ServiceProvider: NSObject {
    /// Selector form: <NSMessage>:userData:error:
    /// Declared in Info.plist NSServices ▸ NSMessage = "renameFiles".
    @objc func renameFiles(
        _ pboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !urls.isEmpty else {
            return
        }
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(
            name: .macRenameAddFiles,
            object: nil,
            userInfo: ["urls": urls]
        )
    }
}

extension Notification.Name {
    static let macRenameAddFiles = Notification.Name("MacRenameAddFiles")
}
