import Foundation

/// Central orchestrator for the rename pipeline.
/// Manages items, computes preview names, and executes file renames.
/// Matches PowerRename's CPowerRenameManager + DoRename flow.
@Observable
public final class RenameEngine: @unchecked Sendable {
    public var searchTerm: String = ""
    public var replaceTerm: String = ""
    public var flags: RenameFlags = []
    public var items: [RenameItem] = []

    private let metadataCache = MetadataCache()

    public init() {}

    // MARK: - Item Management

    /// Adds files/folders from the given URLs.
    public func addItems(urls: [URL], recursive: Bool = true) {
        let newItems = FileEnumerator.enumerate(urls: urls, recursive: recursive)
        items.append(contentsOf: newItems)
    }

    /// Removes all items and resets state.
    public func clearItems() {
        items.removeAll()
    }

    // MARK: - Preview Computation

    /// Computes new names for all items based on current search/replace/flags.
    /// This is the "regex phase" — no files are modified.
    public func computePreview() async {
        // Reset all items
        for item in items {
            item.reset()
        }

        guard !searchTerm.isEmpty else { return }

        var enumIndex = 0

        for item in items {
            let shouldProcess = shouldProcessItem(item)

            if !shouldProcess {
                item.status = .excluded
                continue
            }

            await processItem(item, enumIndex: &enumIndex)
        }
    }

    /// Processes a single item through the full rename pipeline.
    /// Matches Renaming.cpp DoRename() flow.
    private func processItem(_ item: RenameItem, enumIndex: inout Int) async {
        // 1. Determine source name based on scoping flags
        let sourceName = extractSourceName(from: item)

        // 2. Build the replacement template with token expansion
        var currentReplace = replaceTerm

        // 2a. Expand enumeration and randomizer tokens
        currentReplace = TokenExpander.expandInlineTokens(
            currentReplace,
            flags: flags,
            enumIndex: enumIndex
        )

        // 2b. Expand date/time tokens if a time source is active
        if let timeSource = flags.timeSource,
           let fileDate = item.fileTime(for: timeSource),
           DateTimeToken.containsTokens(in: replaceTerm) {
            currentReplace = TokenExpander.expandDateTimeTokens(currentReplace, date: fileDate)
        }

        // 2c. Expand metadata tokens if metadata source is active
        if flags.usesMetadata && MetadataToken.containsTokens(in: replaceTerm) {
            let ext = item.fileExtension.lowercased()
            if !item.isFolder && MetadataPatterns.supportsMetadata(fileExtension: ext) {
                let patterns = await metadataCache.patterns(
                    for: item.url,
                    exif: flags.contains(.metadataEXIF),
                    xmp: flags.contains(.metadataXMP)
                )
                currentReplace = TokenExpander.expandMetadataTokens(currentReplace, patterns: patterns)
            }
        }

        // 3. Perform search/replace
        let result = SearchReplace.replace(
            in: sourceName,
            searchTerm: searchTerm,
            replaceTerm: currentReplace,
            flags: flags
        )

        var newName = result.output

        // 4. If no match but text transform is active, apply transform to source
        if newName == nil && flags.textTransform != nil {
            newName = sourceName
        }

        guard var computedName = newName else {
            item.status = .unchanged
            return
        }

        // 5. Reassemble full filename from scoped part
        computedName = reassembleName(computedName, for: item)

        // 6. Trim whitespace and trailing dots
        computedName = FileValidator.trimFilename(computedName)

        // 7. Apply text transformation
        if let transform = flags.textTransform {
            computedName = CaseTransform.apply(transform, to: computedName, flags: flags)
        }

        // 8. Check if name actually changed
        if computedName == item.originalName {
            item.status = .unchanged
            return
        }

        // 9. Validate
        let validationStatus = FileValidator.validate(
            newName: computedName,
            parentPath: item.parentPath,
            isFolder: item.isFolder
        )

        item.newName = computedName
        item.status = validationStatus

        // 10. Increment enum index if match was found
        if result.matched {
            enumIndex += 1
        }
    }

    // MARK: - File Operations

    /// Executes the rename operation on all items with status `.shouldRename`.
    /// Renames depth-first (deepest items first) to avoid path invalidation.
    public func executeRename() async throws -> [RenamePair] {
        let toRename = items
            .filter { $0.status == .shouldRename && $0.newName != nil }
            .sorted { $0.depth > $1.depth } // Deepest first

        var completed: [RenamePair] = []

        for item in toRename {
            guard let newName = item.newName else { continue }
            let sourceURL = item.url
            let destURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName)

            try FileManager.default.moveItem(at: sourceURL, to: destURL)
            completed.append(RenamePair(source: sourceURL, destination: destURL))
        }

        return completed
    }

    /// Undoes a set of renames by reversing each pair.
    public func undoRenames(_ pairs: [RenamePair]) throws {
        // Undo in reverse order (shallowest first, since we renamed deepest first)
        for pair in pairs.reversed() {
            try FileManager.default.moveItem(at: pair.destination, to: pair.source)
        }
    }

    // MARK: - Helpers

    /// Determines whether an item should be processed based on exclusion flags.
    private func shouldProcessItem(_ item: RenameItem) -> Bool {
        if flags.contains(.excludeFolders) && item.isFolder { return false }
        if flags.contains(.excludeFiles) && !item.isFolder { return false }
        if flags.contains(.excludeSubfolders) && item.depth > 0 { return false }
        // extensionOnly doesn't apply to folders
        if flags.contains(.extensionOnly) && item.isFolder { return false }
        if !item.isSelected { return false }
        return true
    }

    /// Extracts the portion of the filename to search within, based on scoping flags.
    private func extractSourceName(from item: RenameItem) -> String {
        if item.isFolder {
            return item.originalName
        }

        if flags.contains(.nameOnly) {
            return item.stem
        }

        if flags.contains(.extensionOnly) {
            return item.fileExtension
        }

        return item.originalName
    }

    /// Reassembles the full filename after search/replace on a scoped part.
    private func reassembleName(_ processedPart: String, for item: RenameItem) -> String {
        if item.isFolder {
            return processedPart
        }

        let ext = item.fileExtension

        if flags.contains(.nameOnly) && !ext.isEmpty {
            return "\(processedPart).\(ext)"
        }

        if flags.contains(.extensionOnly) && !ext.isEmpty {
            return "\(item.stem).\(processedPart)"
        }

        return processedPart
    }
}

/// Records a rename operation for undo support.
public struct RenamePair: Sendable {
    public let source: URL
    public let destination: URL
}
