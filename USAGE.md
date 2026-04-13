# MacRename — Usage Guide

MacRename is a bulk file-renaming tool for macOS — a native port of PowerToys'
PowerRename. It comes in three forms:

- **Standalone app** (drag-and-drop GUI)
- **`macrename` CLI** (scriptable, composable with the shell)
- **Finder Sync extension** (right-click in Finder → "Rename with MacRename")

This guide covers day-to-day usage. For architecture and build instructions,
see [CLAUDE.md](CLAUDE.md) and [PLAN.md](PLAN.md).

---

## Quick start (app)

1. Launch **MacRename**.
2. Drag files or folders into the window, or click **Choose Files...**
3. Type in **Search for…** and **Replace with…**
4. The preview updates after ~150ms. Rows that will change show a blue
   **Rename** badge; rows with problems (invalid characters, collisions, name
   too long) show a red/orange badge.
5. Uncheck any row you want to skip.
6. Click **Rename N File(s)** and confirm. Renamed rows flip to a green
   **Renamed** badge.
7. **⌘Z** undoes the last batch.

Your last search/replace terms persist across launches, and a clock-icon menu
next to each field offers recent entries.

---

## Search modes

| Mode | How it matches |
|------|----------------|
| **Literal** (default) | Exact text, case-insensitive |
| **Case sensitive** (`Aa`) | Distinguishes case |
| **Regex** (`.*`) | Full regular expression (NSRegularExpression / ICU) |
| **Match all** (`All`) | Replace every occurrence, not just the first |

NFC normalization and non-breaking-space folding happen automatically, so
copy-pasted search terms won't silently miss.

---

## Scope — what gets touched

- **Apply to: Full name / Name only** — with *Name only* on, the extension is
  preserved; the search/replace only sees the stem.
- **Extension only** — the stem is preserved; the search/replace only sees
  the extension.
- **Exclude files / Exclude folders** — limit the target kind.
- **Exclude subfolders** — when a folder is added, don't recurse into it.

---

## Text transforms

Apply *after* the search/replace. Radio-style — only one active at a time:

- **UPPERCASE** — `Report.txt` → `REPORT.TXT`
- **lowercase** — `Report.txt` → `report.txt`
- **Title Case** — `the quick brown fox.txt` → `The Quick Brown Fox.txt`
  (with the conventional exception list: *a, an, to, the, at, by, for, in, of,
  on, up, and, as, but, or, nor* — unless they're the first or last word)
- **Capitalized** — `report` → `Report`

If the search finds no match but a transform is active, the transform applies
to the whole name anyway.

---

## Tokens

Tokens expand inside the **Replace** string. The Options panel has toggles
that must be on for each category (`Enumerate`, `Randomize`, `Time source`,
EXIF/XMP). Use the token menu (curly-brace icon next to **Replace**) to
insert them without typos.

### Enumeration — `Enumerate` toggle

`${start=N,increment=N,padding=N}` — a per-item counter.

| Input | Items | Output |
|-------|-------|--------|
| Replace = `file_${start=1,padding=3}`, Search = `.*`, Regex on | `a.txt`, `b.txt`, `c.txt` | `file_001.txt`, `file_002.txt`, `file_003.txt` |

The counter advances on every match, even when the computed name happens to
equal the original (so indexing stays monotonic across already-correct items).

### Random — `Randomize` toggle

- `${rstringalnum=N}` — N alphanumeric chars
- `${rstringalpha=N}` — N letters
- `${rstringdigit=N}` — N digits
- `${ruuidv4}` — a UUID v4

### Date / time — pick a `Time source`

Expanded from the file's **creation**, **modification**, or **access** time.

| Token | Meaning | Example |
|-------|---------|---------|
| `$YYYY` / `$YY` / `$Y` | year | `2026` / `26` / `2026` |
| `$MMMM` / `$MMM` / `$MM` / `$M` | month | `March` / `Mar` / `03` / `3` |
| `$DDDD` / `$DDD` / `$DD` / `$D` | day of week / day | `Tuesday` / `Tue` / `15` / `15` |
| `$HH` / `$H` | hour (24h) | `14` / `14` |
| `$hh` / `$h` | hour (12h) | `02` / `2` |
| `$TT` / `$tt` | AM/PM | `PM` / `pm` |
| `$mm` / `$m` / `$ss` / `$s` | minute / second | `05` / `5` / `09` / `9` |
| `$fff` / `$ff` / `$f` | milliseconds | `123` / `12` / `1` |

### Image metadata — `EXIF` / `XMP` toggles

Reads from the file via ImageIO. Works on `.jpg`, `.jpeg`, `.png`, `.tif`,
`.tiff`, `.heic`, `.heif`, `.dng`, `.cr2`, `.nef`, `.arw`, and similar.

Common EXIF tokens: `$CAMERA_MAKE`, `$CAMERA_MODEL`, `$LENS`, `$ISO`,
`$APERTURE`, `$SHUTTER`, `$FOCAL`, `$FLASH`, `$WIDTH`, `$HEIGHT`,
`$LATITUDE`, `$LONGITUDE`, `$ALTITUDE`, `$DATE_TAKEN_YYYY`, `$DATE_TAKEN_MM`,
`$DATE_TAKEN_DD`, `$DATE_TAKEN_HH`, `$DATE_TAKEN_mm`, `$DATE_TAKEN_SS`.

XMP/IPTC tokens: `$CREATOR`, `$CREATOR_TOOL`, `$TITLE`, `$DESCRIPTION`,
`$SUBJECT`, `$RIGHTS`, `$CREATE_DATE_YYYY`, etc.

Unknown tokens are left in place so you can spot typos.

---

## Regex cheat sheet

MacRename uses `NSRegularExpression` (ICU flavor), close to ECMAScript.

| Pattern | Matches |
|---------|---------|
| `.` | Any character except newline |
| `.*` | Any run of characters (greedy) |
| `.*?` | Any run (lazy) |
| `\d` `\D` | Digit / non-digit |
| `\w` `\W` | Word / non-word character |
| `\s` `\S` | Whitespace / non-whitespace |
| `^` `$` | Start / end of string |
| `[abc]` `[^abc]` | Character class / negated |
| `(foo)` | Capture group |
| `(?:foo)` | Non-capturing group |
| `foo\|bar` | Alternation |
| `x{n}` `x{n,}` `x{n,m}` | Quantifiers |
| `$1`, `$2`, ... | Backreference in the **Replace** string |

### Useful recipes

- **Strip prefix**: `^IMG_` → `` (empty)
- **Reorder `dd.mm.yy` → `yyyymmdd`**:
  Search `(\d{2})\.(\d{2})\.(\d{2})`, Replace `20$3$2$1`
- **Drop garbage and keep only the date**:
  Search `^.*?(\d{2})\.(\d{2})\.(\d{2})`, Replace `20$3$2$1`
- **Normalize whitespace**: Search `\s+`, Replace `_`, *Match all* on
- **Uppercase the extension only**: Scope = *Extension only*, Transform =
  UPPERCASE, Search = `.+`, Regex on

---

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘O** | Open Files… |
| **⌘A** | Select all rows |
| **⇧⌘D** | Deselect all rows |
| **⌘↩** | Rename (with confirmation) |
| **⌘Z** | Undo last rename batch |

---

## CLI — `macrename`

Build & install:

```bash
swift build -c release
cp .build/release/macrename /usr/local/bin/   # optional
```

Two subcommands: `preview` (dry run) and `rename` (commit). They take the
same flags.

```bash
macrename preview [flags] <paths>...
macrename rename  [flags] <paths>...
```

Paths may be files or directories. Directories are enumerated recursively
unless `--no-recurse` is set.

### Flags

**Required**
- `-s, --search <pattern>` — the search term

**Optional**
- `-r, --replace <pattern>` — replacement (default: empty)
- `--regex` — enable regular expressions
- `--case-sensitive` — exact-case matching
- `-a, --all` — match every occurrence, not just the first
- `--name-only` — scope to the filename stem
- `--extension-only` — scope to the file extension
- `--uppercase` / `--lowercase` / `--titlecase` / `--capitalized` — transform
- `--enumerate` — enable `${start=,increment=,padding=}` tokens
- `--randomize` — enable `${rstring…}` and `${ruuidv4}` tokens
- `--creation-time` / `--modification-time` / `--access-time` — time source
  for `$YYYY`-family date tokens
- `--exif` / `--xmp` — enable metadata tokens
- `--exclude-files` / `--exclude-folders` — restrict target kind
- `--no-recurse` — don't descend into subfolders

### CLI recipes

```bash
# Preview first, always
macrename preview -s 'IMG_' -r 'Photo_' ~/Pictures/*.jpg

# Camera-style rename from EXIF
macrename rename --exif --name-only --regex -s '.+' \
  -r '$CAMERA_MAKE-$DATE_TAKEN_YYYY$DATE_TAKEN_MM$DATE_TAKEN_DD-ISO$ISO' \
  ~/Pictures/vacation/*.jpg

# Strip "garbage " and a dd.mm.yy date → yyyymmdd
macrename rename --regex -s '^.*?(\d{2})\.(\d{2})\.(\d{2})' \
  -r '20$3$2$1' ~/Downloads/*.pdf

# Sequence N screenshots
macrename rename --enumerate -s '.*' --regex \
  -r 'screenshot-${start=1,padding=3}' ~/Desktop/Screenshot*.png

# Lowercase all extensions under a tree
macrename rename --extension-only --lowercase -s '.+' --regex ~/Archive/
```

---

## Statuses

In the app's rightmost column and in the CLI's preview output:

| Status | Meaning |
|--------|---------|
| **Rename** (blue) | Will be renamed once you click Rename |
| **Renamed** (green) | Successfully renamed on disk |
| **Excluded** | Unchecked, or filtered out by an *Exclude* flag |
| **Invalid** | New name contains `/` or `:` |
| **Too long** | New filename exceeds 255 bytes or path exceeds 1024 |
| **Exists** | Another item would rename to the same name |
| *(blank)* | No change — the search didn't match, and no transform is active |

---

## Troubleshooting

- **Right-click "Rename with MacRename" isn't appearing in Finder.** The
  extension needs to be signed with a real Developer ID — ad-hoc signing from
  `swift build` isn't enough for Finder to register it. Build the app target
  via Xcode with a signing team selected.
- **Case-only rename "fails because the file already exists".** Should be
  handled automatically (two-step rename via a temp name). If you still see
  this, please open an issue with the volume type (`diskutil info /`).
- **`${ruuidv4}` appears literally in the output.** Turn on **Randomize**
  (app) or `--randomize` (CLI).
- **`$YYYY` appears literally.** Pick a **Time source** (creation / modified
  / access) in the Options panel, or pass `--modification-time` (etc.) to
  the CLI.
