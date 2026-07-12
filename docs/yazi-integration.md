# Opening yazi's selection into the main pane

**Status: roadmap — not bundled in v0.1.**

Out of the box, tmux-ide runs [yazi](https://github.com/sxyazi/yazi) in the left
slot as a normal file manager: pressing Enter opens the highlighted file with
yazi's own opener (usually `$EDITOR` *inside the yazi pane*). What most people
actually want from an IDE layout is different: highlight a file on the left, and
have it open in the **main workspace pane** in the centre.

yazi can't move focus across tmux panes by itself, but it can run a shell
command — and that command can be `tmux send-keys` aimed at the main pane. This
page is the recipe. It's documentation-only for now; a future tmux-ide version
may wire the pane target up automatically (see "The missing piece" below).

## The idea

```
  yazi pane                          main pane
  ┌──────────┐   Enter on a file     ┌───────────────────────┐
  │ > app.py │ ────────────────────► │ $ nvim app.py         │
  │   lib/   │   tmux send-keys      │  (opens in the centre) │
  └──────────┘                       └───────────────────────┘
```

## Step 1 — give the main pane a stable target

tmux can't address a pane by a friendly name, so tag the main pane with a title
you can search for. After the layout is built, run this once (focus is already
on the main pane):

```sh
tmux select-pane -T ide-main
```

Now a small resolver finds it from anywhere in the `ide` window:

```sh
# resolve-main.sh — print the pane_id whose title is "ide-main"
tmux list-panes -t ide -F '#{pane_id} #{pane_title}' \
  | awk '$2=="ide-main"{print $1; exit}'
```

## Step 2 — a yazi keymap that sends to it

yazi's `shell` command runs a command with the hovered file as `$0` (and every
selected file as `$@`). Bind Enter (or a new key) to send an editor command to
the main pane instead of opening it locally.

`~/.config/yazi/keymap.toml`:

```toml
[[manager.prepend_keymap]]
on   = "<Enter>"
desc = "Open the hovered file in the tmux-ide main pane"
run  = '''
  shell 'main=$(tmux list-panes -t ide -F "#{pane_id} #{pane_title}" | awk "\$2==\"ide-main\"{print \$1; exit}"); [ -n "$main" ] && tmux send-keys -t "$main" "${EDITOR:-nvim} \"$0\"" Enter' --confirm
'''
```

- `--confirm` runs the command without pausing for a keypress.
- `$0` is the file yazi is hovering; the surrounding quotes keep paths with
  spaces intact.
- If the main pane can't be found (you're not in an `ide` window), the command
  does nothing rather than typing into the wrong place.

Keep yazi's default Enter behavior on a second key if you sometimes want the
local opener:

```toml
[[manager.prepend_keymap]]
on   = "o"
run  = "open"
```

## The missing piece (why this isn't built in yet)

The resolver above depends on the `ide-main` pane title, which you have to set by
hand today. A clean built-in version would instead **pass the main pane id into
the yazi slot's environment** at build time, e.g.:

```sh
# what a future ide.sh could do when it splits the left slot:
tmux split-window -h -b -l "$yazi_cells" -t "$MAIN" \
     -e "IDE_MAIN_PANE=$MAIN" -c "$CWD" yazi
```

Then the keymap simplifies to:

```toml
run = 'shell ''tmux send-keys -t "$IDE_MAIN_PANE" "${EDITOR:-nvim} \"$0\"" Enter'' --confirm'
```

(`split-window -e` needs tmux 3.0+.) Wiring this — with an option to opt in and a
choice of "type a command" vs. "just cd there" — is the planned follow-up. Until
then, the title-based recipe above works on any tmux ≥ 2.4.
