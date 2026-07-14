# tmux-workdesk HERO SCREENSHOT — a single, high-resolution still of the layout
# menu that `prefix + i` opens (IDE layout · 2×2 grid · Columns · Left | 3-stack).
# Larger and sharper than a demo.gif frame, frozen with the menu open.
#
# Fully self-contained: docs/demo-setup.sh stages an anonymous sample project and
# a cockpit-style ISOLATED tmux server (socket wd-demo) — the user's live server
# is never touched. Run from the repo root:  vhs docs/screenshot.tape
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
Sleep 1200ms

# prefix + i opens the layout menu; hold it open for the shutter
Ctrl+B
Sleep 500ms
Type "i"
Sleep 1500ms

# ---- the shutter ----
Screenshot docs/screenshot.png
Hide

# ---- teardown: kill only our isolated server ----
Sleep 300ms
Type "tmux -L wd-demo kill-server"
Enter
Sleep 500ms
