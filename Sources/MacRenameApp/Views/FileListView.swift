import SwiftUI
import MacRenameCore

struct FileListView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        Table(viewModel.items) {
            TableColumn("") { item in
                Toggle("", isOn: Binding(
                    get: { item.isSelected },
                    set: { item.isSelected = $0 }
                ))
                .labelsHidden()
            }
            .width(24)

            TableColumn("Original Name") { item in
                HStack(spacing: 4) {
                    Image(systemName: item.isFolder ? "folder.fill" : "doc.fill")
                        .foregroundStyle(item.isFolder ? .blue : .secondary)
                        .font(.system(size: 11))
                    Text(item.originalName)
                        .lineLimit(1)
                }
                .padding(.leading, CGFloat(item.depth) * 16)
            }

            TableColumn("New Name") { item in
                FileRowNewName(item: item)
            }

            TableColumn("Status") { item in
                StatusBadge(status: item.status)
            }
            .width(min: 60, ideal: 80, max: 100)
        }
    }
}

struct FileRowNewName: View {
    let item: RenameItem

    var body: some View {
        if let newName = item.newName {
            Text(newName)
                .lineLimit(1)
                .foregroundColor(item.status == .shouldRename ? .primary : .red)
        } else {
            Text("—")
                .foregroundStyle(.quaternary)
        }
    }
}

struct StatusBadge: View {
    let status: RenameStatus

    var body: some View {
        switch status {
        case .shouldRename:
            Label("Rename", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 11))
        case .invalidCharacters:
            Label("Invalid", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.system(size: 11))
        case .filenameTooLong, .pathTooLong:
            Label("Too long", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.system(size: 11))
        case .nameAlreadyExists:
            Label("Exists", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 11))
        case .excluded:
            Label("Excluded", systemImage: "minus.circle")
                .foregroundStyle(.secondary)
                .font(.system(size: 11))
        case .unchanged, .initial:
            Text("")
        }
    }
}
