import SwiftUI

struct SearchReplaceBar: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search for...", text: $viewModel.searchTerm)
                    .textFieldStyle(.roundedBorder)

                Toggle("Aa", isOn: $viewModel.caseSensitive)
                    .toggleStyle(.button)
                    .help("Case sensitive")

                Toggle(".*", isOn: $viewModel.useRegex)
                    .toggleStyle(.button)
                    .help("Use regular expressions")

                Toggle("All", isOn: $viewModel.matchAll)
                    .toggleStyle(.button)
                    .help("Match all occurrences")
            }

            HStack {
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                TextField("Replace with...", text: $viewModel.replaceTerm)
                    .textFieldStyle(.roundedBorder)

                TokenMenu(viewModel: viewModel)
            }
        }
    }
}

struct TokenMenu: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        Menu {
            Section("Enumeration") {
                Button("Counter ${start=1,increment=1,padding=3}") {
                    insertToken("${start=1,increment=1,padding=3}")
                }
            }
            Section("Random") {
                Button("Random alphanumeric ${rstringalnum=8}") {
                    insertToken("${rstringalnum=8}")
                }
                Button("Random letters ${rstringalpha=8}") {
                    insertToken("${rstringalpha=8}")
                }
                Button("Random digits ${rstringdigit=4}") {
                    insertToken("${rstringdigit=4}")
                }
                Button("UUID ${ruuidv4}") {
                    insertToken("${ruuidv4}")
                }
            }
            Section("Date / Time") {
                Button("Year $YYYY") { insertToken("$YYYY") }
                Button("Month $MM") { insertToken("$MM") }
                Button("Day $DD") { insertToken("$DD") }
                Button("Hour (24h) $HH") { insertToken("$HH") }
                Button("Minute $mm") { insertToken("$mm") }
                Button("Second $ss") { insertToken("$ss") }
                Button("Full date $YYYY-$MM-$DD") { insertToken("$YYYY-$MM-$DD") }
                Button("Full datetime $YYYY-$MM-$DD_$HH-$mm-$ss") {
                    insertToken("$YYYY-$MM-$DD_$HH-$mm-$ss")
                }
            }
            Section("Metadata (EXIF)") {
                Button("Camera make $CAMERA_MAKE") { insertToken("$CAMERA_MAKE") }
                Button("Camera model $CAMERA_MODEL") { insertToken("$CAMERA_MODEL") }
                Button("ISO $ISO") { insertToken("$ISO") }
                Button("Aperture $APERTURE") { insertToken("$APERTURE") }
                Button("Date taken $DATE_TAKEN_YYYY-$DATE_TAKEN_MM-$DATE_TAKEN_DD") {
                    insertToken("$DATE_TAKEN_YYYY-$DATE_TAKEN_MM-$DATE_TAKEN_DD")
                }
            }
        } label: {
            Image(systemName: "ellipsis.curlybraces")
                .help("Insert token")
        }
    }

    private func insertToken(_ token: String) {
        viewModel.replaceTerm += token
    }
}
