# tmux-workdesk demo — one keypress turns the current project into a four-slot
# IDE window; pressing it again from anywhere jumps back without rebuilding.
# Fully self-contained: docs/demo-setup.sh stages an anonymous sample project,
# a cockpit-style themed ISOLATED tmux server (socket wd-demo), and a harmless
# AI-slot stand-in. Re-record from the repo root with:  vhs docs/demo.tape
Output "docs/demo.gif"
Require tmux

Set Shell "bash"
Set FontFamily "MesloLGS Nerd Font Mono"
Set FontSize 20
Set Width 1600
Set Height 900
Set Padding 20
Set TypingSpeed 35ms

Hide
Type "bash docs/demo-setup.sh"
Enter
Sleep 3s
Type "clear; tmux -L wd-demo attach -t demo"
Enter
Sleep 1500ms
Show

# the cockpit: double status row + clean prompt, sitting in a project dir
Sleep 1200ms

# one keypress -> the four-slot IDE window
Ctrl+B
Sleep 400ms
Type "i"
Sleep 5500ms

# jump away ... and back: the toggle never rebuilds
Ctrl+B
Sleep 300ms
Type "0"
Sleep 800ms
Type "# press  prefix + i  again from anywhere -> jumps back, never rebuilds"
Sleep 1600ms
Ctrl+B
Sleep 300ms
Type "i"
Sleep 2200ms

# settle in the main workspace and hold the money shot
Type "bat --style=numbers,header src/app.py"
Enter
Sleep 4s

Hide
Ctrl+B
Type "d"
Sleep 500ms
Type "tmux -L wd-demo kill-server"
Enter
Sleep 500ms
