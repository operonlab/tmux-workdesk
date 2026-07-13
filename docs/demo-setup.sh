#!/bin/bash
# demo-setup.sh — self-contained stage for docs/demo.tape. Builds everything
# the recording needs and starts an ISOLATED tmux server (socket: wd-demo,
# own config) — your real tmux server and config are never touched.
# Anonymous by construction: staged sample project, identity-free prompts,
# no hostname in the status line, and the AI slot is a harmless stand-in.
set -u
SOCK=wd-demo
WORK=/tmp/vhs-workdesk-demo
APP=/tmp/demo-app
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMUX_BIN="${TMUX_BIN:-tmux}"

mkdir -p "$WORK"

# ── clean, anonymous shell for every pane ──
cat > "$WORK/rc.sh" <<'RC'
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export LANG=en_US.UTF-8
_git_seg() { b=$(git branch --show-current 2>/dev/null) && [ -n "$b" ] && printf '  %s' "$b"; }
PS1='\[\e[38;2;166;227;161m\] dev \[\e[38;2;137;180;250m\]\W\[\e[38;2;249;226;175m\]$(_git_seg)\[\e[0m\] ❯ '
PROMPT_COMMAND=
RC

# ── harmless AI-slot stand-in (no real agent CLI is ever launched) ──
cat > "$WORK/agent-slot.sh" <<'AGENT'
#!/bin/bash
printf '\n\n   \033[38;2;203;166;247m✦  AI assistant\033[0m\n\n\n   (your AI agent CLI here)\n\n\n   \033[2mclaude · codex · gemini …\033[0m\n'
exec -a agent sleep 3600
AGENT
chmod +x "$WORK/agent-slot.sh"

# demo yazi config: defaults (hidden files off) regardless of the recording
# user's real yazi settings
mkdir -p "$WORK/yazi-config"

# ── staged sample project (real git history for yazi + lazygit) ──
rm -rf "$APP"; mkdir -p "$APP/src" "$APP/tests"
printf '# demo-app\n\nA tiny sample project.\n' > "$APP/README.md"
printf '__pycache__/\n*.pyc\n' > "$APP/.gitignore"
printf 'flask\npytest\n' > "$APP/requirements.txt"
cat > "$APP/src/app.py" <<'PY'
"""demo-app entry point."""
from config import load_settings


def main() -> None:
    settings = load_settings()
    print(f"starting demo-app on port {settings['port']}")


if __name__ == "__main__":
    main()
PY
printf 'def test_placeholder():\n    assert True\n' > "$APP/tests/test_app.py"
git -C "$APP" init -q -b main
git -C "$APP" -c user.name=dev -c user.email=dev@example.com add -A
git -C "$APP" -c user.name=dev -c user.email=dev@example.com commit -qm "initial commit"
printf '\n- work in progress\n' >> "$APP/README.md"

# ── cockpit-style theme (catppuccin mocha, hardcoded, portable) ──
cat > "$WORK/theme.conf" <<'CONF'
set -g default-terminal "tmux-256color"
set -as terminal-overrides ",xterm-256color:Tc"
set -g mouse on
setw -g mode-keys vi
setw -g automatic-rename off
set -g escape-time 0
set -g status 2
set -g status-interval 2
set -g status-style "bg=#1E1E1E,fg=#cdd6f4"
set -g status-left '#[fg=#a6e3a1,bg=#1E1E1E]#[fg=#11111b,bg=#a6e3a1]  #[fg=#cdd6f4,bg=#313244] #S #[fg=#313244,bg=#1E1E1E] '
set -g status-left-length 30
set -g status-right '#[fg=#f5c2e7,bg=#1E1E1E]#[fg=#11111b,bg=#f5c2e7]  #[fg=#cdd6f4,bg=#313244] #W #[fg=#89dceb,bg=#313244]#[fg=#11111b,bg=#89dceb]  #[fg=#cdd6f4,bg=#313244] %H:%M #[fg=#313244,bg=#1E1E1E]'
set -g status-right-length 120
set -g 'status-format[1]' '#[align=left]#(cat /tmp/vhs-demo-row2-left 2>/dev/null)#[align=right]#(cat /tmp/vhs-demo-row2-right 2>/dev/null)'
set -g window-status-format '#[fg=#6c7086] #I:#W '
set -g window-status-current-format '#[fg=#89b4fa,bold] #I:#W '
set -g window-status-separator ''
set -g pane-border-status top
set -g pane-border-format '#[align=centre]#{?pane_active,#[reverse],}#{pane_index}#[default] #{?#{==:#{pane_current_command},sleep},agent,#{pane_current_command}}'
set -g pane-border-style 'fg=#45475a'
set -g pane-active-border-style 'fg=#fab387,bold'
set -g message-style 'bg=#f9e2af,fg=#11111b,bold'
CONF

# ── ambient row-2 pills (static demo values, honest set dressing) ──
pill() { printf '#[fg=%s,bg=#1E1E1E]\xee\x82\xb6#[fg=#11111b,bg=%s]%s #[fg=#cdd6f4,bg=#313244] %s #[fg=#313244,bg=#1E1E1E]\xee\x82\xb4 ' "$1" "$1" "$2" "$3"; }
{ pill '#f5c2e7' '' 'AI 5H 40%'; pill '#89b4fa' '' 'CX 5H 65%'; } > /tmp/vhs-demo-row2-left
{ pill '#a6e3a1' '' 'CPU 34%'; pill '#f9e2af' '' 'MEM 16.7/24G'; pill '#94e2d5' '' '↓17K ↑30K'; } > /tmp/vhs-demo-row2-right

# ── isolated server: window 0 runs the clean shell EXPLICITLY (a session's
#    first window is created before default-command applies — classic leak) ──
"$TMUX_BIN" -L "$SOCK" kill-server 2>/dev/null
sleep 0.3
"$TMUX_BIN" -L "$SOCK" -f "$WORK/theme.conf" new-session -d -s demo -x 118 -y 30 -n shell -c "$APP" "bash --rcfile $WORK/rc.sh -i"
"$TMUX_BIN" -L "$SOCK" set -g default-command "bash --rcfile $WORK/rc.sh -i"
"$TMUX_BIN" -L "$SOCK" setenv -g YAZI_CONFIG_HOME "$WORK/yazi-config"

# ── workdesk slots (defaults, with the AI slot pointed at the stand-in) ──
"$TMUX_BIN" -L "$SOCK" set -g @workdesk-cwd "$APP"
"$TMUX_BIN" -L "$SOCK" set -g @workdesk-right-cmd "$WORK/agent-slot.sh"
"$TMUX_BIN" -L "$SOCK" run-shell "$PLUGIN/workdesk.tmux"
