#!/usr/bin/env bash
# workdesk.tmux — TPM entry point for tmux-workdesk.
#
# TPM sources this file once at tmux start. It reads the user's @workdesk-bind
# option and installs the prefix-table key binding that opens the layout menu
# (IDE scaffold + pane-level geometry presets).

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "${CURRENT_DIR}/scripts/helpers.sh"

WORKDESK_SCRIPT="${CURRENT_DIR}/scripts/workdesk.sh"

bind_key=$(get_tmux_option "@workdesk-bind" "i")

# The prefix binding opens the layout chooser. Setting @workdesk-bind to "none"
# disables it. @workdesk-menu can be set to "off" to bind the IDE toggle
# directly (the pre-menu behaviour) instead of opening the chooser.
menu_mode=$(get_tmux_option "@workdesk-menu" "on")
if [ "$bind_key" != "none" ]; then
	if [ "$menu_mode" = "off" ]; then
		tmux bind-key -T prefix "$bind_key" run-shell "'${WORKDESK_SCRIPT}' ide"
	else
		tmux bind-key -T prefix "$bind_key" run-shell "'${WORKDESK_SCRIPT}' menu"
	fi
fi

# The single bind above is the only side effect; make sure a false test never
# leaks out as exit 1 (which tmux would print as a scary "returned 1").
exit 0
