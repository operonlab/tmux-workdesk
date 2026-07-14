# tmux-workdesk demo — one prefix key per layout, featuring the new presets.
# Walks: prefix+g (2×2 grid) -> prefix+a (lead: wide lead pane + workers stacked
# right — the go-to layout for driving an agent team) -> prefix+r (rows: full-
# width stacked) -> prefix+i (IDE layout). The geometry layouts reflow the SAME
# panes; a/r are example keys (lead/rows have no default key). i is the default.
#
# TIMELINE NOTE: each beat holds the PREVIOUS layout static while the KeyCastr
# bezel (⌃B then the chord) is composited on top, and only THEN presses the key
# so the layout changes AFTER the bezel finishes — "show the keys, then act".
# The overlay windows in docs/demo-overlay.sh land inside these static holds.
#
# Fully self-contained: docs/demo-setup.sh stages an anonymous sample project,
# a cockpit-style themed ISOLATED tmux server (socket wd-demo) that binds
# lead->a and rows->r, and harmless tool stand-ins.
#
# Re-record from the repo root with:
#   vhs docs/demo.tape && bash docs/demo-overlay.sh
Output "docs/demo-raw.gif"
Require tmux

Set Shell "bash"
Set FontFamily "Menlo, Symbols Nerd Font Mono"
Set FontSize 18
Set Width 2080
Set Height 1080
Set Padding 20
Set TypingSpeed 35ms

Hide
Type "bash docs/demo-setup.sh"
Enter
Sleep 3s
Type "clear; tmux -L wd-demo attach -t mini"
Enter
Sleep 1500ms
Show

# t=0.0  cockpit dwell
Sleep 1200ms

# --- grid: bezel over the cockpit (1.30 ⌃B, 1.80 ⌃B G), THEN press at ~2.9 ---
Sleep 1500ms
Ctrl+B
Sleep 200ms
Type "g"
Sleep 2000ms

# --- lead: bezel over the grid (4.95 ⌃B, 5.45 ⌃B A), THEN press at ~6.6 ---
Sleep 1500ms
Ctrl+B
Sleep 200ms
Type "a"
Sleep 2000ms

# --- rows: bezel over lead (8.70 ⌃B, 9.20 ⌃B R), THEN press at ~10.4 ---
Sleep 1500ms
Ctrl+B
Sleep 200ms
Type "r"
Sleep 2000ms

# --- IDE: bezel over rows (12.45 ⌃B, 12.95 ⌃B I), THEN press at ~14.1 ---
Sleep 1500ms
Ctrl+B
Sleep 200ms
Type "i"
Sleep 4000ms

Hide
Ctrl+B
Type "d"
Sleep 500ms
Type "tmux -L wd-demo kill-server"
Enter
Sleep 500ms
