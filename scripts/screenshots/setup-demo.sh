#!/usr/bin/env bash
# Build a demo directory of realistic fake files for App Store screenshots.
# Output: ~/Pictures/MacRename-Demo/  (re-created each run)
set -euo pipefail

DEMO=~/Pictures/MacRename-Demo
rm -rf "$DEMO"
mkdir -p "$DEMO"/{Holiday,Meeting-notes,Receipts}

# ── Holiday photos: messy, IMG_-prefixed, DSC_ mixed in ──
for i in 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010 0011 0012; do
  cp "$(pwd)/Tests/Fixtures/images/IMG_0001.jpg" "$DEMO/Holiday/IMG_${i}.jpg" 2>/dev/null \
    || /usr/bin/printf '' > "$DEMO/Holiday/IMG_${i}.jpg"
done
for i in 100 101 102 103; do
  /usr/bin/printf '' > "$DEMO/Holiday/DSC_${i}.JPG"
done

# ── Meeting notes: dd.mm.yy dates, mixed extensions, garbage prefixes ──
for date in 14.03.26 21.03.26 28.03.26 04.04.26 11.04.26; do
  /usr/bin/printf '' > "$DEMO/Meeting-notes/garbage Meeting ${date}.pdf"
done
/usr/bin/printf '' > "$DEMO/Meeting-notes/Project Plan v1.docx"
/usr/bin/printf '' > "$DEMO/Meeting-notes/Project Plan v2 FINAL.docx"
/usr/bin/printf '' > "$DEMO/Meeting-notes/Project Plan v2 FINAL ACTUAL.docx"

# ── Receipts: numbered, lower-case extensions ──
for i in 1 2 3 4 5 6 7 8; do
  /usr/bin/printf '' > "$DEMO/Receipts/receipt-${i}.PDF"
done

echo "Demo files written to $DEMO"
echo "Contents:"
ls -la "$DEMO"/*/ | grep -v "^total"
