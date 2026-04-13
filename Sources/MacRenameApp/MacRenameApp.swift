import SwiftUI
import AppKit

@main
struct MacRenameApp: App {
    @Environment(\.openWindow) private var openWindow
    @State private var viewModel = AppViewModel()
    private let serviceProvider = ServiceProvider()

    init() {
        // SPM executables don't auto-activate as foreground apps,
        // so the window won't receive keyboard focus without this.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()

        // Register the Services-menu provider. The Info.plist NSServices
        // declaration tells macOS what to advertise; this tells macOS where
        // to dispatch the call when the user picks our menu item.
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
    }

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .onOpenURL { url in
                    if let files = URLSchemeHandler.parseURLScheme(url) {
                        viewModel.addFiles(urls: files)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .macRenameAddFiles)) { note in
                    if let urls = note.userInfo?["urls"] as? [URL] {
                        viewModel.addFiles(urls: urls)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MacRename") {
                    NSApp.orderFrontStandardAboutPanel(options: aboutPanelOptions())
                }
            }
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
            CommandGroup(replacing: .help) {
                Button("MacRename Help") {
                    openWindow(id: "help")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Window("MacRename Help", id: "help") {
            HelpView()
        }
        .defaultSize(width: 780, height: 560)
    }

    private func aboutPanelOptions() -> [NSApplication.AboutPanelOptionKey: Any] {
        let credits = NSMutableAttributedString()
        let regular = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let bold = NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
        let center = NSMutableParagraphStyle()
        center.alignment = .center

        credits.append(NSAttributedString(
            string: "Designed by ",
            attributes: [.font: regular, .paragraphStyle: center,
                         .foregroundColor: NSColor.labelColor]
        ))
        credits.append(NSAttributedString(
            string: "Simon Craig",
            attributes: [.font: bold, .paragraphStyle: center,
                         .foregroundColor: NSColor.labelColor]
        ))
        credits.append(NSAttributedString(
            string: "\n\nCode written by ",
            attributes: [.font: regular, .paragraphStyle: center,
                         .foregroundColor: NSColor.labelColor]
        ))
        credits.append(NSAttributedString(
            string: "Claude",
            attributes: [.font: bold, .paragraphStyle: center,
                         .foregroundColor: NSColor.labelColor]
        ))
        credits.append(NSAttributedString(
            string: " (Anthropic Claude Opus 4.6)\n\nA macOS port of PowerToys PowerRename.",
            attributes: [.font: regular, .paragraphStyle: center,
                         .foregroundColor: NSColor.secondaryLabelColor]
        ))

        return [
            .applicationName: "MacRename",
            .applicationVersion: "1.0.0",
            .credits: credits,
            .init(rawValue: "Copyright"): "© 2026 Simon Craig",
        ]
    }
}
