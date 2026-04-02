import Foundation

/// Enumerates files and folders from given URLs, optionally recursing into subdirectories.
public enum FileEnumerator {

    /// Creates `RenameItem` instances from the given URLs.
    /// If a URL points to a directory and `recursive` is true, its contents are enumerated.
    /// Items are returned in a stable order: directories first (for depth-first rename safety),
    /// then files, sorted alphabetically within each group at each level.
    public static func enumerate(
        urls: [URL],
        recursive: Bool = true
    ) -> [RenameItem] {
        var items: [RenameItem] = []
        let fm = FileManager.default

        for url in urls {
            let standardized = url.standardizedFileURL
            var isDir: ObjCBool = false

            guard fm.fileExists(atPath: standardized.path, isDirectory: &isDir) else {
                continue
            }

            if isDir.boolValue {
                let folderItem = RenameItem(url: standardized, isFolder: true, depth: 0)
                items.append(folderItem)

                if recursive {
                    let children = enumerateDirectory(
                        standardized,
                        baseDepth: 1,
                        fileManager: fm
                    )
                    items.append(contentsOf: children)
                }
            } else {
                let fileItem = RenameItem(url: standardized, isFolder: false, depth: 0)
                items.append(fileItem)
            }
        }

        return items
    }

    private static func enumerateDirectory(
        _ directoryURL: URL,
        baseDepth: Int,
        fileManager fm: FileManager
    ) -> [RenameItem] {
        var items: [RenameItem] = []

        guard let enumerator = fm.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
            options: [.skipsHiddenFiles]
        ) else {
            return items
        }

        while let itemURL = enumerator.nextObject() as? URL {
            let resourceValues = try? itemURL.resourceValues(
                forKeys: [.isDirectoryKey]
            )
            let isDir = resourceValues?.isDirectory ?? false

            // Depth is based on path components relative to the base directory
            let relativePath = itemURL.path.dropFirst(directoryURL.path.count)
            let depth = baseDepth + relativePath.components(separatedBy: "/").filter { !$0.isEmpty }.count - 1

            let item = RenameItem(url: itemURL, isFolder: isDir, depth: depth)
            items.append(item)
        }

        return items
    }
}
