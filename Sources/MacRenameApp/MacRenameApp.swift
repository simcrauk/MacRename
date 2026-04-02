import SwiftUI

@main
struct MacRenameApp: App {
    @State private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Files...") {
                    viewModel.openFilePanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
