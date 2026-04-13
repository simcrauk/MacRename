# App Store screenshot workflow

Goal: produce 5–6 PNGs in `Resources/screenshots/` ready to upload to App
Store Connect.

## One-time setup

```bash
./scripts/screenshots/setup-demo.sh   # builds ~/Pictures/MacRename-Demo
open ~/Applications/MacRename.app     # or ⌘R in Xcode
open ~/Pictures/MacRename-Demo        # so you can drag folders in
```

Resize the MacRename window to a presentable size — recommend ~1100×750.
Apple accepts up to 2880×1800; bigger is fine, but the window doesn't need
to fill the frame.

## Capture loop

For each scenario below: set up the app to match the description, then run
`capture.sh <name>` from this repo. The script brings MacRename to the
front, finds its window via Quartz, and writes a PNG with no shadow.

### Scenarios

| # | Name | Setup |
|---|------|-------|
| 1 | `hero` | Drag the **Holiday** folder in. Search `IMG_`, Replace `Photo_`. Preview shows pending renames. |
| 2 | `regex-date` | Drag the **Meeting-notes** folder in. Toggle **Regex**. Search `^.*?(\d{2})\.(\d{2})\.(\d{2})`, Replace `20$3$2$1`. Shows a powerful one-shot transformation. |
| 3 | `exif` | Drag the **Holiday** folder in (or Tests/Fixtures/images for real EXIF). Toggle **Regex**, **Name only**, and turn on **EXIF** in the Options panel. Search `.+`, Replace `$CAMERA_MAKE-$DATE_TAKEN_YYYY$DATE_TAKEN_MM$DATE_TAKEN_DD-ISO$ISO`. Demonstrates metadata tokens. |
| 4 | `options` | Drag any folder in. Expand the **Options** panel. Light up several toggles so the panel is visually busy. |
| 5 | `enumerate` | Drag the **Receipts** folder in. Turn on **Enumerate**. Search `.+`, Replace `receipt-${start=1,padding=3}`, Regex on. Shows token expansion in action. |
| 6 | `help` | Open Help ▸ MacRename Help (⌘?). Click the **Tokens** sidebar item. |

```bash
./scripts/screenshots/capture.sh hero
./scripts/screenshots/capture.sh regex-date
./scripts/screenshots/capture.sh exif
./scripts/screenshots/capture.sh options
./scripts/screenshots/capture.sh enumerate
./scripts/screenshots/capture.sh help
```

## After

Open `Resources/screenshots/` in Finder. If any look wrong, redo just that
one with the same `capture.sh <name>` command — it'll overwrite. Upload
the PNGs to App Store Connect when you submit.

Tip: between captures, click **Clear** in MacRename to reset, then drag the
next folder. Don't quit the app — the security-scoped grants are
session-bound, so each launch would re-prompt for parent folder access.
