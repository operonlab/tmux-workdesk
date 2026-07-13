# tmux-workdesk demo — turn the current project into an IDE-style tmux window
# (files | shell/git | agent) with a single keypress, then toggle back and forth.
#
# Recorded against an isolated tmux server (socket: vhsdemo-workdesk,
# -f /dev/null), never the user's live server. The AI slot is a harmless
# stand-in — no real agent CLI is ever launched.
Output docs/demo.gif
Require tmux

Set Shell "bash"
Set Width 1200
Set Height 700
Set FontSize 14
Set Padding 12
Set TypingSpeed 55ms

# ---- hidden setup: isolated server + slot options + plugin load ----
Hide
Type "bash /private/tmp/claude-501/-Users-joneshong/aaff1254-ec36-4c2f-98bf-76d62cc8b483/scratchpad/vhs-visual/setup-workdesk.sh"
Enter
Sleep 1s
Type "clear; tmux -L vhsdemo-workdesk attach -t demo"
Enter
Sleep 1500ms
Show

# ---- visible demo ----
Sleep 1500ms

# one keypress builds the four-slot IDE window (yazi · shell/lazygit · agent)
Ctrl+B
Sleep 500ms
Type "i"
Sleep 6s

# leave the IDE window...
Ctrl+B
Sleep 400ms
Type "0"
Sleep 1800ms

# ...press the same key again and it jumps straight back — never rebuilds
Ctrl+B
Sleep 500ms
Type "i"
Sleep 3s

# ---- hidden teardown ----
Hide
Type "tmux -L vhsdemo-workdesk kill-server"
Enter
Sleep 500ms
