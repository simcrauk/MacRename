import XCTest
@testable import MacRenameCore

final class FileValidatorTests: XCTestCase {

    func testValidFilename() {
        let status = FileValidator.validate(newName: "photo.jpg", parentPath: "/Users/test", isFolder: false)
        XCTAssertEqual(status, .shouldRename)
    }

    func testSlashInvalid() {
        let status = FileValidator.validate(newName: "path/file.txt", parentPath: "/Users/test", isFolder: false)
        XCTAssertEqual(status, .invalidCharacters)
    }

    func testColonInvalid() {
        let status = FileValidator.validate(newName: "file:name.txt", parentPath: "/Users/test", isFolder: false)
        XCTAssertEqual(status, .invalidCharacters)
    }

    func testEmptyInvalid() {
        let status = FileValidator.validate(newName: "", parentPath: "/Users/test", isFolder: false)
        XCTAssertEqual(status, .invalidCharacters)
    }

    func testFilenameTooLong() {
        let longName = String(repeating: "a", count: 256)
        let status = FileValidator.validate(newName: longName, parentPath: "/tmp", isFolder: false)
        XCTAssertEqual(status, .filenameTooLong)
    }

    func testTrimWhitespace() {
        let result = FileValidator.trimFilename("  hello world  ")
        XCTAssertEqual(result, "hello world")
    }

    func testTrimDots() {
        let result = FileValidator.trimFilename("file...")
        XCTAssertEqual(result, "file")
    }

    func testTrimCombined() {
        let result = FileValidator.trimFilename("  hello. . ")
        XCTAssertEqual(result, "hello")
    }
}
