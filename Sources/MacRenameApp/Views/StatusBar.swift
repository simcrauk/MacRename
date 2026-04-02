import SwiftUI

struct StatusBar: View {
    @Bindable var viewModel: AppViewModel
    @State private var showConfirmation = false

    var body: some View {
        HStack {
            if viewModel.totalItems > 0 {
                Text("\(viewModel.totalItems) item(s)")
                    .foregroundStyle(.secondary)

                if viewModel.itemsToRename > 0 {
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text("\(viewModel.itemsToRename) to rename")
                        .foregroundStyle(.blue)
                }

                let errors = viewModel.items.filter {
                    $0.status == .invalidCharacters || $0.status == .filenameTooLong
                    || $0.status == .pathTooLong || $0.status == .nameAlreadyExists
                }.count
                if errors > 0 {
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text("\(errors) error(s)")
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            if viewModel.isProcessing {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 4)
            }

            if viewModel.renameCompleted {
                Button("Undo") {
                    viewModel.undoRename()
                }
                .keyboardShortcut("z", modifiers: .command)
                .buttonStyle(.bordered)
            }

            Button("Clear") {
                viewModel.clearFiles()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.items.isEmpty)

            Button("Rename \(viewModel.itemsToRename) File(s)") {
                showConfirmation = true
            }
            .keyboardShortcut(.return, modifiers: .command)
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.itemsToRename == 0 || viewModel.isProcessing)
            .confirmationDialog(
                "Rename \(viewModel.itemsToRename) file(s)?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Rename") {
                    Task {
                        await viewModel.executeRename()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will rename the selected files. You can undo this operation.")
            }
        }
    }
}
