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

win_name=$(get_tmux_option "@workdesk-window-name" "ide")

# Unbind every per-layout key (same defaults as workdesk.tmux). A key set to
# "none" was never bound, so skip it.
for opt_default in \
	"@workdesk-ide-bind:i" \
	"@workdesk-grid-bind:g" \
	"@workdesk-columns-bind:none" \
	"@workdesk-rows-bind:none" \
	"@workdesk-l3-bind:none" \
	"@workdesk-lead-bind:none" \
	"@workdesk-mainh-bind:none" \
	"@workdesk-duo-bind:none" \
	"@workdesk-fleet-bind:none" \
	"@workdesk-focus-bind:none" \
	"@workdesk-cycle-bind:none" \
	"@workdesk-menu-bind:none"; do
	key=$(get_tmux_option "${opt_default%%:*}" "${opt_default##*:}")
	[ "$key" = "none" ] && continue
	tmux unbind-key -T prefix "$key" 2>/dev/null || true
done

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
