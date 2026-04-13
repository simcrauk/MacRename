import SwiftUI
import MacRenameCore
import UniformTypeIdentifiers

@Observable
@MainActor
final class AppViewModel {
    let engine = RenameEngine()
    let settings: AppSettings

    var searchTerm: String {
        didSet {
            if settings.persistState { settings.lastSearchTerm = searchTerm }
            schedulePreview()
        }
    }
    var replaceTerm: String {
        didSet {
            if settings.persistState { settings.lastReplaceTerm = replaceTerm }
            schedulePreview()
        }
    }

    // Search options
    var caseSensitive = false { didSet { syncFlags() } }
    var matchAll = true { didSet { syncFlags() } }
    var useRegex = false { didSet { syncFlags() } }

    // Scope
    var nameOnly = false { didSet { if nameOnly { extensionOnly = false }; syncFlags() } }
    var extensionOnly = false { didSet { if extensionOnly { nameOnly = false }; syncFlags() } }
    var excludeFiles = false { didSet { syncFlags() } }
    var excludeFolders = false { didSet { syncFlags() } }
    var excludeSubfolders = false { didSet { syncFlags() } }

    // Text transform (radio-style: only one active)
    var textTransform: TextTransformOption = .none { didSet { syncFlags() } }

    // Tokens
    var enumerate = false { didSet { syncFlags() } }
    var randomize = false { didSet { syncFlags() } }

    // Time source
    var timeSource: TimeSourceOption = .none { didSet { syncFlags() } }

    // Metadata
    var metadataEXIF = false { didSet { syncFlags() } }
    var metadataXMP = false { didSet { syncFlags() } }

    // State
    var isProcessing = false
    var renameCompleted = false
    var lastRenamePairs: [RenamePair] = []
    var errorMessage: String?

    private var previewTask: Task<Void, Never>?

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        // Default to persisting on first launch; users can later opt out.
        if UserDefaults.standard.object(forKey: "persistState") == nil {
            settings.persistState = true
        }
        self.searchTerm = settings.persistState ? (settings.lastSearchTerm ?? "") : ""
        self.replaceTerm = settings.persistState ? (settings.lastReplaceTerm ?? "") : ""
    }

    var items: [RenameItem] { engine.items }
    var itemsToRename: Int { items.filter { $0.status == .shouldRename }.count }
    var totalItems: Int { items.count }

    // MARK: - File Management

    func addFiles(urls: [URL]) {
        engine.addItems(urls: urls, recursive: !excludeSubfolders)
        schedulePreview()
    }

    func clearFiles() {
        engine.clearItems()
        renameCompleted = false
        lastRenamePairs = []
        errorMessage = nil
    }

    /// Toggle whether an item participates in the rename. Re-runs the preview
    /// so the "to rename" count and excluded statuses update immediately.
    func setSelected(_ item: RenameItem, _ selected: Bool) {
        item.isSelected = selected
        schedulePreview()
    }

    func openFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select files or folders to rename"

        if panel.runModal() == .OK {
            addFiles(urls: panel.urls)
        }
    }

    // MARK: - Rename

    func executeRename() async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let pairs = try await engine.executeRename()
            lastRenamePairs = pairs
            renameCompleted = true
            // Mark renamed items so the list shows a terminal "Renamed" badge
            // instead of still advertising them as pending.
            let renamedSources = Set(pairs.map { $0.source })
            for item in engine.items where renamedSources.contains(item.url) {
                item.status = .renamed
            }
            settings.pushSearchMRU(searchTerm)
            settings.pushReplaceMRU(replaceTerm)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoRename() {
        guard !lastRenamePairs.isEmpty else { return }
        do {
            try engine.undoRenames(lastRenamePairs)
            lastRenamePairs = []
            renameCompleted = false
            // Re-add from original paths and recompute
            schedulePreview()
        } catch {
            errorMessage = "Undo failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func syncFlags() {
        var flags: RenameFlags = []
        if caseSensitive { flags.insert(.caseSensitive) }
        if matchAll { flags.insert(.matchAll) }
        if useRegex { flags.insert(.useRegex) }
        if nameOnly { flags.insert(.nameOnly) }
        if extensionOnly { flags.insert(.extensionOnly) }
        if excludeFiles { flags.insert(.excludeFiles) }
        if excludeFolders { flags.insert(.excludeFolders) }
        if excludeSubfolders { flags.insert(.excludeSubfolders) }
        if enumerate { flags.insert(.enumerate) }
        if randomize { flags.insert(.randomize) }
        if metadataEXIF { flags.insert(.metadataEXIF) }
        if metadataXMP { flags.insert(.metadataXMP) }

        switch textTransform {
        case .none: break
        case .uppercase: flags.insert(.uppercase)
        case .lowercase: flags.insert(.lowercase)
        case .titlecase: flags.insert(.titlecase)
        case .capitalized: flags.insert(.capitalized)
        }

        switch timeSource {
        case .none: break
        case .creation: flags.insert(.creationTime)
        case .modification: flags.insert(.modificationTime)
        case .access: flags.insert(.accessTime)
        }

        engine.flags = flags
        schedulePreview()
    }

    private func schedulePreview() {
        engine.searchTerm = searchTerm
        engine.replaceTerm = replaceTerm

        previewTask?.cancel()
        previewTask = Task {
            // Small debounce
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await engine.computePreview()
        }
    }
}

// MARK: - Option Enums for UI

enum TextTransformOption: String, CaseIterable, Identifiable {
    case none = "None"
    case uppercase = "UPPERCASE"
    case lowercase = "lowercase"
    case titlecase = "Title Case"
    case capitalized = "Capitalized"

    var id: String { rawValue }
}

enum TimeSourceOption: String, CaseIterable, Identifiable {
    case none = "None"
    case creation = "Creation"
    case modification = "Modified"
    case access = "Accessed"

    var id: String { rawValue }
}
