#!/bin/bash
# Post-overlay pass: composite KeyCastr-style key bezels onto the raw vhs
# capture at the tape's deterministic timestamps, then re-palette the GIF.
#
#   vhs docs/demo.tape          -> docs/demo-raw.gif
#   bash docs/demo-overlay.sh   -> docs/demo.gif
#
# Bezels come from docs/keycast-bezel.py (PIL render, docs/assets/bezel-*.png).
# The enable= windows below MUST stay in sync with the Sleeps in demo.tape
# (timeline starts at the tape's Show).
set -u
cd "$(dirname "$0")"

[ -f demo-raw.gif ] || { echo "demo-raw.gif missing — run vhs docs/demo.tape first" >&2; exit 1; }
for b in assets/bezel-cb.png assets/bezel-cbi.png assets/bezel-cb0.png; do
  [ -f "$b" ] || { echo "$b missing — run keycast-bezel.py first" >&2; exit 1; }
done

ffmpeg -y -loglevel error -i demo-raw.gif \
  -i assets/bezel-cb.png -i assets/bezel-cbi.png -i assets/bezel-cb0.png \
  -filter_complex "\
[0:v][1:v]overlay=(W-w)/2:H-h-120:enable='between(t,0.90,2.15)+between(t,5.90,6.95)+between(t,11.40,12.45)'[v1];\
[v1][2:v]overlay=(W-w)/2:H-h-120:enable='between(t,2.15,3.60)+between(t,12.45,13.80)'[v2];\
[v2][3:v]overlay=(W-w)/2:H-h-120:enable='between(t,6.95,8.20)'[v3];\
[v3]split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5[out]" \
  -map '[out]' demo.gif

echo "demo.gif written ($(du -h demo.gif | cut -f1))"
