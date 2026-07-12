#!/usr/bin/env bash
# ide.sh — build (or switch back to) a one-window IDE layout for the current
#          project, on a single keypress.
#
# Usage:  ide.sh toggle
#
# Toggle behavior:
#   * A window named @ide-window-name (default "ide") already exists in the
#     current session  ->  just select-window to it (no rebuild).
#   * It does not exist  ->  build the layout rooted at @ide-cwd (default: the
#     triggering pane's current path).
#
# Layout (default four slots):
#
#   +--------+---------------------+----------+
#   |        |   main  (70% high)  |          |
#   |  yazi  +---------------------+  agent   |
#   | (20% w)|  lazygit (30% high) | (30% w)  |
#   | full h |   central column    |  full h  |
#   +--------+---------------------+----------+
#      20%           ~50%              30%
#
# Each slot's command and size is a @ide-* option (see README). A slot whose
# option is set empty is skipped — the neighbouring pane keeps that space.
#
# Sizing note: the width/height options are percentages OF THE WHOLE WINDOW.
# They are converted to absolute cell counts from #{window_width}/#{window_height}
# and passed to `split-window -l <cells>`. Using absolute cells (not the
# `-l N%` percentage syntax, which is relative to the split pane and only
# arrived in tmux 3.1) makes the proportions exact regardless of split order
# and keeps the floor at tmux 2.4.
#
# Invoked by tmux via `run-shell`, so it must never `set -e`: a non-zero exit
# would be reported by tmux as a binding error.

set -u

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "${CURRENT_DIR}/helpers.sh"

# tmux bindings run this script with the SERVER's environment, whose PATH is
# often minimal (login-shell-managed dirs like ~/.local/bin are absent there).
# Harvest the user's login PATH once so the command guards below see what the
# user sees in a normal terminal.
user_path="$("${SHELL:-/bin/sh}" -lc 'printf %s "$PATH"' 2>/dev/null || true)"
[ -n "$user_path" ] && PATH="$user_path:$PATH"
export PATH

# num_or <value> <default> — strip to digits, fall back to default when empty.
# Guards the arithmetic below against a stray "20%" or a typo in a user option.
num_or() {
	v="${1//[!0-9]/}"
	printf '%s' "${v:-$2}"
}

# resolve_first <command-line> — print the command line with its first token
# replaced by an absolute path, failing when it doesn't resolve. The pane
# command is executed by the tmux server (NOT this script), whose PATH may be
# minimal — an absolute first token works in any environment.
resolve_first() {
	first="${1%% *}"
	rest="${1#"$first"}"
	abs=$(command -v "$first" 2>/dev/null) || return 1
	printf '%s%s' "$abs" "$rest"
}

msg() {
	tmux display-message "$1" 2>/dev/null || true
}

# split_slot <left|right|bottom> <size-cells> <command>
# Carves one slot off the main pane. Empty command = skip (neighbour keeps the
# space). Missing command = open a shell there and say so.
split_slot() {
	dir="$1"
	size="$2"
	cmd="$3"
	[ -z "$cmd" ] && return 0
	[ "${size:-0}" -lt 1 ] && return 0

	flags=()
	case "$dir" in
	left) flags=(-h -b) ;;   # new pane to the LEFT of main
	right) flags=(-h) ;;     # new pane to the RIGHT of main
	bottom) flags=(-v) ;;    # new pane BELOW main
	*) return 0 ;;
	esac

	if rcmd=$(resolve_first "$cmd"); then
		tmux split-window "${flags[@]}" -l "$size" -t "$MAIN" -c "$CWD" -P -F '#{pane_id}' "$rcmd" 2>/dev/null || true
	else
		tmux split-window "${flags[@]}" -l "$size" -t "$MAIN" -c "$CWD" -P -F '#{pane_id}' 2>/dev/null || true
		msg "ide: ${cmd%% *} not found, slot left as shell"
	fi
}

ide_toggle() {
	win_name=$(get_tmux_option "@ide-window-name" "ide")

	# ── already built? just switch to it ──
	target=""
	while IFS= read -r line; do
		[ -z "$line" ] && continue
		idx="${line%% *}"
		name="${line#* }"
		if [ "$name" = "$win_name" ]; then
			target="$idx"
			break
		fi
	done < <(tmux list-windows -F '#{window_index} #{window_name}' 2>/dev/null)

	if [ -n "$target" ]; then
		tmux select-window -t ":$target" 2>/dev/null || true
		return 0
	fi

	# ── resolve the root directory ──
	CWD=$(get_tmux_option "@ide-cwd" "")
	if [ -z "$CWD" ]; then
		CWD=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
	fi
	[ -z "$CWD" ] && CWD="$HOME"

	# ── main pane (the window's first pane), with a command guard ──
	main_cmd=$(get_slot_cmd "@ide-main-cmd" "")
	if [ -n "$main_cmd" ]; then
		if rmain=$(resolve_first "$main_cmd"); then
			main_cmd="$rmain"
		else
			msg "ide: ${main_cmd%% *} not found, slot left as shell"
			main_cmd=""
		fi
	fi
	if [ -n "$main_cmd" ]; then
		MAIN=$(tmux new-window -n "$win_name" -c "$CWD" -P -F '#{pane_id}' "$main_cmd" 2>/dev/null || true)
	else
		MAIN=$(tmux new-window -n "$win_name" -c "$CWD" -P -F '#{pane_id}' 2>/dev/null || true)
	fi
	[ -z "$MAIN" ] && {
		msg "ide: could not create the '$win_name' window"
		return 0
	}

	# Mark the window as plugin-managed. External automation (auto-layout /
	# rebalance hooks) can check this window option and leave our carefully
	# proportioned panes alone.
	tmux set-option -w -t "$MAIN" @ide-window 1 2>/dev/null || true

	# ── converge the fresh window to the attached client BEFORE measuring ──
	# Under `window-size manual` (or before sizing settles) a new window can sit
	# at the 80x24 default; computing slot cells against that ruins every
	# proportion. Nudge it toward the client, then measure what actually stuck.
	cw=$(num_or "$(tmux display-message -t "$MAIN" -p '#{client_width}' 2>/dev/null)" 0)
	ch=$(num_or "$(tmux display-message -t "$MAIN" -p '#{client_height}' 2>/dev/null)" 0)
	if [ "$cw" -ge 20 ] && [ "$ch" -ge 5 ]; then
		tmux resize-window -t "$MAIN" -x "$cw" -y "$ch" 2>/dev/null || true
	fi

	# ── whole-window dimensions → absolute cell sizes for each slot ──
	WW=$(num_or "$(tmux display-message -t "$MAIN" -p '#{window_width}' 2>/dev/null)" 0)
	WH=$(num_or "$(tmux display-message -t "$MAIN" -p '#{window_height}' 2>/dev/null)" 0)
	left_pct=$(num_or "$(get_tmux_option "@ide-left-width" "20")" 20)
	right_pct=$(num_or "$(get_tmux_option "@ide-right-width" "30")" 30)
	bottom_pct=$(num_or "$(get_tmux_option "@ide-bottom-height" "30")" 30)
	left_cells=$((WW * left_pct / 100))
	right_cells=$((WW * right_pct / 100))
	bottom_cells=$((WH * bottom_pct / 100))

	# ── carve the slots off main, in order: left, right, bottom ──
	# get_slot_cmd (not get_tmux_option): an option explicitly set to "" means
	# "skip this slot" and must NOT fall back to the default command.
	split_slot left "$left_cells" "$(get_slot_cmd "@ide-left-cmd" "yazi")" >/dev/null
	RIGHT=$(split_slot right "$right_cells" "$(get_slot_cmd "@ide-right-cmd" "claude")")
	split_slot bottom "$bottom_cells" "$(get_slot_cmd "@ide-bottom-cmd" "lazygit")" >/dev/null

	# ── optional second row in the right column (e.g. a file tree over an agent) ──
	rb_cmd=$(get_slot_cmd "@ide-right-bottom-cmd" "")
	if [ -n "$rb_cmd" ] && [ -n "${RIGHT:-}" ]; then
		rb_pct=$(num_or "$(get_tmux_option "@ide-right-bottom-height" "50")" 50)
		rb_cells=$((WH * rb_pct / 100))
		if [ "$rb_cells" -ge 1 ]; then
			if rb=$(resolve_first "$rb_cmd"); then
				tmux split-window -v -l "$rb_cells" -t "$RIGHT" -c "$CWD" "$rb" 2>/dev/null || true
			else
				tmux split-window -v -l "$rb_cells" -t "$RIGHT" -c "$CWD" 2>/dev/null || true
				msg "ide: ${rb_cmd%% *} not found, slot left as shell"
			fi
		fi
	fi

	# ── land focus in the main workspace ──
	tmux select-pane -t "$MAIN" 2>/dev/null || true
}

case "${1:-toggle}" in
toggle) ide_toggle ;;
*)
	echo "usage: ide.sh {toggle}" >&2
	exit 1
	;;
esac
