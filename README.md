# tmux-workdesk

> 中文說明請見 [docs/zh.md](docs/zh.md)

A **pane-layout switcher** for tmux. Press one key to open a small menu and pick
a layout for your window — a 2×2 grid, even columns, a big-left-plus-stacked-right
split, or an IDE-style four-slot shape. The layouts are the point; you decide
what runs in the panes.

![the tmux-workdesk layout menu — IDE layout, 2×2 grid, Columns, Left | 3-stack](docs/screenshot.png)

*One `prefix + i` opens the chooser; pick a layout and the current window rearranges into it.*

## What is this?

tmux can already cycle its built-in layouts with `prefix + Space`, but those are
generic and unnamed. tmux-workdesk gives you a **named menu of the layouts you
actually reach for**, on one keypress, applied to the current window:

- **IDE layout** — a four-slot shape: a narrow left sidebar, a main workspace,
  a strip beneath it, and a right column. Built as **plain shells by default** —
  point the slots at your own tools if you want (see below). Opens as a dedicated
  `ide` window you can toggle back to.
- **2×2 grid** — four equal panes, tiled.
- **Columns** — N even side-by-side columns (default 4).
- **Left │ 3-stack** — the left half is one full-height pane; the right half is
  split into three stacked panes.

The geometry layouts work on your **current** window: they add plain-shell panes
until the layout has enough, then arrange them. They never kill panes, so you can
switch between layouts freely.

```
   IDE layout            2×2 grid           Columns          Left │ 3-stack
+----+------+----+    +------+------+    +--+--+--+--+     +--------+--------+
|    | main |    |    |      |      |    |  |  |  |  |     |        |   R1   |
|    +------+    |    +------+------+    |  |  |  |  |     |   L    +--------+
|    | strip|    |    |      |      |    |  |  |  |  |     |        |   R2   |
+----+------+----+    +------+------+    +--+--+--+--+     |        +--------+
                                                          |        |   R3   |
                                                          +--------+--------+
```

## The IDE layout — bring your own tools

The IDE layout ships as **four plain shell panes** in that shape. It doesn't
launch any particular program — the *shape* is what the plugin provides. To turn
it into your IDE, point each slot at a tool in `~/.tmux.conf`:

```tmux
# EXAMPLE — a file manager on the left, a git TUI in the strip, an agent on the right.
# These tools are just an illustration; use whatever you like (or nothing).
set -g @workdesk-left-cmd   'yazi'      # a terminal file manager
set -g @workdesk-bottom-cmd 'lazygit'   # a git TUI
set -g @workdesk-right-cmd  'claude'    # an AI-assistant CLI
set -g @workdesk-main-cmd   'nvim'      # your editor in the main pane
```

Each `@workdesk-<slot>-cmd` is optional:

- **unset or empty** → that slot is a plain shell (the layout, no tool),
- **a command** → it runs in that slot (if it isn't installed, the slot falls
  back to a shell and says so),
- **`none`** → the slot is dropped, and its neighbour keeps the space.

> ⚠️ **Slot commands run programs.** They come from your own `~/.tmux.conf`, but
> treat them with the same care as any command you put in a config file.

## Quickstart

New to tmux's `prefix` key? The default prefix is `Ctrl-b` — press `Ctrl-b`,
release it, then press the next key.

You need **tmux 2.4 or newer**. Pick one of the two paths.

### Path A — with TPM (the tmux plugin manager)

If you've never installed TPM, run these three lines first (copy-paste as-is):

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
printf '\n%s\n' "run '~/.tmux/plugins/tpm/tpm'" >> ~/.tmux.conf
tmux source ~/.tmux.conf
```

(If tmux isn't running yet, `tmux source` may print "no server running" —
that's fine, the setting just takes effect next time you start tmux.)

Then add tmux-workdesk. Put this line in your `~/.tmux.conf` **above** the
`run '~/.tmux/plugins/tpm/tpm'` line:

```tmux
set -g @plugin 'operonlab/tmux-workdesk'
```

Reload and install:

```sh
tmux source ~/.tmux.conf   # 1. reload config
# 2. press: prefix + I   (capital i) to fetch the plugin
```

### Path B — without TPM (one line, no plugin manager)

Clone it anywhere, then add one line to `~/.tmux.conf`:

```sh
git clone https://github.com/operonlab/tmux-workdesk ~/.tmux/plugins/tmux-workdesk
printf '%s\n' "run-shell '~/.tmux/plugins/tmux-workdesk/workdesk.tmux'" >> ~/.tmux.conf
tmux source ~/.tmux.conf
```

(If tmux isn't running yet, `tmux source` may print "no server running" —
that's fine, the setting just takes effect next time you start tmux.)

### Try it

1. `cd` into a project and start (or attach to) tmux.
2. Press **`prefix + i`** (lowercase i) → the layout menu opens.
3. Pick a layout by its highlighted key:
   - **`i`** — the IDE layout (a new `ide` window; press `prefix + i` then `i`
     again from anywhere to jump back to it — it is not rebuilt),
   - **`g`** — 2×2 grid, **`c`** — columns, **`l`** — left │ 3-stack (these
     rearrange the current window).

> **Prefer one key straight to the IDE layout?** Set `@workdesk-menu 'off'` and
> `prefix + i` skips the menu and toggles the IDE layout directly (the pre-menu
> behaviour).
>
> **Heads up:** by default `prefix + i` **overrides tmux's built-in binding**
> (a window-information message). Rebind with `@workdesk-bind` if you rely on it.

## Demo

![tmux-workdesk demo — prefix + i opens the layout menu; picking a layout rearranges the window](docs/demo.gif)

## Options

Set any of these in `~/.tmux.conf` **before** the plugin's `run`/`@plugin`
line. All are optional.

| Option | Default | What it does (plain words) |
|---|---|---|
| `@workdesk-bind` | `i` | The key (after your prefix) that opens the layout menu. Set to `none` to disable the binding. **Overrides the built-in `prefix + i`.** |
| `@workdesk-menu` | `on` | `on` = the key opens the layout menu. `off` = the key toggles the IDE layout directly, no menu. |
| `@workdesk-columns-count` | `4` | Number of columns the **Columns** layout produces (clamped 2–8). |
| `@workdesk-window-name` | `ide` | The name of the IDE-layout window. The toggle finds it by this name. |
| `@workdesk-cwd` | *(triggering pane's path)* | The directory the IDE layout is rooted at. Defaults to wherever you pressed the key. |
| `@workdesk-main-cmd` | *(empty → shell)* | Command for the IDE main workspace. Empty leaves a plain shell. |
| `@workdesk-left-cmd` | *(empty → shell)* | Command for the IDE left slot. Empty = plain shell; `none` = drop the slot. |
| `@workdesk-right-cmd` | *(empty → shell)* | Command for the IDE right slot. Empty = plain shell; `none` = drop the slot. |
| `@workdesk-bottom-cmd` | *(empty → shell)* | Command for the IDE centre-bottom slot. Empty = plain shell; `none` = drop the slot. |
| `@workdesk-left-width` | `20` | IDE left slot width, as a **percent of the window**. |
| `@workdesk-right-width` | `30` | IDE right slot width, as a **percent of the window**. |
| `@workdesk-bottom-height` | `30` | IDE strip height, as a **percent of the window**. |
| `@workdesk-right-bottom-cmd` | *(empty)* | Optional second command stacked **under** the IDE right slot. Empty = the right column stays one pane. |
| `@workdesk-right-bottom-height` | `50` | Height of that second right-column pane, as a **percent of the window**. |

Every IDE-layout window this plugin builds carries the window option
`@workdesk-window 1`. If you run your own auto-layout or rebalance hooks, check
that option and skip re-laying-out these windows — their pane proportions are
deliberate.

### More IDE-layout examples

Git panel on the left, files stacked over an agent on the right (the *main*
slot becomes the top-right pane):

```tmux
set -g @workdesk-left-cmd 'lazygit'
set -g @workdesk-left-width '33'
set -g @workdesk-main-cmd 'yazi'
set -g @workdesk-bottom-cmd 'claude'
set -g @workdesk-bottom-height '40'
set -g @workdesk-right-cmd 'none'
```

No AI slot — just files + editor + git:

```tmux
set -g @workdesk-right-cmd 'none'
set -g @workdesk-left-cmd 'yazi'
set -g @workdesk-bottom-cmd 'lazygit'
set -g @workdesk-main-cmd 'nvim'
set -g @plugin 'operonlab/tmux-workdesk'
```

## Uninstall

Run the bundled teardown script to unbind the key and close the IDE window, then
delete the folder:

```sh
~/.tmux/plugins/tmux-workdesk/scripts/teardown.sh
rm -rf ~/.tmux/plugins/tmux-workdesk
```

> ⚠️ Teardown **kills the `ide` window**, which closes everything running inside
> it. Save your work first.

(If you installed via TPM, also remove the `set -g @plugin '.../tmux-workdesk'` line
from `~/.tmux.conf`.)

## Troubleshooting / FAQ

**I pressed `prefix + i` and it just showed a window-info message.**
That's tmux's built-in `prefix + i` — the plugin's binding isn't loaded yet.
Reload your config (`tmux source ~/.tmux.conf`), and if you use TPM, install with
`prefix + I` (capital i). Once tmux-workdesk is loaded, `prefix + i` opens the menu.

**A grid/columns/left-stack layout added empty shell panes.**
That's by design — the geometry layouts add plain-shell panes until the layout
has enough, then arrange them. Run whatever you like in the new panes.

**An IDE slot opened as a plain shell instead of the program I expected.**
That slot's command isn't on your `PATH` in the environment tmux launched from.
tmux-workdesk checks the first word of each `*-cmd` and, if it can't find it, opens
a shell there and prints `workdesk: <cmd> not found, slot left as shell`. Install
the tool, or point the option at the right binary.

**I want fewer IDE panes.**
Set that slot's command to `none` (e.g. `set -g @workdesk-right-cmd 'none'`).
The split is skipped and the neighbouring pane keeps the space.

**Pressing the IDE key again opened yet another window — or did nothing.**
It should never build a second one: the toggle looks for a window named
`@workdesk-window-name` (default `ide`) and just switches to it if present. If you
renamed the IDE window by hand, tmux-workdesk can no longer find it and will build
a fresh one — change `@workdesk-window-name` to match, or don't rename it.

**The proportions look slightly off by a cell or two.**
tmux spends one cell on each pane border, so a 20% / ~50% / 30% split of a
200-column window lands at 40 / 98 / 60 columns (the two missing columns are the
borders). That's expected.

**Do the layouts survive a tmux server restart?**
The windows and panes live in the running server like any other, so a
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) setup can bring
them back — but tmux-workdesk itself keeps no state on disk. After a plain restart,
just press `prefix + i` and pick the layout again.

## Roadmap

- **yazi → main pane**: if you point the IDE left slot at yazi, you can open the
  file yazi highlights directly into the main workspace. The recipe (yazi opener
  config + a `tmux send-keys` bridge) is written up in
  [docs/yazi-integration.md](docs/yazi-integration.md); it is **not bundled**.

## Why not `tmux-ide`?

This plugin was briefly named `tmux-ide` during development, but that name is
already taken by several unrelated projects — most notably
[guysoft/tmux-ide](https://github.com/guysoft/tmux-ide), plus
[wavyrai/tmux-ide](https://github.com/wavyrai/tmux-ide) and
[sandeeprenjith/TMUX-IDE](https://github.com/sandeeprenjith/TMUX-IDE). Rather
than pile onto a crowded name, this project renamed to **tmux-workdesk** before
its first release. It is not affiliated with any of the projects above.

It is also a different kind of tool: guysoft/tmux-ide is a fixed
`nvim + opencode` IDE with an nvim RPC socket for agent-driven debugging;
tmux-workdesk is a **layout switcher** — the IDE shape is one of several layouts,
it launches no tools of its own, and its options live under `@workdesk-*` (versus
guysoft's `@ide-*`), so enabling both won't cross wires.

## Credits / License

Part of a small family of single-purpose tmux plugins. Released under the
[MIT License](LICENSE).
