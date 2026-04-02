import SwiftUI

struct DropZoneView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Drop files or folders here")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("or")
                .foregroundStyle(.tertiary)

            Button("Choose Files...") {
                viewModel.openFilePanel()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
