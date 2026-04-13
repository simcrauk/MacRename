import XCTest
@testable import MacRenameCore

final class RenameEngineAdvancedTests: XCTestCase {

    // MARK: - Regex Tests

    func testRegexReplace() async {
        let engine = RenameEngine()
        engine.searchTerm = "IMG_(\\d{4})(\\d{2})(\\d{2})"
        engine.replaceTerm = "Photo_$1-$2-$3"
        engine.flags = .useRegex

        let item = RenameItem(url: URL(fileURLWithPath: "/tmp/IMG_20240315.jpg"), isFolder: false, depth: 0)
        engine.items = [item]

        await engine.computePreview()

        XCTAssertEqual(item.newName, "Photo_2024-03-15.jpg")
        XCTAssertEqual(item.status, .shouldRename)
    }

    func testRegexReplaceAll() async {
        let engine = RenameEngine()
        engine.searchTerm = "\\s+"
        engine.replaceTerm = "_"
        engine.flags = [.useRegex, .matchAll]

        let item = RenameItem(url: URL(fileURLWithPath: "/tmp/my cool file.txt"), isFolder: false, depth: 0)
        engine.items = [item]

        await engine.computePreview()

        XCTAssertEqual(item.newName, "my_cool_file.txt")
    }

    // MARK: - PowerRename Spec Parity

    /// Enumeration counter must advance per match, not per change.
    /// Mirrors PowerRename's VerifyCounterIncrementsWhenResultIsUnchanged.
    func testEnumerationCounterAdvancesOnUnchangedResult() async {
        let engine = RenameEngine()
        engine.searchTerm = "(.*)"
        engine.replaceTerm = "NewFile-${start=1}"
        engine.flags = [.useRegex, .enumerate]

        // Item #3 already has the name the counter would produce for index 2.
        engine.items = [
            RenameItem(url: URL(fileURLWithPath: "/tmp/DocA"), isFolder: false, depth: 0),
            RenameItem(url: URL(fileURLWithPath: "/tmp/DocB"), isFolder: false, depth: 0),
            RenameItem(url: URL(fileURLWithPath: "/tmp/NewFile-3"), isFolder: false, depth: 0),
            RenameItem(url: URL(fileURLWithPath: "/tmp/DocC"), isFolder: false, depth: 0),
        ]

        await engine.computePreview()

        XCTAssertEqual(engine.items[0].newName, "NewFile-1")
        XCTAssertEqual(engine.items[1].newName, "NewFile-2")
        XCTAssertEqual(engine.items[2].status, .unchanged)
        XCTAssertEqual(engine.items[3].newName, "NewFile-4",
                       "Counter must still advance past the unchanged item.")
    }

    /// Non-breaking space (U+00A0) in a filename is folded to regular space
    /// so copy-pasted search terms match. Mirrors PowerRename's
    /// VerifyUnicodeAndWhitespaceNormalization.
    func testNonBreakingSpaceNormalization() async {
        let engine = RenameEngine()
        engine.searchTerm = "Hello World"
        engine.replaceTerm = "Match"

        let nbsp = "Hello\u{00A0}World.txt"
        let item = RenameItem(url: URL(fileURLWithPath: "/tmp/\(nbsp)"), isFolder: false, depth: 0)
        engine.items = [item]

        await engine.computePreview()

        XCTAssertEqual(item.newName, "Match.txt")
    }

    // MARK: - Folder Tests

    func testFolderRename() async {
        let engine = RenameEngine()
        engine.searchTerm = "old"
        engine.replaceTerm = "new"
        engine.flags = []

        let folder = RenameItem(url: URL(fileURLWithPath: "/tmp/old_project"), isFolder: true, depth: 0)
        engine.items = [folder]

        await engine.computePreview()

        XCTAssertEqual(folder.newName, "new_project")
    }

    func testExtensionOnlySkipsFolders() async {
        let engine = RenameEngine()
        engine.searchTerm = "test"
        engine.replaceTerm = "demo"
        engine.flags = .extensionOnly

        let folder = RenameItem(url: URL(fileURLWithPath: "/tmp/test_folder"), isFolder: true, depth: 0)
        engine.items = [folder]

        await engine.computePreview()

        XCTAssertEqual(folder.status, .excluded)
    }

    // MARK: - Duplicate Detection

    func testDuplicateDetection() async {
        let engine = RenameEngine()
        engine.searchTerm = "\\d+"
        engine.replaceTerm = ""
        engine.flags = [.useRegex, .matchAll]

        let item1 = RenameItem(url: URL(fileURLWithPath: "/tmp/file1.txt"), isFolder: false, depth: 0)
        let item2 = RenameItem(url: URL(fileURLWithPath: "/tmp/file2.txt"), isFolder: false, depth: 0)
        engine.items = [item1, item2]

        await engine.computePreview()

        // Both would become "file.txt" — should detect collision
        XCTAssertEqual(item1.newName, "file.txt")
        XCTAssertEqual(item2.newName, "file.txt")
        // At least one should be marked as duplicate
        let duplicates = engine.items.filter { $0.status == .nameAlreadyExists }
        XCTAssertGreaterThanOrEqual(duplicates.count, 1)
    }

    // MARK: - Transform Without Match

    func testTransformWithoutMatchApplied() async {
        let engine = RenameEngine()
        engine.searchTerm = ".*"
        engine.replaceTerm = "$0"
        engine.flags = [.useRegex, .lowercase]

        let item = RenameItem(url: URL(fileURLWithPath: "/tmp/HELLO.TXT"), isFolder: false, depth: 0)
        engine.items = [item]

        await engine.computePreview()

        XCTAssertEqual(item.newName, "hello.txt")
    }

    // MARK: - Enumeration Integration

    func testEnumerationInRename() async {
        let engine = RenameEngine()
        engine.searchTerm = ".+"
        engine.replaceTerm = "photo_${start=1,increment=1,padding=3}"
        engine.flags = [.useRegex, .enumerate, .nameOnly]

        let item1 = RenameItem(url: URL(fileURLWithPath: "/tmp/a.jpg"), isFolder: false, depth: 0)
        let item2 = RenameItem(url: URL(fileURLWithPath: "/tmp/b.jpg"), isFolder: false, depth: 0)
        let item3 = RenameItem(url: URL(fileURLWithPath: "/tmp/c.jpg"), isFolder: false, depth: 0)
        engine.items = [item1, item2, item3]

        await engine.computePreview()

        XCTAssertEqual(item1.newName, "photo_001.jpg")
        XCTAssertEqual(item2.newName, "photo_002.jpg")
        XCTAssertEqual(item3.newName, "photo_003.jpg")
    }

    // MARK: - Exclude Subfolders

    func testExcludeSubfolders() async {
        let engine = RenameEngine()
        engine.searchTerm = "test"
        engine.replaceTerm = "demo"
        engine.flags = .excludeSubfolders

        let root = RenameItem(url: URL(fileURLWithPath: "/tmp/test.txt"), isFolder: false, depth: 0)
        let sub = RenameItem(url: URL(fileURLWithPath: "/tmp/dir/test.txt"), isFolder: false, depth: 1)
        engine.items = [root, sub]

        await engine.computePreview()

        XCTAssertEqual(root.status, .shouldRename)
        XCTAssertEqual(sub.status, .excluded)
    }

    // MARK: - Invalid Characters

    func testInvalidCharacterDetection() async {
        let engine = RenameEngine()
        engine.searchTerm = "file"
        engine.replaceTerm = "path/file"
        engine.flags = []

        let item = RenameItem(url: URL(fileURLWithPath: "/tmp/file.txt"), isFolder: false, depth: 0)
        engine.items = [item]

        await engine.computePreview()

        XCTAssertEqual(item.status, .invalidCharacters)
    }

    // MARK: - Deselected Items

    func testDeselectedItemsSkipped() async {
        let engine = RenameEngine()
        engine.searchTerm = "test"
        engine.replaceTerm = "demo"
        engine.flags = []

        let item = RenameItem(url: URL(fileURLWithPath: "/tmp/test.txt"), isFolder: false, depth: 0)
        item.isSelected = false
        engine.items = [item]

        await engine.computePreview()

        XCTAssertEqual(item.status, .excluded)
    }

    // MARK: - Case Sensitive Search

    func testCaseSensitiveSearch() async {
        let engine = RenameEngine()
        engine.searchTerm = "Test"
        engine.replaceTerm = "Demo"
        engine.flags = .caseSensitive

        let item1 = RenameItem(url: URL(fileURLWithPath: "/tmp/Test.txt"), isFolder: false, depth: 0)
        let item2 = RenameItem(url: URL(fileURLWithPath: "/tmp/test.txt"), isFolder: false, depth: 0)
        engine.items = [item1, item2]

        await engine.computePreview()

        XCTAssertEqual(item1.newName, "Demo.txt")
        XCTAssertEqual(item1.status, .shouldRename)
        XCTAssertEqual(item2.status, .unchanged)
    }

    // MARK: - Empty Replacement

    func testReplaceWithEmpty() async {
        let engine = RenameEngine()
        engine.searchTerm = "_backup"
        engine.replaceTerm = ""
        engine.flags = []

        let item = RenameItem(url: URL(fileURLWithPath: "/tmp/data_backup.csv"), isFolder: false, depth: 0)
        engine.items = [item]

        await engine.computePreview()

        XCTAssertEqual(item.newName, "data.csv")
    }

    // MARK: - Title Case Name Only

    func testTitleCaseNameOnly() async {
        let engine = RenameEngine()
        engine.searchTerm = ".*"
        engine.replaceTerm = "$0"
        engine.flags = [.useRegex, .titlecase, .nameOnly]

        let item = RenameItem(url: URL(fileURLWithPath: "/tmp/the lord of the rings.txt"), isFolder: false, depth: 0)
        engine.items = [item]

        await engine.computePreview()

        XCTAssertEqual(item.newName, "The Lord of the Rings.txt")
    }
}
