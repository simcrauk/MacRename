# MacRename — macOS Port of PowerToys PowerRename

## Context

PowerRename is a bulk file renaming tool in Microsoft PowerToys for Windows. We're creating a native macOS equivalent called **MacRename** at `~/Projects/MacRename/`. The goal is feature parity with PowerRename's rename engine, adapted for macOS conventions.

**Decisions made:**
- Pure Swift, SwiftUI, macOS 14 Sonoma minimum
- Three targets: standalone app, Finder extension, CLI tool
- Shared core library with no UI dependencies

## Project Structure

```
~/Projects/MacRename/
├── Package.swift                          # SPM package definition
├── project.yml                            # XcodeGen config → MacRename.xcodeproj
├── scripts/
│   ├── generate-xcodeproj.sh              # Regenerate Xcode project from project.yml
│   ├── test-cli.sh                        # CLI integration tests (23 scenarios)
│   ├── perf-test.sh                       # Preview + rename benchmark on N files
│   └── generate-exif-fixtures.swift       # Produce JPEGs with known EXIF
├── Sources/
│   ├── MacRenameCore/                     # Shared engine library
│   │   ├── Models/
│   │   │   ├── RenameFlags.swift          # OptionSet matching PowerRename flags
│   │   │   ├── RenameItem.swift           # File/folder item with original/new name
│   │   │   ├── RenameStatus.swift         # Validation status enum
│   │   │   ├── TextTransform.swift        # Uppercase/lowercase/titlecase/capitalized
│   │   │   └── TimeSource.swift           # Creation/modification/access time
│   │   ├── Engine/
│   │   │   ├── RenameEngine.swift         # Central orchestrator (@Observable)
│   │   │   ├── SearchReplace.swift        # Regex and literal search/replace
│   │   │   ├── TokenExpander.swift        # Coordinates all token expansion
│   │   │   ├── EnumerationToken.swift     # ${start=X,increment=Y,padding=Z} parsing & expansion
│   │   │   ├── RandomizerToken.swift      # ${rstringalnum=N}, ${ruuidv4}, etc.
│   │   │   ├── DateTimeToken.swift        # $YYYY, $MM, $DD, $HH, etc.
│   │   │   └── MetadataToken.swift        # $CAMERA_MAKE, $ISO, etc.
│   │   ├── Metadata/
│   │   │   ├── MetadataExtractor.swift    # CGImageSource-based EXIF/XMP extraction
│   │   │   ├── MetadataPatterns.swift     # Pattern name constants (EXIF + XMP)
│   │   │   └── MetadataCache.swift        # Per-file metadata cache
│   │   ├── FileSystem/
│   │   │   ├── FileEnumerator.swift       # Recursive directory enumeration
│   │   │   ├── FileRenamer.swift          # FileManager rename with undo support
│   │   │   └── FileValidator.swift        # Invalid chars (/ :), path length (1024/255)
│   │   ├── Transforms/
│   │   │   ├── CaseTransform.swift        # Uppercase, lowercase, titlecase, capitalized
│   │   │   └── TitleCaseRules.swift       # Exception words: a, an, the, at, by, for...
│   │   └── Settings/
│   │       └── AppSettings.swift          # UserDefaults-backed settings
│   │
│   ├── MacRenameApp/                      # SwiftUI standalone app
│   │   ├── MacRenameApp.swift             # @main App entry point
│   │   ├── Info.plist                     # App bundle config + URL scheme
│   │   ├── MacRename.entitlements         # user-selected files, sandbox off
│   │   ├── Views/
│   │   │   ├── MainView.swift             # Primary window layout + drop handler
│   │   │   ├── SearchReplaceBar.swift     # Search/replace fields + TokenMenu
│   │   │   ├── FileListView.swift         # Table with original/new/status columns
│   │   │   ├── DropZoneView.swift         # Empty state with drop target
│   │   │   ├── OptionsPanel.swift         # Collapsible flags panel
│   │   │   └── StatusBar.swift            # Counts, rename/undo/clear buttons
│   │   ├── ViewModels/
│   │   │   └── AppViewModel.swift         # Bridges RenameEngine to UI
│   │   └── Utilities/
│   │       └── URLSchemeHandler.swift      # macrename:// URL scheme parser
│   │
│   ├── FinderExtension/                   # Finder Sync Extension
│   │   ├── FinderSync.swift               # FIFinderSync subclass
│   │   ├── Info.plist
│   │   └── FinderExtension.entitlements   # sandbox on, user-selected files
│   │
│   └── MacRenameCLI/                      # Command-line tool
│       └── MacRenameCLI.swift             # ArgumentParser entry point
│
├── Tests/
│   ├── MacRenameCoreTests/
│   │   ├── SearchReplaceTests.swift        # 9 tests — regex & literal matching
│   │   ├── EnumerationTokenTests.swift     # 7 tests — counter parsing & output
│   │   ├── RandomizerTokenTests.swift      # 7 tests — random string generation
│   │   ├── DateTimeTokenTests.swift        # 7 tests — date/time pattern expansion
│   │   ├── TokenExpanderTests.swift        # 9 tests — coordinated token expansion
│   │   ├── CaseTransformTests.swift        # 7 tests — all four case transformations
│   │   ├── FileValidatorTests.swift        # 8 tests — macOS filename validation
│   │   ├── RenameEngineTests.swift         # 7 tests — basic engine scenarios
│   │   └── RenameEngineAdvancedTests.swift # 13 tests — regex, folders, dupes, edge cases
│   └── Fixtures/                           # CLI integration test fixture tree
│       ├── simple/, match-all/, mixed-case/, scope/, nested/
│       ├── enum/, regex/, tricky-names/, random/, invalid/
│       └── (TODO: images/ with real EXIF JPEGs for metadata tests)
```

## Key Types

### RenameFlags (OptionSet)
```swift
struct RenameFlags: OptionSet {
    static let caseSensitive, matchAll, useRegex, enumerate, excludeFiles,
               excludeFolders, excludeSubfolders, nameOnly, extensionOnly,
               uppercase, lowercase, titlecase, capitalized, randomize,
               creationTime, modificationTime, accessTime, metadataEXIF, metadataXMP
}
```

### RenameItem
```swift
@Observable class RenameItem: Identifiable {
    let id: UUID
    let url: URL
    let originalName: String
    var newName: String?
    let isFolder: Bool
    let depth: Int
    var isSelected: Bool
    var status: RenameStatus
}
```

### RenameEngine (orchestrator)
```swift
@Observable class RenameEngine {
    var searchTerm: String
    var replaceTerm: String
    var flags: RenameFlags
    var items: [RenameItem]

    func addItems(urls: [URL], recursive: Bool)
    func computePreview() async        // Regex phase — compute all new names
    func executeRename() async throws   // File operation phase — perform renames
}
```

## Implementation Phases

### Phase 1: Project Setup & Core Models — DONE
- SPM package with MacRenameCore, MacRenameApp, MacRenameCLI targets
- `RenameFlags`, `RenameItem`, `RenameStatus`, `TextTransform`, `TimeSource` models
- `FileValidator` (macOS rules: no `/` or `:`, 255 byte filename, 1024 PATH_MAX)
- `FileEnumerator` using `FileManager.enumerator(at:)`
- **Tests**: FileValidatorTests (8 tests)

### Phase 2: Search & Replace Engine — DONE
- `SearchReplace.swift`: Literal and regex via `NSRegularExpression` (ECMAScript mode)
- `CaseTransform.swift`: Uppercase, lowercase, capitalized, titlecase with exception list
- Scoped transforms (name only / extension only / full)
- **Tests**: SearchReplaceTests (9 tests), CaseTransformTests (7 tests)

### Phase 3: Token Expansion — DONE
- `EnumerationToken.swift`: `${start=X,increment=Y,padding=Z}` parsing and expansion
- `RandomizerToken.swift`: `${rstringalnum=N}`, `${rstringalpha=N}`, `${rstringdigit=N}`, `${ruuidv4}`
- `DateTimeToken.swift`: `$YYYY`..`$f` patterns expanded from file timestamps
- `TokenExpander.swift`: Coordinates expansion order (enum/random → regex → datetime → metadata)
- **Tests**: EnumerationTokenTests (7), RandomizerTokenTests (7), DateTimeTokenTests (7), TokenExpanderTests (9)

### Phase 4: Metadata Extraction — DONE
- `MetadataExtractor.swift`: CGImageSource-based EXIF/XMP extraction via ImageIO
- `MetadataPatterns.swift`: All pattern constants (CAMERA_MAKE, ISO, DATE_TAKEN_*, CREATOR, TITLE, etc.)
- `MetadataCache.swift`: Thread-safe actor-based per-URL cache
- `MetadataToken.swift`: Expands `$PATTERN_NAME` tokens using extracted values

### Phase 5: Engine Orchestrator — DONE
- `RenameEngine.swift` with full 10-step pipeline matching PowerRename's DoRename():
  filter → scope → time → metadata → tokens → search/replace → reassemble → trim → transform → validate
- `FileRenamer.swift`: Depth-first rename with atomic rollback on failure
- Duplicate name detection (case-insensitive, per-directory)
- Undo support via `RenamePair` tracking
- **Tests**: RenameEngineTests (7), RenameEngineAdvancedTests (13)

### Phase 6: SwiftUI App — DONE
- `MainView` with search/replace bar, collapsible options panel, file table, status bar
- Drag-and-drop and File > Open (Cmd+O) for adding files
- Live preview with 150ms debounce on input changes
- Token helper menu for inserting enum/random/datetime/metadata patterns
- Rename button with confirmation dialog, progress indicator, error display
- Undo button (Cmd+Z), Select All / Deselect All commands
- URL scheme handler (`macrename://open?files=...`) for Finder extension integration

### Phase 7: Finder Extension — DONE (build), needs real signing for runtime registration
- `FinderSync.swift`: FIFinderSync subclass with "Rename with MacRename" context menu
- `Info.plist` + `FinderExtension.entitlements` for sandboxed extension
- Launches main app via URL scheme, falls back to pasteboard
- Xcode project at `project.yml` (XcodeGen) embeds the `.appex` inside the `.app`;
  `scripts/generate-xcodeproj.sh` regenerates `MacRename.xcodeproj` on demand
- **TODO**: Sign with a real Apple Developer ID so Finder will actually register the
  extension and surface the context menu item (ad-hoc signing builds but won't load
  in Finder)

### Phase 8: CLI Tool — DONE
- `swift-argument-parser` based with `preview` and `rename` subcommands
  (root command is `AsyncParsableCommand` so async subcommands actually run)
- Full flag coverage: `--search`/`-s`, `--replace`/`-r`, `--regex`,
  `--case-sensitive`, `--all`/`-a`, `--name-only`, `--extension-only`,
  `--uppercase`, `--lowercase`, `--titlecase`, `--capitalized`,
  `--enumerate`, `--randomize`, `--creation-time`, `--modification-time`,
  `--access-time`, `--exclude-files`, `--exclude-folders`, `--no-recurse`
- Accepts file paths as positional arguments

### Phase 9: Polish & Testing — MOSTLY DONE
- 74 unit tests across 9 test suites, all passing
- 19 CLI integration scenarios at `scripts/test-cli.sh` using fixture tree
  at `Tests/Fixtures/` (simple/match-all/mixed-case/scope/nested/enum/regex/
  tricky-names/random/invalid). Covers search/replace variants, case transforms,
  scope flags, recursion, regex with capture groups, enumeration, randomize,
  datetime tokens, unicode/space filenames, and validation errors
- Duplicate detection, rollback on failure, confirmation dialog
- FileRenamer handles case-only renames via temp-name two-step (APFS/HFS+)
- FileEnumerator returns children sorted folders-first, `localizedStandardCompare`
- Settings persistence: `AppSettings` is wired into `AppViewModel`; last
  search/replace terms persist across launches (`persistState` defaults to true)
- MRU history: `searchMRU` / `replaceMRU` in `AppSettings`, pushed on each
  successful rename, surfaced via clock-icon menus in `SearchReplaceBar`
- EXIF fixtures: `scripts/generate-exif-fixtures.swift` produces tiny JPEGs with
  known TIFF/EXIF (Canon EOS 5D / Nikon D850) at `Tests/Fixtures/images/`; three
  CLI scenarios verify metadata extraction
- Performance: `scripts/perf-test.sh` benchmarks preview + rename; 10k-file
  baseline on APFS SSD is preview ≈ 1.0s, rename ≈ 1.4s
- PowerRename spec parity (via local `PowerToys/` checkout):
  - Enumeration counter advances per match, not per visible change
    (matches `VerifyCounterIncrementsWhenResultIsUnchanged`)
  - First-match regex no longer double-replaces zero-width patterns like `(.*)`
  - NFC normalization + non-breaking-space folding at SearchReplace entry
    (matches `VerifyUnicodeAndWhitespaceNormalization`)
  - Remaining audit gap: only a low-priority randomizer edge case
    (negative lengths on `${rstringalpha=-N}`), not worth fixing
- Accessibility: VoiceOver labels across `SearchReplaceBar`, `OptionsPanel`,
  `StatusBar`, `FileListView`, `DropZoneView`; decorative icons hidden;
  grouped counts announced as a single item
- Keyboard shortcuts throughout the app
- **TODO**: Manual VoiceOver QA pass on a real build (label strings exist but
  interaction flow hasn't been walked through end-to-end)

### Phase 10: Xcode Project & Build Tooling — DONE
- `project.yml` drives XcodeGen; `.xcodeproj` is gitignored and regenerated
- `MacRenameApp` activation policy set to `.regular` so `swift run` gains key focus
- Entitlements files for app (sandbox off, user-selected files) and extension
  (sandbox on)
- `scripts/generate-xcodeproj.sh` and `scripts/test-cli.sh` wrappers
- Xcode build (`xcodebuild -scheme MacRename`) and `swift test` both green

## Reference Files (PowerRename source)

These files should be consulted during implementation:

| File | Used For |
|------|----------|
| `src/modules/powerrename/lib/Renaming.cpp` | DoRename() pipeline — the master logic to port |
| `src/modules/powerrename/lib/Helpers.cpp` | Date/time expansion, case transforms, metadata expansion, validation |
| `src/modules/powerrename/lib/PowerRenameRegEx.cpp` | Replace() method — token + regex ordering |
| `src/modules/powerrename/lib/PowerRenameInterfaces.h` | Flag definitions, status enums |
| `src/modules/powerrename/lib/Enumerating.h/.cpp` | Enumeration token syntax and math |
| `src/modules/powerrename/lib/Randomizer.h/.cpp` | Random token types and generation |
| `src/modules/powerrename/lib/MetadataTypes.h` | EXIF/XMP pattern name constants |
| `src/modules/powerrename/lib/MetadataPatternExtractor.h/.cpp` | Metadata extraction flow |
| `src/modules/powerrename/unittests/CommonRegExTests.h` | Test cases as behavioral spec |

## macOS vs Windows Differences

| Concern | Windows (PowerRename) | macOS (MacRename) |
|---------|----------------------|-------------------|
| Invalid filename chars | `< > : " \ / \| ? *` | `/` and `:` only |
| Max path length | 260 (files), 247 (folders) | 1024 (PATH_MAX) |
| Max filename length | 260 | 255 |
| Regex library | std::wregex / boost::wregex | NSRegularExpression |
| Metadata extraction | Windows Imaging Component | CGImageSource (ImageIO) |
| HEIF support | Requires Store extension | Native |
| File operations | IFileOperation COM | FileManager.moveItem |
| Threading | CreateThread + SRW locks | Swift concurrency (async/await) |
| Settings | Registry + JSON | UserDefaults |
| Shell integration | IContextMenu COM | FIFinderSync |
| Unicode normalization | NFC via NormalizeString | String in Swift is already Unicode-correct; use precomposedStringWithCanonicalMapping |

## Verification

- **Unit tests**: `swift test` — all core engine tests pass
- **Manual app test**: Launch app, drop files, verify preview, execute rename, undo
- **Finder test**: Right-click files in Finder, verify context menu appears and launches app
- **CLI test**: `macrename preview --search "IMG" --replace "Photo" ~/Pictures/*.jpg`
- **Edge cases**: Files with Unicode names, deeply nested folders, 10k+ items, images with/without EXIF
