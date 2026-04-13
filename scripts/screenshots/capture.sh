#!/usr/bin/env bash
# Capture the front MacRename window to Resources/screenshots/<name>.png
# Usage:   ./scripts/screenshots/capture.sh hero
#          ./scripts/screenshots/capture.sh exif-rename
set -euo pipefail

cd "$(dirname "$0")/../.."

if [[ $# -ne 1 ]]; then
  echo "usage: capture.sh <screenshot-name>" >&2
  exit 2
fi

NAME="$1"
OUT="Resources/screenshots/${NAME}.png"
mkdir -p "$(dirname "$OUT")"

# Bring MacRename to the front, then ask Quartz for its window ID
osascript -e 'tell application "MacRename" to activate' >/dev/null
sleep 1.2

# Ask AppKit (via AppleScript / System Events) for the front MacRename
# window's screen-space bounds. Returns "x,y,w,h" — empty if no window.
BOUNDS="$(osascript <<'AS' 2>/dev/null
tell application "System Events"
    tell process "MacRename"
        if (count of windows) is 0 then return ""
        set p to position of window 1
        set s to size of window 1
        return ((item 1 of p) as text) & "," & ((item 2 of p) as text) ¬
            & "," & ((item 1 of s) as text) & "," & ((item 2 of s) as text)
    end tell
end tell
AS
)"

if [[ -z "$BOUNDS" ]]; then
  echo "Could not find a MacRename window. Is the app running and visible?" >&2
  echo "(If you've never granted Accessibility permission, System Settings →" >&2
  echo " Privacy & Security → Accessibility → enable Terminal/iTerm.)" >&2
  exit 1
fi

# -o = no shadow (cleaner App Store shot), -x = silent, -R = region
screencapture -o -x -R "$BOUNDS" "$OUT"
echo "Wrote $OUT  ($(file --brief "$OUT"))  region=$BOUNDS"
