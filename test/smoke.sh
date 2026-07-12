#!/usr/bin/env bash
# smoke.sh — headless functional test for tmux-ide on an isolated tmux socket.
#
# Never touches the default tmux server: every command runs under `tmux -L`
# with a private socket that is killed on exit. Scripts are invoked via
# `run-shell`, so the bare `tmux` calls inside them inherit the same private
# socket through $TMUX — no PATH shim needed here.
#
# These tests assert layout structure, not that the tools launched — so every
# scenario pins the slot commands to a plain `sh` (see inert_slots). On a dev
# machine the real defaults (yazi / claude / lazygit) ARE installed, and a
# leaked or slow slot pane becomes a live AI agent that pollutes the host's
# agent observability; smoke runs must never start one.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
IDE="${REPO_DIR}/scripts/ide.sh"

SOCKETS=""
FAILS=0
TMPDIRS=""

cleanup() {
	for s in $SOCKETS; do
		tmux -L "$s" kill-server 2>/dev/null || true
		rm -f "${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)/$s" 2>/dev/null || true
	done
	for d in $TMPDIRS; do
		[ -n "$d" ] && rm -rf "$d" 2>/dev/null || true
	done
}
trap cleanup EXIT INT TERM

# new_sock <letter> — allocate a socket name into $SOCK and register it for
# cleanup. Must be called plainly, never as `$(new_sock …)`: command
# substitution runs the body in a subshell, the SOCKETS registration dies
# there, and cleanup silently becomes a no-op that leaks every test server.
new_sock() {
	SOCK="idetest$$_$1"
	SOCKETS="$SOCKETS $SOCK"
}

# inert_slots <sock> — pin all slot commands to a plain shell so a smoke run
# never launches the real tools (claude would register as a live agent on the
# host). Scenarios that probe a specific slot option override it afterwards.
inert_slots() {
	tmux -L "$1" set-option -g @ide-left-cmd "sh"
	tmux -L "$1" set-option -g @ide-right-cmd "sh"
	tmux -L "$1" set-option -g @ide-bottom-cmd "sh"
}

check() {
	# check <label> <expected> <actual>
	if [ "$2" = "$3" ]; then
		echo "  PASS: $1 (= $3)"
	else
		echo "  FAIL: $1 — expected [$2] got [$3]"
		FAILS=$((FAILS + 1))
	fi
}

panes_of() {
	# panes_of <sock> <window-target> — one pane per line: "left top width height active"
	tmux -L "$1" list-panes -t "$2" -F '#{pane_left} #{pane_top} #{pane_width} #{pane_height} #{pane_active}' 2>/dev/null
}

echo "tmux version: $(tmux -V)"

# ═════════════════ Scenario A: default four slots → 4 panes, exact geometry ═════════════════
echo "── Scenario A: default four-slot layout (200x50 window)"
new_sock A; A=$SOCK
tmux -L "$A" -f /dev/null new-session -d -s work -x 200 -y 50
inert_slots "$A"
tmux -L "$A" run-shell "'${IDE}' toggle"
sleep 0.3
count=$(panes_of "$A" work:ide | grep -c .)
check "pane count (four slots built)" "4" "$count"

geom=$(panes_of "$A" work:ide)
# yazi = the leftmost pane (left == 0): full height, 20% of 200 = 40 wide.
yazi_w=$(printf '%s\n' "$geom" | awk '$1==0{print $3; exit}')
yazi_h=$(printf '%s\n' "$geom" | awk '$1==0{print $4; exit}')
check "yazi left pane width (20% of 200)" "40" "$yazi_w"
check "yazi left pane is full height" "50" "$yazi_h"
# agent = the rightmost pane (max left). 30% of 200 = 60 wide, full height, left=140.
agent_left=$(printf '%s\n' "$geom" | awk '{if($1>m)m=$1}END{print m}')
agent_w=$(printf '%s\n' "$geom" | awk -v m="$agent_left" '$1==m{print $3; exit}')
agent_h=$(printf '%s\n' "$geom" | awk -v m="$agent_left" '$1==m{print $4; exit}')
check "agent right pane left offset" "140" "$agent_left"
check "agent right pane width (30% of 200)" "60" "$agent_w"
check "agent right pane is full height" "50" "$agent_h"
# lazygit = the one pane with top != 0 (the central bottom): 30% of 50 = 15 tall.
bottom_count=$(printf '%s\n' "$geom" | awk '$2!=0{c++}END{print c+0}')
lg_h=$(printf '%s\n' "$geom" | awk '$2!=0{print $4; exit}')
lg_left=$(printf '%s\n' "$geom" | awk '$2!=0{print $1; exit}')
check "exactly one bottom pane (lazygit)" "1" "$bottom_count"
check "lazygit height (30% of 50)" "15" "$lg_h"
check "lazygit sits in the central column (left=41)" "41" "$lg_left"
# focus must land on the main pane: central column, top row (left=41, top=0).
active_left=$(printf '%s\n' "$geom" | awk '$5==1{print $1; exit}')
active_top=$(printf '%s\n' "$geom" | awk '$5==1{print $2; exit}')
check "focus on main pane — left offset" "41" "$active_left"
check "focus on main pane — top row" "0" "$active_top"

# ═════════════════ Scenario B: @ide-right-cmd empty → slot skipped, 3 panes ═════════════════
echo "── Scenario B: empty @ide-right-cmd → agent slot skipped (3 panes)"
new_sock B; B=$SOCK
tmux -L "$B" -f /dev/null new-session -d -s work -x 200 -y 50
inert_slots "$B"
tmux -L "$B" set-option -g @ide-right-cmd ""
tmux -L "$B" run-shell "'${IDE}' toggle"
sleep 0.3
check "pane count with agent slot empty" "3" "$(panes_of "$B" work:ide | grep -c .)"
# with no agent slot the neighbour keeps the space: rightmost edge reaches 199.
right_edge=$(panes_of "$B" work:ide | awk '{e=$1+$3-1; if(e>m)m=e}END{print m}')
check "no agent gap — layout reaches window right edge" "199" "$right_edge"

# ═════════════════ Scenario C: missing program → fallback shell, pane still built ═════════════════
echo "── Scenario C: missing slot program → pane opens as a shell (still 4 panes)"
new_sock C; C=$SOCK
tmux -L "$C" -f /dev/null new-session -d -s work -x 200 -y 50
inert_slots "$C"
tmux -L "$C" set-option -g @ide-left-cmd "nonexistent-cmd-xyz123"
tmux -L "$C" run-shell "'${IDE}' toggle"
sleep 0.3
check "missing-program slot still built (4 panes)" "4" "$(panes_of "$C" work:ide | grep -c .)"
# the leftmost pane must NOT be running the bogus command (guard opened a shell).
left_cmd=$(tmux -L "$C" list-panes -t work:ide -F '#{pane_left} #{pane_current_command}' | awk '$1==0{print $2; exit}')
check "left slot is not the bogus command" "yes" "$([ "$left_cmd" != "nonexistent-cmd-xyz123" ] && echo yes || echo no)"

# ═════════════════ Scenario D: toggle twice → no rebuild, switch back to existing ═════════════════
echo "── Scenario D: second toggle selects the existing window (no rebuild)"
new_sock D; D=$SOCK
tmux -L "$D" -f /dev/null new-session -d -s work -x 200 -y 50
inert_slots "$D"
tmux -L "$D" run-shell "'${IDE}' toggle"
sleep 0.3
first_panes=$(panes_of "$D" work:ide | grep -c .)
# move focus away to a different window so we can prove the 2nd toggle switches back
tmux -L "$D" new-window -d -t work
tmux -L "$D" select-window -t work:0
tmux -L "$D" run-shell "'${IDE}' toggle"
sleep 0.3
ide_win_count=$(tmux -L "$D" list-windows -t work -F '#{window_name}' | grep -cx 'ide')
check "still exactly one 'ide' window (no rebuild)" "1" "$ide_win_count"
check "pane count unchanged after 2nd toggle" "$first_panes" "$(panes_of "$D" work:ide | grep -c .)"
active_win=$(tmux -L "$D" display-message -t work -p '#{window_name}')
check "2nd toggle switched focus back to the ide window" "ide" "$active_win"

# ═════════════════ Scenario E: @ide-cwd with a space is passed through safely ═════════════════
echo "── Scenario E: cwd containing a space is honored for every slot"
new_sock E; E=$SOCK
SPACEBASE="${TMPDIR:-/tmp}/ide smoke $$"
mkdir -p "$SPACEBASE"
# Canonicalize (resolve symlinks like macOS /var → /private/var, drop any
# doubled slash from a trailing-slash TMPDIR) so the comparison matches the
# path tmux reports back via #{pane_current_path}.
SPACEBASE=$(cd "$SPACEBASE" && pwd -P)
TMPDIRS="$TMPDIRS $SPACEBASE"
tmux -L "$E" -f /dev/null new-session -d -s work -x 200 -y 50
inert_slots "$E"
tmux -L "$E" set-option -g @ide-cwd "$SPACEBASE"
tmux -L "$E" run-shell "'${IDE}' toggle"
sleep 0.3
main_path=$(tmux -L "$E" display-message -t work:ide -p '#{pane_current_path}')
check "main pane cwd (with space) is correct" "$SPACEBASE" "$main_path"
# every slot got the same -c: assert the leftmost (yazi) pane too.
yazi_path=$(tmux -L "$E" list-panes -t work:ide -F '#{pane_left}|#{pane_current_path}' | awk -F'|' '$1==0{print $2; exit}')
check "left slot cwd (with space) is correct" "$SPACEBASE" "$yazi_path"

# ═════════════════ Scenario F: entrypoint binds the key, teardown removes it + the window ═════════════════
echo "── Scenario F: ide.tmux installs the bind; teardown.sh unbinds + kills the window"
new_sock F; F=$SOCK
tmux -L "$F" -f /dev/null new-session -d -s work -x 200 -y 50
inert_slots "$F"
tmux -L "$F" run-shell "'${REPO_DIR}/ide.tmux'"
sleep 0.2
bound=$(tmux -L "$F" list-keys -T prefix 2>/dev/null | grep -c 'ide.sh.*toggle')
check "prefix key bound after ide.tmux" "1" "$bound"
# build a window, then tear down
tmux -L "$F" run-shell "'${IDE}' toggle"
sleep 0.3
check "ide window present before teardown" "1" "$(tmux -L "$F" list-windows -t work -F '#{window_name}' | grep -cx 'ide')"
tmux -L "$F" run-shell "'${REPO_DIR}/scripts/teardown.sh'"
sleep 0.2
check "prefix key unbound after teardown" "0" "$(tmux -L "$F" list-keys -T prefix 2>/dev/null | grep -c 'ide.sh.*toggle')"
check "ide window killed after teardown" "0" "$(tmux -L "$F" list-windows -t work -F '#{window_name}' | grep -cx 'ide')"

echo ""
if [ "$FAILS" -eq 0 ]; then
	echo "ALL SMOKE CHECKS PASSED"
	exit 0
else
	echo "SMOKE FAILURES: $FAILS"
	exit 1
fi
