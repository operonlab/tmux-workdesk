#!/usr/bin/env bash
# workdesk.sh — build (or switch back to) a one-window IDE layout for the current
#          project, on a single keypress.
#
# Usage:  workdesk.sh toggle
#
# Toggle behavior:
#   * A window named @workdesk-window-name (default "ide") already exists in the
#     current session  ->  just select-window to it (no rebuild).
#   * It does not exist  ->  build the layout rooted at @workdesk-cwd (default: the
#     triggering pane's current path).
#
# Layout — the "ide" shape (four slots). Every slot is a PLAIN SHELL by default:
# the plugin ships the SHAPE, not any particular tool.
#
#   +--------+---------------------+----------+
#   |        |   main  (70% high)  |          |
#   |  left  +---------------------+  right   |
#   | (20% w)|  bottom (30% high)  | (30% w)  |
#   | full h |   central column    |  full h  |
#   +--------+---------------------+----------+
#      20%           ~50%              30%
#
# Each slot's size is a @workdesk-* option (see README). Point a slot at a tool
# with @workdesk-<slot>-cmd — e.g. a file manager on the left, a git TUI in the
# bottom, an agent CLI on the right. Those are EXAMPLES, not defaults. Set a
# slot's -cmd to "none" to drop it (the neighbour keeps that space).
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
# Carves one slot off the main pane. The command is OPTIONAL — the LAYOUT is the
# point, not the tool:
#   ""      -> a plain shell pane (the default: build the shape, launch nothing)
#   "none"  -> skip this slot (the neighbour keeps the space)
#   <cmd>   -> run it (falling back to a shell + a notice if it isn't installed)
split_slot() {
	dir="$1"
	size="$2"
	cmd="$3"
	[ "$cmd" = "none" ] && return 0
	[ "${size:-0}" -lt 1 ] && return 0

	flags=()
	case "$dir" in
	left) flags=(-h -b) ;;   # new pane to the LEFT of main
	right) flags=(-h) ;;     # new pane to the RIGHT of main
	bottom) flags=(-v) ;;    # new pane BELOW main
	*) return 0 ;;
	esac

	if [ -z "$cmd" ]; then
		tmux split-window "${flags[@]}" -l "$size" -t "$MAIN" -c "$CWD" -P -F '#{pane_id}' 2>/dev/null || true
	elif rcmd=$(resolve_first "$cmd"); then
		tmux split-window "${flags[@]}" -l "$size" -t "$MAIN" -c "$CWD" -P -F '#{pane_id}' "$rcmd" 2>/dev/null || true
	else
		tmux split-window "${flags[@]}" -l "$size" -t "$MAIN" -c "$CWD" -P -F '#{pane_id}' 2>/dev/null || true
		msg "workdesk: ${cmd%% *} not found, slot left as shell"
	fi
}

workdesk_toggle() {
	win_name=$(get_tmux_option "@workdesk-window-name" "ide")

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
		# A window with our name but a single pane is a remnant (the layout
		# panes were closed, or an earlier build died half-way). Selecting it
		# forever would make the toggle look broken — heal instead: recycle a
		# lone idle shell and rebuild; leave a lone BUSY pane alone and say why.
		npanes=$(tmux display-message -p -t ":$target" '#{window_panes}' 2>/dev/null)
		if [ "${npanes:-2}" -ge 2 ]; then
			tmux select-window -t ":$target" 2>/dev/null || true
			return 0
		fi
		lone_cmd=$(tmux list-panes -t ":$target" -F '#{pane_current_command}' 2>/dev/null | head -1)
		case "$lone_cmd" in
		zsh | bash | sh | -zsh | -bash | fish)
			tmux kill-window -t ":$target" 2>/dev/null || true
			# fall through to a fresh build below
			;;
		*)
			tmux select-window -t ":$target" 2>/dev/null || true
			msg "workdesk: window '$win_name' has a single busy pane ($lone_cmd) — close or empty it, then toggle again to rebuild"
			return 0
			;;
		esac
	fi

	# ── resolve the root directory ──
	CWD=$(get_tmux_option "@workdesk-cwd" "")
	if [ -z "$CWD" ]; then
		CWD=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
	fi
	[ -z "$CWD" ] && CWD="$HOME"

	# ── main pane (the window's first pane), with a command guard ──
	main_cmd=$(get_slot_cmd "@workdesk-main-cmd" "")
	if [ -n "$main_cmd" ]; then
		if rmain=$(resolve_first "$main_cmd"); then
			main_cmd="$rmain"
		else
			msg "workdesk: ${main_cmd%% *} not found, slot left as shell"
			main_cmd=""
		fi
	fi
	if [ -n "$main_cmd" ]; then
		MAIN=$(tmux new-window -n "$win_name" -c "$CWD" -P -F '#{pane_id}' "$main_cmd" 2>/dev/null || true)
	else
		MAIN=$(tmux new-window -n "$win_name" -c "$CWD" -P -F '#{pane_id}' 2>/dev/null || true)
	fi
	[ -z "$MAIN" ] && {
		msg "workdesk: could not create the '$win_name' window"
		return 0
	}

	# Mark the window as plugin-managed. External automation (auto-layout /
	# rebalance hooks) can check this window option and leave our carefully
	# proportioned panes alone.
	tmux set-option -w -t "$MAIN" @workdesk-window 1 2>/dev/null || true

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
	left_pct=$(num_or "$(get_tmux_option "@workdesk-left-width" "20")" 20)
	right_pct=$(num_or "$(get_tmux_option "@workdesk-right-width" "30")" 30)
	bottom_pct=$(num_or "$(get_tmux_option "@workdesk-bottom-height" "30")" 30)
	left_cells=$((WW * left_pct / 100))
	right_cells=$((WW * right_pct / 100))
	bottom_cells=$((WH * bottom_pct / 100))

	# ── carve the slots off main, in order: left, right, bottom ──
	# get_slot_cmd (not get_tmux_option): an option explicitly set to "" means
	# "skip this slot" and must NOT fall back to the default command.
	# Slots default to plain shells — the plugin ships the SHAPE, not a toolset.
	# Point a slot at a tool with @workdesk-<slot>-cmd; "none" drops the slot.
	split_slot left "$left_cells" "$(get_slot_cmd "@workdesk-left-cmd" "")" >/dev/null
	RIGHT=$(split_slot right "$right_cells" "$(get_slot_cmd "@workdesk-right-cmd" "")")
	split_slot bottom "$bottom_cells" "$(get_slot_cmd "@workdesk-bottom-cmd" "")" >/dev/null

	# ── optional second row in the right column (e.g. a file tree over an agent) ──
	rb_cmd=$(get_slot_cmd "@workdesk-right-bottom-cmd" "")
	if [ -n "$rb_cmd" ] && [ -n "${RIGHT:-}" ]; then
		rb_pct=$(num_or "$(get_tmux_option "@workdesk-right-bottom-height" "50")" 50)
		rb_cells=$((WH * rb_pct / 100))
		if [ "$rb_cells" -ge 1 ]; then
			if rb=$(resolve_first "$rb_cmd"); then
				tmux split-window -v -l "$rb_cells" -t "$RIGHT" -c "$CWD" "$rb" 2>/dev/null || true
			else
				tmux split-window -v -l "$rb_cells" -t "$RIGHT" -c "$CWD" 2>/dev/null || true
				msg "workdesk: ${rb_cmd%% *} not found, slot left as shell"
			fi
		fi
	fi

	# ── land focus in the main workspace ──
	tmux select-pane -t "$MAIN" 2>/dev/null || true
}

# ─────────────────────────── geometry presets ───────────────────────────
# Pure pane-level layouts for the CURRENT window: reach a target pane count by
# splitting empty shells off the current panes, then apply a native tmux
# layout. Non-destructive — panes are only ever ADDED, never killed, so a
# preset can be re-applied or switched to freely.

# ensure_panes <n> — add empty shells (inheriting the pane's cwd) until the
# current window holds at least <n> panes. Re-tile between splits so there is
# always room for the next one; the caller applies the final layout afterwards.
ensure_panes() {
	target="$1"
	guard=0
	while :; do
		n=$(tmux list-panes 2>/dev/null | wc -l | tr -d ' ')
		[ "${n:-0}" -ge "$target" ] && break
		guard=$((guard + 1))
		[ "$guard" -gt 16 ] && break
		tmux split-window -d -c '#{pane_current_path}' >/dev/null 2>&1 || break
		tmux select-layout tiled >/dev/null 2>&1 || true
	done
}

# columns_count — read @workdesk-columns-count, clamp to 2-8, default 4.
columns_count() {
	raw=$(get_tmux_option "@workdesk-columns-count" "4")
	n="${raw//[!0-9]/}"
	n="${n:-4}"
	n=$((10#$n))
	[ "$n" -lt 2 ] && n=2
	[ "$n" -gt 8 ] && n=8
	printf '%s' "$n"
}

focus_first() {
	first=$(tmux list-panes -F '#{pane_id}' 2>/dev/null | head -1)
	[ -n "$first" ] && tmux select-pane -t "$first" 2>/dev/null || true
}

# grid — 2x2 tiled square (4 panes).
layout_grid() {
	ensure_panes 4
	tmux select-layout tiled >/dev/null 2>&1 || true
	focus_first
}

# columns — N side-by-side columns (@workdesk-columns-count, default 4).
layout_columns() {
	n=$(columns_count)
	ensure_panes "$n"
	tmux select-layout even-horizontal >/dev/null 2>&1 || true
	focus_first
}

# l3 — left half (50% width, full height) + right half split into 3 stacked
# panes (~33% each). main-vertical with main-pane-width pinned to half the
# window is exactly this shape; the right column auto-divides among the rest.
layout_l3() {
	ensure_panes 4
	WW=$(num_or "$(tmux display-message -p '#{window_width}' 2>/dev/null)" 0)
	if [ "$WW" -ge 4 ]; then
		tmux set-window-option main-pane-width "$((WW / 2))" 2>/dev/null || true
	fi
	tmux select-layout main-vertical >/dev/null 2>&1 || true
	focus_first
}

# menu — the layout chooser (also installed as the prefix binding).
layout_menu() {
	self="${CURRENT_DIR}/workdesk.sh"
	tmux display-menu -T '#[align=centre]#[fg=#fab387] workdesk ' -x C -y C \
		'IDE layout'      i "run-shell \"'${self}' ide\"" \
		'' \
		'2×2 grid'        g "run-shell \"'${self}' grid\"" \
		'Columns'         c "run-shell \"'${self}' columns\"" \
		'Left │ 3-stack'  l "run-shell \"'${self}' l3\"" \
		'' \
		'Cancel'          q '' 2>/dev/null || true
}

case "${1:-menu}" in
toggle | ide) workdesk_toggle ;;
grid) layout_grid ;;
columns | cols) layout_columns ;;
l3) layout_l3 ;;
menu) layout_menu ;;
*)
	echo "usage: workdesk.sh {menu|ide|grid|columns|l3}" >&2
	exit 1
	;;
esac
