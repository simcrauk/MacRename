# MacRename Setup Guide

## Building from Command Line (SPM)

```bash
# Build all targets
swift build

# Run the app
swift run MacRenameApp

# Run the CLI
swift run macrename preview --search "old" --replace "new" ~/Documents/*.txt
swift run macrename rename --search "old" --replace "new" --all ~/Documents/*.txt

# Run tests
swift test
```

## Building with Xcode

1. Open `Package.swift` in Xcode:
   ```bash
   open Package.swift
   ```
2. Select the `MacRenameApp` scheme
3. Build and run (Cmd+R)

## Setting Up the Finder Extension

The Finder Sync Extension requires a proper Xcode project with code signing.

### Steps:

1. Open Xcode and create a new project:
   - File > New > Project > macOS > App
   - Product Name: MacRename
   - Bundle Identifier: com.macrename.app
   - Interface: SwiftUI

2. Add the SPM package as a local dependency:
   - File > Add Package Dependencies > Add Local
   - Select the MacRename directory

3. Add a Finder Sync Extension target:
   - File > New > Target > macOS > Finder Sync Extension
   - Product Name: MacRename Finder Extension
   - Replace the generated FinderSync.swift with `Sources/FinderExtension/FinderSync.swift`

4. Configure code signing for both targets

5. Build and run the main app to register the extension

6. Enable the extension:
   - System Settings > Privacy & Security > Extensions > Finder Extensions
   - Enable "MacRename Finder Extension"

## CLI Installation

```bash
# Build release binary
swift build -c release

# Copy to PATH
cp .build/release/macrename /usr/local/bin/

# Verify
macrename --help
```
