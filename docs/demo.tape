# tmux-workdesk demo — one keypress turns the current project into an IDE
# window; pressing it again from anywhere jumps back without rebuilding.
# Fully self-contained: docs/demo-setup.sh stages an anonymous sample project,
# a cockpit-style themed ISOLATED tmux server (socket wd-demo), and a harmless
# AI-slot stand-in.
#
# Re-record from the repo root with:
#   vhs docs/demo.tape && bash docs/demo-overlay.sh
# The overlay pass composites KeyCastr-style key bezels (docs/assets/) onto
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

# t=0.0  cockpit dwell — bezel "⌃B" fades in at 0.90
Sleep 1600ms

# t=1.6  prefix + i -> the IDE window (bezel switches to "⌃B I" at 2.15)
Ctrl+B
Sleep 500ms
Type "i"
Sleep 4400ms

# t=6.5  jump away: prefix + 0 (bezel "⌃B" 5.90, then "⌃B 0" 6.95)
Ctrl+B
Sleep 400ms
Type "0"
Sleep 1400ms

# t=8.4  caption in the plain shell
Type "# press  prefix + i  again from anywhere -> jumps back, never rebuilds"
Sleep 1200ms

# t=12.0  ... and back: the toggle never rebuilds (bezel 11.40 / 12.45)
Ctrl+B
Sleep 400ms
Type "i"
Sleep 2200ms

# hold the money shot: lazygit third | yazi over the agent
Sleep 3500ms

Hide
Ctrl+B
Type "d"
Sleep 500ms
Type "tmux -L wd-demo kill-server"
Enter
Sleep 500ms
