import SwiftUI
import MacRenameCore

struct FileListView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        Table(viewModel.items) {
            TableColumn("") { item in
                Toggle("", isOn: Binding(
                    get: { item.isSelected },
                    set: { viewModel.setSelected(item, $0) }
                ))
                .labelsHidden()
                .accessibilityLabel("Include \(item.originalName)")
            }
            .width(24)

            TableColumn("Original Name") { item in
                HStack(spacing: 4) {
                    Image(systemName: item.isFolder ? "folder.fill" : "doc.fill")
                        .foregroundStyle(item.isFolder ? .blue : .secondary)
                        .font(.system(size: 11))
                        .accessibilityHidden(true)
                    Text(item.originalName)
                        .lineLimit(1)
                }
                .padding(.leading, CGFloat(item.depth) * 16)
                .accessibilityLabel("\(item.isFolder ? "Folder" : "File"): \(item.originalName)")
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

    private var colorForStatus: Color {
        switch item.status {
        case .shouldRename, .renamed: return .primary
        default: return .red
        }
    }

    var body: some View {
        if let newName = item.newName {
            Text(newName)
                .lineLimit(1)
                .foregroundColor(colorForStatus)
                .accessibilityLabel("New name: \(newName)")
        } else {
            Text("—")
                .foregroundStyle(.quaternary)
                .accessibilityLabel("No change")
        }
    }
}

struct StatusBadge: View {
    let status: RenameStatus

    var body: some View {
        switch status {
        case .shouldRename:
            Label("Rename", systemImage: "checkmark.circle")
                .foregroundStyle(.blue)
                .font(.system(size: 11))
        case .renamed:
            Label("Renamed", systemImage: "checkmark.circle.fill")
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
