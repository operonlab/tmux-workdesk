#!/usr/bin/env bash
# ide.tmux — TPM entry point for tmux-ide.
#
# TPM sources this file once at tmux start. It reads the user's @ide-bind
# option and installs the prefix-table key binding that toggles the IDE window.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "${CURRENT_DIR}/scripts/helpers.sh"

IDE_SCRIPT="${CURRENT_DIR}/scripts/ide.sh"

bind_key=$(get_tmux_option "@ide-bind" "i")

# Setting the bind option to "none" disables the binding.
if [ "$bind_key" != "none" ]; then
	tmux bind-key -T prefix "$bind_key" run-shell "'${IDE_SCRIPT}' toggle"
fi

# The single bind above is the only side effect; make sure a false test never
# leaks out as exit 1 (which tmux would print as a scary "returned 1").
exit 0
