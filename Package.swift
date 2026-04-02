// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacRename",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "MacRenameCore", targets: ["MacRenameCore"]),
        .executable(name: "MacRenameApp", targets: ["MacRenameApp"]),
        .executable(name: "macrename", targets: ["MacRenameCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "MacRenameCore",
            path: "Sources/MacRenameCore"
        ),
        .executableTarget(
            name: "MacRenameApp",
            dependencies: ["MacRenameCore"],
            path: "Sources/MacRenameApp"
        ),
        .executableTarget(
            name: "MacRenameCLI",
            dependencies: [
                "MacRenameCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/MacRenameCLI"
        ),
        .testTarget(
            name: "MacRenameCoreTests",
            dependencies: ["MacRenameCore"],
            path: "Tests/MacRenameCoreTests"
        ),
    ]
)
