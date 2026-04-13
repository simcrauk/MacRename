# MacRename – Claude Code Instructions

macOS port of PowerToys PowerRename. Pure Swift, SwiftUI, targeting macOS 14 Sonoma.

## Architecture

- **MacRenameCore** – Shared library (no UI deps). Rename engine, token expansion, metadata extraction, file operations.
- **MacRenameApp** – SwiftUI standalone app. Drag-and-drop, live preview, options panel.
- **MacRenameCLI** – `macrename` CLI via swift-argument-parser. `preview` and `rename` subcommands.
- **FinderExtension** – Finder Sync Extension (requires Xcode project for code signing).

## Build & Test

```bash
swift build              # Build all SPM targets (core + CLI)
swift test               # Run 74 unit tests (requires Xcode toolchain)
swift run macrename      # Run the CLI
```

### Standalone app & Finder extension (Xcode)

The GUI app and Finder Sync extension must be built through the Xcode project
(a bare SPM executable isn't a proper `.app` bundle — it won't receive keyboard
focus, and Finder extensions need code signing). The project is defined in
[`project.yml`](project.yml) and generated via XcodeGen:

```bash
brew install xcodegen              # one-time
./scripts/generate-xcodeproj.sh    # regenerate MacRename.xcodeproj
open MacRename.xcodeproj           # ⌘R to run
```

`MacRename.xcodeproj` is gitignored — only `project.yml` is source-of-truth.
Edit `project.yml` and regenerate rather than editing the project in Xcode's
GUI. First-time setup: in Xcode, select the `MacRename` target → Signing &
Capabilities → choose your team (ad-hoc signing works for local runs but
Finder Sync registration needs a real identity).

## Project Structure

```
Sources/MacRenameCore/
  Models/       – RenameFlags, RenameItem, RenameStatus, TextTransform, TimeSource
  Engine/       – RenameEngine, SearchReplace, TokenExpander, enum/random/datetime/metadata tokens
  Transforms/   – CaseTransform, TitleCaseRules
  FileSystem/   – FileEnumerator, FileValidator, FileRenamer
  Metadata/     – MetadataExtractor (ImageIO), MetadataPatterns, MetadataCache
  Settings/     – AppSettings (UserDefaults)
Sources/MacRenameApp/
  Views/        – MainView, SearchReplaceBar, OptionsPanel, FileListView, DropZoneView, StatusBar
  ViewModels/   – AppViewModel
  Utilities/    – URLSchemeHandler
Sources/MacRenameCLI/
  MacRenameCLI.swift
Sources/FinderExtension/
  FinderSync.swift, Info.plist
Tests/MacRenameCoreTests/
  9 test files covering all engine components
```

## Key Rules

- All rename logic lives in MacRenameCore – never put engine logic in the app or CLI targets
- RenameEngine.computePreview() order must match PowerRename's DoRename() pipeline: filter → scope → tokens → regex → transform → trim → validate → dedup
- Token expansion order: enum/random first (in replace string), then regex substitution, then datetime, then metadata
- Use XCTest (not Swift Testing) – SPM + Xcode CLT compatibility
- macOS validation: only `/` and `:` are invalid filename chars; 255 byte filename limit, 1024 PATH_MAX
- Title case exceptions: a, an, to, the, at, by, for, in, of, on, up, and, as, but, or, nor
- FileRenamer renames deepest items first and rolls back all changes on failure

## Style

- Swift 6 strict concurrency – all models are Sendable, RenameEngine is @Observable
- Use `NSRegularExpression` for regex (ECMAScript compatibility matching PowerRename)
- Prefer `async/await` over GCD
- No third-party dependencies except swift-argument-parser (CLI only)

## Reference

The original PowerRename source is at:
- `src/modules/powerrename/lib/` in the PowerToys repo
- Key files: Renaming.cpp (pipeline), PowerRenameRegEx.cpp (regex engine), Helpers.cpp (transforms/datetime)
