#!/usr/bin/env bash
# workdesk.tmux — TPM entry point for tmux-workdesk.
#
# TPM sources this file once at tmux start. It installs one prefix-table key
# binding per layout — each key runs a layout directly (no menu), so the plugin
# stays pure `bind-key … run-shell` and works on tmux 2.4+ (the display-menu
# chooser needs 3.0+, so it is opt-in only, see @workdesk-menu-bind below).
#
# Every binding is a @workdesk-<layout>-bind option; set any to "none" to skip
# it. Defaults bind only the two keys that don't clobber a core tmux binding
# (i, g); columns and l3 default to "none" because their mnemonic keys (c, l)
# are tmux's own new-window / last-window — bind them to a free key you like.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "${CURRENT_DIR}/scripts/helpers.sh"

WORKDESK_SCRIPT="${CURRENT_DIR}/scripts/workdesk.sh"

# bind_layout <key> <layout> — bind one prefix key to run a layout, unless the
# key is "none".
bind_layout() {
	[ "$1" = "none" ] && return 0
	tmux bind-key -T prefix "$1" run-shell "'${WORKDESK_SCRIPT}' $2"
}

bind_layout "$(get_tmux_option "@workdesk-ide-bind" "i")"        ide
bind_layout "$(get_tmux_option "@workdesk-grid-bind" "g")"       grid
bind_layout "$(get_tmux_option "@workdesk-columns-bind" "none")" columns
bind_layout "$(get_tmux_option "@workdesk-rows-bind" "none")"    rows
bind_layout "$(get_tmux_option "@workdesk-l3-bind" "none")"      l3
bind_layout "$(get_tmux_option "@workdesk-lead-bind" "none")"    lead
bind_layout "$(get_tmux_option "@workdesk-mainh-bind" "none")"   mainh
bind_layout "$(get_tmux_option "@workdesk-duo-bind" "none")"     duo
bind_layout "$(get_tmux_option "@workdesk-fleet-bind" "none")"   fleet
bind_layout "$(get_tmux_option "@workdesk-focus-bind" "none")"   focus

# Optional one-key cycle that steps the current window through the layout ring
# (@workdesk-cycle-ring, default grid -> columns -> rows -> grid). Off by
# default; bind it to a free key if you prefer "next layout" to per-layout keys.
bind_layout "$(get_tmux_option "@workdesk-cycle-bind" "none")"   cycle

# Opt-in chooser (needs tmux 3.0+ for display-menu). Off by default so the
# plugin's default path stays on the tmux 2.4 floor. Set @workdesk-menu-bind to
# a key to bind a single menu of every layout.
bind_layout "$(get_tmux_option "@workdesk-menu-bind" "none")"  menu

# The binds above are the only side effects; make sure a false test never
# leaks out as exit 1 (which tmux would print as a scary "returned 1").
exit 0
