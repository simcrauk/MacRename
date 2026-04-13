import SwiftUI
import AppKit

@main
struct MacRenameApp: App {
    @State private var viewModel = AppViewModel()

    init() {
        // SPM executables don't auto-activate as foreground apps,
        // so the window won't receive keyboard focus without this.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .onOpenURL { url in
                    if let files = URLSchemeHandler.parseURLScheme(url) {
                        viewModel.addFiles(urls: files)
                    }
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Files...") {
                    viewModel.openFilePanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .pasteboard) {
                Button("Select All") {
                    viewModel.items.forEach { $0.isSelected = true }
                }
                .keyboardShortcut("a", modifiers: .command)

                Button("Deselect All") {
                    viewModel.items.forEach { $0.isSelected = false }
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }
}
