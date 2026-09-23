#!/bin/sh
# Capture the page's app screenshots from the phone's debug-only ShowcaseActivity.
# The showcase renders the real app UI on an in-memory database filled with invented sample
# content, so no personal Todos, Thoughts or account details can appear. It needs a connected
# Android device running a Debug build of the app that includes ShowcaseActivity.
#
#   sh scripts/capture-screens.sh          # English and Chinese
#   sh scripts/capture-screens.sh zh       # one language
#   ADB=/path/to/adb WIDTH=720 SCREENS="home_todo recording" sh scripts/capture-screens.sh
#
# Output: site/assets/img/screens/<lang>/<screen>.jpg, status bar cropped. Review every image
# before committing it.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out="$root/site/assets/img/screens"
ADB=${ADB:-$(command -v adb || echo "$HOME/Library/Android/sdk/platform-tools/adb")}
WIDTH=${WIDTH:-720}
QUALITY=${QUALITY:-80}
component=com.kk.knockboost/.ShowcaseActivity
screens=${SCREENS:-"home_todo home_thoughts thought_read thought_sources thought_edit todo_edit collections recording"}
langs=${*:-en zh}
raw=$(mktemp -d)
trap 'rm -rf "$raw"' EXIT INT TERM

"$ADB" get-state >/dev/null

size=$("$ADB" shell wm size | sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' | tail -n 1)
w=${size% *}
h=${size#* }
bar=$("$ADB" shell dumpsys window | sed -n 's/.*type=statusBars frame=\[0,0\]\[[0-9]*,\([0-9]*\)\].*/\1/p' | head -n 1)
bar=${bar:-0}

# Every tap and capture requires the showcase to own input focus. Taps stay in the middle of the
# screen, away from where notification banners appear.
require_focus() {
    "$ADB" shell dumpsys window | grep -q "mCurrentFocus=.*ShowcaseActivity" || {
        echo "ShowcaseActivity does not have focus; stopped at $1" >&2
        exit 1
    }
}

# Raw `screencap` RGBA -> top-down 24-bit BMP without the status bar rows. (sips crop offsets are
# unreliable, so only resizing and JPEG encoding are left to sips.)
crop_status_bar() {
    python3 - "$1" "$2" "$3" <<'PY'
import struct, sys

data = open(sys.argv[1], "rb").read()
width, height, pixel_format = struct.unpack_from("<III", data)
start = len(data) - width * height * 4  # the header is 12 or 16 bytes depending on Android version
if pixel_format != 1 or start not in (12, 16):
    sys.exit(f"unexpected screencap format {pixel_format} with a {start}-byte header")
top = int(sys.argv[2])
rows = height - top
rgba = data[start + top * width * 4:]
bgr = bytearray(width * rows * 3)
bgr[0::3], bgr[1::3], bgr[2::3] = rgba[2::4], rgba[1::4], rgba[0::4]
stride = (width * 3 + 3) & ~3
if stride != width * 3:
    pad = bytes(stride - width * 3)
    bgr = b"".join(bytes(bgr[i:i + width * 3]) + pad for i in range(0, len(bgr), width * 3))
header = b"BM" + struct.pack("<IHHI", 54 + len(bgr), 0, 0, 54)
info = struct.pack("<IiiHHIIiiII", 40, width, -rows, 1, 24, 0, len(bgr), 2835, 2835, 0, 0)
with open(sys.argv[3], "wb") as out:
    out.write(header + info + bgr)
PY
}

open_screen() {
    "$ADB" logcat -c
    "$ADB" shell am start -W -n "$component" --activity-clear-task --es lang "$1" --es screen "$2" >/dev/null
    tries=0
    until "$ADB" logcat -d -s KKShowcase:I | grep -q "event=ready screen=$2 lang=$1"; do
        tries=$((tries + 1))
        [ "$tries" -lt 40 ] || { echo "ShowcaseActivity did not start ($1 $2)" >&2; exit 1; }
        sleep 0.25
    done
    sleep 1.5
    require_focus "$1 $2"
}

for lang in $langs; do
    mkdir -p "$out/$lang"
    for screen in $screens; do
        case "$screen" in
            thought_sources)
                open_screen "$lang" thought_read
                "$ADB" shell input swipe $((w / 2)) $((h * 80 / 100)) $((w / 2)) $((h * 30 / 100)) 350
                "$ADB" shell input swipe $((w / 2)) $((h * 80 / 100)) $((w / 2)) $((h * 30 / 100)) 350
                sleep 1.2
                ;;
            thought_edit)
                open_screen "$lang" thought_edit
                # Tapping the document body switches the reading view into edit mode.
                "$ADB" shell input tap $((w / 2)) $((h * 56 / 100))
                sleep 1.5
                if "$ADB" shell dumpsys input_method | grep -q "mInputShown=true"; then
                    "$ADB" shell input keyevent KEYCODE_BACK
                    sleep 1
                fi
                ;;
            *)
                open_screen "$lang" "$screen"
                ;;
        esac
        require_focus "$lang $screen"
        "$ADB" exec-out screencap > "$raw/$screen.raw"
        require_focus "$lang $screen"
        crop_status_bar "$raw/$screen.raw" "$bar" "$raw/$screen.bmp"
        sips --resampleWidth "$WIDTH" -s format jpeg -s formatOptions "$QUALITY" \
            "$raw/$screen.bmp" --out "$out/$lang/$screen.jpg" >/dev/null
        echo "saved $lang/$screen.jpg"
    done
done
"$ADB" shell input keyevent KEYCODE_HOME
