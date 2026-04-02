import Foundation

/// Performs file rename operations with rollback support on failure.
public enum FileRenamer {

    /// Renames all items with `.shouldRename` status, deepest first.
    /// If any rename fails, previously completed renames are rolled back.
    ///
    /// - Parameter items: The rename items to process.
    /// - Returns: Array of completed rename pairs for undo support.
    /// - Throws: `RenameError` if an operation fails after rollback.
    public static func execute(items: [RenameItem]) throws -> [RenamePair] {
        let toRename = items
            .filter { $0.status == .shouldRename && $0.newName != nil }
            .sorted { $0.depth > $1.depth }

        var completed: [RenamePair] = []
        let fm = FileManager.default

        for item in toRename {
            guard let newName = item.newName else { continue }
            let sourceURL = item.url
            let destURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName)

            // Check destination doesn't already exist
            if fm.fileExists(atPath: destURL.path) {
                // Rollback everything done so far
                rollback(completed)
                throw RenameError.destinationExists(
                    source: sourceURL.lastPathComponent,
                    destination: newName
                )
            }

            do {
                try fm.moveItem(at: sourceURL, to: destURL)
                completed.append(RenamePair(source: sourceURL, destination: destURL))
            } catch {
                // Rollback everything done so far
                rollback(completed)
                throw RenameError.renameFailed(
                    source: sourceURL.lastPathComponent,
                    destination: newName,
                    underlying: error
                )
            }
        }

        return completed
    }

    /// Undoes a set of renames by moving files back to their original locations.
    /// Processes in reverse order (shallowest first, since execute went deepest first).
    public static func undo(_ pairs: [RenamePair]) throws {
        for pair in pairs.reversed() {
            try FileManager.default.moveItem(at: pair.destination, to: pair.source)
        }
    }

    /// Best-effort rollback — logs failures but doesn't throw.
    private static func rollback(_ pairs: [RenamePair]) {
        for pair in pairs.reversed() {
            try? FileManager.default.moveItem(at: pair.destination, to: pair.source)
        }
    }
}

/// Errors that can occur during rename operations.
public enum RenameError: LocalizedError {
    case destinationExists(source: String, destination: String)
    case renameFailed(source: String, destination: String, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .destinationExists(let source, let dest):
            return "Cannot rename '\(source)' to '\(dest)': a file with that name already exists."
        case .renameFailed(let source, let dest, let error):
            return "Failed to rename '\(source)' to '\(dest)': \(error.localizedDescription)"
        }
    }
}
