# tmux-workdesk HERO SCREENSHOT — a single, high-resolution still of the
# four-slot IDE window that `prefix + i` builds: yazi (files) on the left, a
# shell workspace over lazygit (git) in the centre, an AI-agent slot on the
# right. Larger and sharper than docs/demo.gif, frozen at the built layout.
#
# Recorded against an isolated tmux server (socket: shot-workdesk, -f /dev/null),
# never the user's live server. The AI slot is a harmless stand-in — no real
# agent CLI is ever launched. Run from the repo root:  vhs docs/screenshot.tape
Output "/private/tmp/claude-501/-Users-joneshong/aaff1254-ec36-4c2f-98bf-76d62cc8b483/scratchpad/hero-shots/workdesk/_recording.gif"
Require tmux

Set Shell "bash"
Set FontFamily "MesloLGS Nerd Font Mono"
Set FontSize 20
Set Width 1600
Set Height 900
Set Padding 20

# ---- hidden setup: isolated server + slots + plugin, then attach ----
Hide
Type "bash /private/tmp/claude-501/-Users-joneshong/aaff1254-ec36-4c2f-98bf-76d62cc8b483/scratchpad/hero-shots/workdesk/setup.sh"
Enter
Sleep 2s
Type "clear; tmux -L shot-workdesk attach -t demo"
Enter
Sleep 1500ms

# Build the layout while the terminal is VISIBLE so every pane's first paint
# lands on the recording canvas (building under Hide leaves half-painted panes).
Show
Sleep 800ms

# one keypress builds the four-slot IDE window (yazi | shell/lazygit | agent)
Ctrl+B
Sleep 500ms
Type "i"
# let yazi, lazygit and the (self-repainting) agent banner settle
Sleep 6s

# focus lands in the main workspace: open a source file so the centre pane
# reads as "where you work" (distinct from the git panel below it). Painting it
# last keeps it fresh on the recording canvas.
Type "bat --style=numbers,header src/app.py"
Enter
Sleep 2500ms

# ---- the shutter ----
Screenshot docs/screenshot.png
Hide

# ---- teardown: kill only our isolated server ----
Sleep 300ms
Type "tmux -L shot-workdesk kill-server"
Enter
Sleep 500ms
