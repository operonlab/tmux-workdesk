#!/usr/bin/env bash
# teardown.sh — cleanly remove tmux-workdesk from a running server.
#
# Unbinds the @workdesk-bind key and kills the IDE window (named @workdesk-window-name)
# in every session where it exists. Safe to run more than once.
#
# WARNING: killing the IDE window closes every program running inside it
# (anything you launched in its panes). Save your work first.

set -u

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "${CURRENT_DIR}/helpers.sh"

bind_key=$(get_tmux_option "@workdesk-bind" "i")
win_name=$(get_tmux_option "@workdesk-window-name" "ide")

if [ "$bind_key" != "none" ]; then
	tmux unbind-key -T prefix "$bind_key" 2>/dev/null || true
fi

# Kill every window named "$win_name" across all sessions. The name match is
# done inside the tmux format (#{==:...}, tmux 2.4+) so window names containing
# spaces are compared correctly; matching rows emit a "$session_id:index"
# target (session_id never contains spaces), others emit an empty line.
while IFS= read -r target; do
	[ -z "$target" ] && continue
	tmux kill-window -t "$target" 2>/dev/null || true
done < <(tmux list-windows -a \
	-F "#{?#{==:#{window_name},${win_name}},#{session_id}:#{window_index},}" 2>/dev/null)

tmux display-message "tmux-workdesk removed (binding unbound, '${win_name}' window killed)" 2>/dev/null || true
