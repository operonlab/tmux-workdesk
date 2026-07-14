# tmux-workdesk demo — one prefix key per layout. Walks every layout:
#   prefix + g  -> 2×2 grid       (geometry: rearranges the current window)
#   prefix + e  -> columns        (same panes reflow — e is a README example key)
#   prefix + a  -> left | 3-stack (same panes reflow — a is a README example key)
#   prefix + i  -> IDE layout     (a pure-layout workspace in its own window;
#                                  the slots here are opted into example tools)
# Fully self-contained: docs/demo-setup.sh stages an anonymous sample project,
# a cockpit-style themed ISOLATED tmux server (socket wd-demo) that also binds
# columns->e and l3->a, and harmless tool stand-ins.
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

# t=4.6  prefix + e -> columns, same panes reflow (bezel "⌃B" 4.70, "⌃B E" 5.15)
Ctrl+B
Sleep 500ms
Type "e"
Sleep 2500ms

# t=7.7  prefix + a -> left | 3-stack, same panes (bezel "⌃B" 7.70, "⌃B A" 8.20)
Ctrl+B
Sleep 500ms
Type "a"
Sleep 2500ms

# t=10.7  prefix + i -> the IDE layout window (bezel "⌃B" 10.75, "⌃B I" 11.25)
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
