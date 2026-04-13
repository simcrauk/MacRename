import SwiftUI

struct OptionsPanel: View {
    @Bindable var viewModel: AppViewModel
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup("Options", isExpanded: $isExpanded) {
            HStack(alignment: .top, spacing: 24) {
                // Scope
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apply to").font(.caption).foregroundStyle(.secondary)
                    Picker("Apply to", selection: $viewModel.nameOnly) {
                        Text("Full name").tag(false)
                        Text("Name only").tag(true)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .accessibilityLabel("Apply to")
                    .onChange(of: viewModel.nameOnly) { _, val in
                        if val { viewModel.extensionOnly = false }
                    }

                    Toggle("Extension only", isOn: $viewModel.extensionOnly)
                        .onChange(of: viewModel.extensionOnly) { _, val in
                            if val { viewModel.nameOnly = false }
                        }
                }

                Divider().frame(height: 80)

                // Filter
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filter").font(.caption).foregroundStyle(.secondary)
                    Toggle("Exclude files", isOn: $viewModel.excludeFiles)
                    Toggle("Exclude folders", isOn: $viewModel.excludeFolders)
                    Toggle("Exclude subfolders", isOn: $viewModel.excludeSubfolders)
                }

                Divider().frame(height: 80)

                // Transform
                VStack(alignment: .leading, spacing: 4) {
                    Text("Text transform").font(.caption).foregroundStyle(.secondary)
                    Picker("Text transform", selection: $viewModel.textTransform) {
                        ForEach(TextTransformOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .accessibilityLabel("Text transform")
                }

                Divider().frame(height: 80)

                // Tokens
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tokens").font(.caption).foregroundStyle(.secondary)
                    Toggle("Enumerate", isOn: $viewModel.enumerate)
                        .help("Enable ${start=N,padding=N} counters")
                    Toggle("Randomize", isOn: $viewModel.randomize)
                        .help("Enable ${rstring…} and ${ruuidv4} tokens")
                    Toggle("EXIF metadata", isOn: $viewModel.metadataEXIF)
                        .help("Enable $CAMERA_MAKE, $ISO, $DATE_TAKEN_* tokens for image files")
                    Toggle("XMP / IPTC metadata", isOn: $viewModel.metadataXMP)
                        .help("Enable $CREATOR, $TITLE, $CREATE_DATE_* tokens")

                    Text("Time source").font(.caption).foregroundStyle(.secondary)
                        .padding(.top, 4)
                    Picker("Time source", selection: $viewModel.timeSource) {
                        ForEach(TimeSourceOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityLabel("Time source")
                    .frame(width: 120)
                }
            }
            .padding(.top, 4)
        }
        .font(.system(size: 12))
    }
}
