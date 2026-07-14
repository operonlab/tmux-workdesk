# tmux-workdesk HERO SCREENSHOT — a single, high-resolution still of the IDE
# layout that `prefix + i` builds (here with the slots opted into example
# tools: a git TUI, a file manager, an AI-agent stand-in). One of the plugin's
# layouts; the geometry layouts (grid / columns / left|3-stack) are shown in
# docs/demo.gif.
#
# Fully self-contained: docs/demo-setup.sh stages an anonymous sample project
# and a cockpit-style ISOLATED tmux server (socket wd-demo) — the user's live
# server is never touched. Run from the repo root:  vhs docs/screenshot.tape
Output "docs/screenshot.png"
Require tmux

Set Shell "bash"
Set FontFamily "Menlo, Symbols Nerd Font Mono"
Set FontSize 18
Set Width 2080
Set Height 1080
Set Padding 20

# ---- hidden setup: isolated cockpit server + plugin, then attach ----
Hide
Type "bash docs/demo-setup.sh"
Enter
Sleep 3s
Type "clear; tmux -L wd-demo attach -t mini"
Enter
Sleep 1500ms
Show
Sleep 800ms

# prefix + i builds the IDE layout; let the tools settle, then shoot
Ctrl+B
Sleep 500ms
Type "i"
Sleep 4s

# ---- the shutter ----
Screenshot docs/screenshot.png
Hide

# ---- teardown: kill only our isolated server ----
Sleep 300ms
Type "tmux -L wd-demo kill-server"
Enter
Sleep 500ms
