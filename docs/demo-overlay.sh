#!/bin/bash
# Post-overlay pass: composite KeyCastr-style key bezels onto the raw vhs
# capture at the tape's deterministic timestamps, then re-palette the GIF.
#
#   vhs docs/demo.tape          -> docs/demo-raw.gif
#   bash docs/demo-overlay.sh   -> docs/demo.gif
#
# Bezels come from docs/keycast-bezel.py (PIL render, docs/assets/bezel-*.png).
# The demo presses prefix+g / +a / +r / +i in turn. Each beat holds the PREVIOUS
# layout static, shows "⌃B" then the chord ("⌃B G" etc.) ON TOP of it, and the
# chord window ENDS ~0.15s before the layout actually changes — so the bezel is
# fully read BEFORE the reflow ("show the keys, then act").
#
# The windows below are EMPIRICALLY tuned to demo-raw.gif's real timeline, which
# vhs compresses ~5% vs the nominal Sleep arithmetic (17.28s wall for ~18.1s of
# Sleeps). Measured layout-change moments (via ffmpeg scene detect + eyes-on
# frame audit): grid ~2.80, lead ~6.30, rows ~9.84, IDE ~13.40. If you re-time
# the tape, re-measure and re-tune these — do NOT trust the nominal Sleep sums.
set -u
cd "$(dirname "$0")"

[ -f demo-raw.gif ] || { echo "demo-raw.gif missing — run vhs docs/demo.tape first" >&2; exit 1; }
for b in assets/bezel-cb.png assets/bezel-cbg.png assets/bezel-cba.png assets/bezel-cbr.png assets/bezel-cbi.png; do
  [ -f "$b" ] || { echo "$b missing — run keycast-bezel.py first" >&2; exit 1; }
done

ffmpeg -y -loglevel error -i demo-raw.gif \
  -i assets/bezel-cb.png -i assets/bezel-cbg.png -i assets/bezel-cba.png \
  -i assets/bezel-cbr.png -i assets/bezel-cbi.png \
  -filter_complex "\
[0:v][1:v]overlay=(W-w)/2:H-h-120:enable='between(t,1.15,1.65)+between(t,4.65,5.15)+between(t,8.15,8.65)+between(t,11.75,12.25)'[v1];\
[v1][2:v]overlay=(W-w)/2:H-h-120:enable='between(t,1.65,2.65)'[v2];\
[v2][3:v]overlay=(W-w)/2:H-h-120:enable='between(t,5.15,6.15)'[v3];\
[v3][4:v]overlay=(W-w)/2:H-h-120:enable='between(t,8.65,9.65)'[v4];\
[v4][5:v]overlay=(W-w)/2:H-h-120:enable='between(t,12.25,13.25)'[v5];\
[v5]split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5[out]" \
  -map '[out]' demo.gif

echo "demo.gif written ($(du -h demo.gif | cut -f1))"
