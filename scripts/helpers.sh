#!/usr/bin/env bash
# helpers.sh — shared option helpers for tmux-workdesk.
#
# This file is meant to be sourced, not executed. It intentionally does NOT
# use `set -e`: it is pulled into scripts that tmux calls from a binding via
# `run-shell`, where a non-zero exit is treated as an error by tmux.

# get_tmux_option <option-name> <default-value>
# Read a global tmux user option, falling back to a default when unset/empty.
get_tmux_option() {
	option_name="$1"
	default_value="$2"
	option_value=$(tmux show-option -gqv "$option_name" 2>/dev/null)
	if [ -z "$option_value" ]; then
		printf '%s' "$default_value"
	else
		printf '%s' "$option_value"
	fi
}

# get_slot_cmd <option-name> <default-value>
# Like get_tmux_option, but distinguishes an option that is UNSET (→ default)
# from one explicitly SET TO EMPTY (→ empty string, which the slot builder
# treats as "skip this slot"). `show-option -gqv` returns empty for both cases,
# so we detect an explicit set via `show-options -g` (an unset option prints no
# line; a set-empty one prints `@name ''`).
get_slot_cmd() {
	if tmux show-options -g 2>/dev/null | grep -q "^$1 "; then
		tmux show-option -gqv "$1" 2>/dev/null
	else
		printf '%s' "$2"
	fi
}
