#!/usr/bin/env bash
# workdesk.tmux — TPM entry point for tmux-workdesk.
#
# TPM sources this file once at tmux start. It reads the user's @workdesk-bind
# option and installs the prefix-table key binding that toggles the IDE window.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "${CURRENT_DIR}/scripts/helpers.sh"

WORKDESK_SCRIPT="${CURRENT_DIR}/scripts/workdesk.sh"

bind_key=$(get_tmux_option "@workdesk-bind" "i")

# Setting the bind option to "none" disables the binding.
if [ "$bind_key" != "none" ]; then
	tmux bind-key -T prefix "$bind_key" run-shell "'${WORKDESK_SCRIPT}' toggle"
fi

# The single bind above is the only side effect; make sure a false test never
# leaks out as exit 1 (which tmux would print as a scary "returned 1").
exit 0
