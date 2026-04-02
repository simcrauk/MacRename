import SwiftUI

struct StatusBar: View {
    @Bindable var viewModel: AppViewModel

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
            }

            Spacer()

            if viewModel.renameCompleted {
                Button("Undo") {
                    viewModel.undoRename()
                }
                .buttonStyle(.bordered)
            }

            Button("Clear") {
                viewModel.clearFiles()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.items.isEmpty)

            Button("Rename") {
                Task {
                    await viewModel.executeRename()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.itemsToRename == 0 || viewModel.isProcessing)
        }
    }
}
