# tmux-workdesk demo — one prefix key per layout, featuring the new presets.
# Walks: prefix+g (2×2 grid) -> prefix+a (lead: wide lead pane + workers stacked
# right — the go-to layout for driving an agent team) -> prefix+r (rows: full-
# width stacked) -> prefix+i (IDE layout). The geometry layouts reflow the SAME
# panes; a/r are example keys (lead/rows have no default key — bind any preset
# to a key you like). i is the default IDE key.
# Fully self-contained: docs/demo-setup.sh stages an anonymous sample project,
# a cockpit-style themed ISOLATED tmux server (socket wd-demo) that binds
# lead->a and rows->r, and harmless tool stand-ins.
#
# Re-record from the repo root with:
#   vhs docs/demo.tape && bash docs/demo-overlay.sh
# The overlay pass composites the KeyCastr-style key bezels (docs/assets/) onto
# the raw capture at the timestamps below — keep the Sleeps in sync with the
# windows in docs/demo-overlay.sh (timeline starts at Show).
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
Sleep 1600ms

# t=1.6  prefix + g -> 2×2 grid (bezel "⌃B" 1.70, "⌃B G" 2.15)
Ctrl+B
Sleep 500ms
Type "g"
Sleep 2500ms

# t=4.6  prefix + a -> lead (wide left + stacked workers) (bezel "⌃B" 4.70, "⌃B A" 5.15)
Ctrl+B
Sleep 500ms
Type "a"
Sleep 2800ms

# t=7.9  prefix + r -> rows, same panes reflow (bezel "⌃B" 8.05, "⌃B R" 8.50)
Ctrl+B
Sleep 500ms
Type "r"
Sleep 2500ms

# t=11.0  prefix + i -> the IDE layout window (bezel "⌃B" 11.10, "⌃B I" 11.55)
Ctrl+B
Sleep 500ms
Type "i"
Sleep 4500ms

Hide
Ctrl+B
Type "d"
Sleep 500ms
Type "tmux -L wd-demo kill-server"
Enter
Sleep 500ms
