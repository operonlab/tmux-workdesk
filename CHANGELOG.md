# Changelog

All notable changes to tmux-workdesk are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **One prefix key per layout** — plain `bind-key -T prefix … run-shell`,
  no menu involved, works on tmux 2.4+. New per-layout bind options:
  `@workdesk-ide-bind` (default `i`), `@workdesk-grid-bind` (default `g`),
  `@workdesk-columns-bind` (default `none`), `@workdesk-l3-bind` (default
  `none`). Set any to `none` to skip that binding. Only `i`/`g` are bound
  by default — `c`/`l` are tmux's own new-window/last-window mnemonics, so
  columns/l3 are opt-in to whatever free key you like.
- **Geometry layouts** for the *current* window: **2×2 grid**, **Columns**
  (count via new option `@workdesk-columns-count`, default `4`, clamped
  2–8), and **Left │ 3-stack** (left half full-height, right half split
  into three stacked panes). These add plain-shell panes until the layout
  has enough, then apply a native tmux layout — panes are only ever added,
  never killed, so the same panes reflow in place and switching between
  layouts is seamless.
- **Cycle** (`@workdesk-cycle-bind`, default `none`): steps the current
  window through a ring of layouts on one key, for "next layout" instead
  of a separate key per layout. The ring is configurable via
  `@workdesk-cycle-ring` (default `grid columns rows`).
- **Menu** (`@workdesk-menu-bind`, default `none`): opt-in `display-menu`
  popup listing every layout. Needs tmux 3.0+ — off by default so the
  plugin's core path stays on the tmux 2.4 floor.
- **Geometry layouts consolidated onto two parameterized primitives**:
  `tile X Y` (an X-by-Y tile of panes; `auto` on either axis adaptive-tiles
  over the current panes) and `main {v|h} <pct> [n]` (one pane at `<pct>`%
  of the window — `v` = left column, `h` = top row — the rest stacked
  beside/below; `n` forces the pane count). Both are bindable directly
  (`workdesk.sh tile 3 1`, `workdesk.sh main v 70`) for shapes the named
  presets don't cover. `tile X Y` is exact for N×1, 1×N, and 2×2; a forced
  non-square N×M falls back to tmux's own `tiled` arrangement.
- **Five new named presets** on top of the primitives: **rows** (`tile 1 N`,
  count via new option `@workdesk-rows-count`, default 3, clamped 2–8),
  **fleet** (`tile auto auto`, adaptive tiled grid — "watch many"), **lead**
  (`main v 50`, a 50%-wide lead pane + stacked workers — the dominant-agent
  layout), **mainh** (`main h 60`, a 60%-tall main pane over a terminal
  strip), and **duo** (`tile 2 1`, two equal panes side by side). Matching
  bind options: `@workdesk-rows-bind`, `@workdesk-fleet-bind`,
  `@workdesk-lead-bind`, `@workdesk-mainh-bind`, `@workdesk-duo-bind`
  (all default `none`).
- **Focus** (`@workdesk-focus-bind`, default `none`): zooms the active pane
  (press again to restore) — the "watch many, focus one" complement to the
  geometry layouts.

### Changed

- **BREAKING: `@workdesk-bind` and `@workdesk-menu` are gone.** Replaced by
  the per-layout `@workdesk-<layout>-bind` options above — there is no
  single option that toggles menu-vs-direct behaviour anymore, because
  there is no menu-by-default behaviour to toggle.
- **BREAKING: the IDE layout no longer launches yazi/lazygit/claude by
  default.** All four slots ship as plain shells; tools are opt-in via
  `@workdesk-<slot>-cmd` (`@workdesk-left-cmd`, `@workdesk-main-cmd`,
  `@workdesk-bottom-cmd`, `@workdesk-right-cmd`). The plugin ships the
  *shape*, not a toolset.
- **BREAKING: empty slot-command semantics flipped.** An unset or empty
  `@workdesk-<slot>-cmd` now means "plain shell" (previously it meant
  "skip this slot"). To skip a slot, set its command to `none`.

## [0.3.0] - 2026-07-13

### Changed

- **Project renamed: `tmux-ide` → `tmux-workdesk`.** An existing plugin
  (guysoft/tmux-ide) already occupies the name with a near-identical concept;
  renaming pre-release avoids permanent search confusion. Everything moves
  with the name: entry point `workdesk.tmux`, main script
  `scripts/workdesk.sh`, the whole option namespace `@ide-*` → `@workdesk-*`
  (including the `@workdesk-window` marker), and status messages now prefixed
  `workdesk:`. The default window name stays `ide` — it describes the layout,
  not the plugin.

## [0.2.1] - 2026-07-12

### Fixed

- **Toggle heals a degenerate IDE window.** If the named window still exists
  but has collapsed to a single pane (layout panes closed, or a build died
  half-way), toggling used to just switch to it — looking broken forever. Now
  a lone *idle shell* is recycled and the layout rebuilt; a lone *busy* pane
  is left untouched with a message explaining how to rebuild.

## [0.2.0] - 2026-07-12

### Added

- **Right-column split** (`@workdesk-right-bottom-cmd` / `@workdesk-right-bottom-height`):
  stack a second command under the right slot — e.g. a file tree above an
  agent CLI.
- **`@workdesk-window 1` window marker** on every window the plugin builds, so
  external auto-layout/rebalance automation can recognise and skip them.
  (Found live: a user rebalance hook running `select-layout -E` flattened the
  plugin's 60/40 stack seconds after the build.)

### Fixed

- **Proportions under `window-size manual`**: a fresh window can sit at the
  80x24 default when created; the plugin now converges it to the attached
  client's size *before* computing slot cells, instead of carving percentages
  out of 80x24.

## [0.1.1] - 2026-07-12

### Fixed

- **Slot commands now survive a minimal tmux server PATH.** Pane commands are
  executed by the tmux server, whose PATH often lacks login-shell dirs like
  `~/.local/bin` — a slot command living there (e.g. `claude`) passed the
  script's own guard but died instantly in the pane. The script now harvests
  the user's login-shell PATH once and hands `split-window` an absolute first
  token, so the guard and the pane agree on what exists. (Found live on the
  first real-desktop demo; the isolated test env masked it.)

## [0.1.0] - 2026-07-12

Initial release.

### Added

- **One-key IDE layout** (`prefix + i` by default): turns the current project
  into a dedicated window — a full-height file tree on the left (yazi), a main
  workspace in the centre, a git panel below it (lazygit), and an AI-assistant
  CLI on the right (claude, or any command). Rebind or disable with `@workdesk-bind`
  (set to `none` to disable). The default `prefix + i` overrides tmux's built-in
  `display-message` binding.
- **Toggle**: if the IDE window (named `@workdesk-window-name`, default `ide`) already
  exists in the session, the key just switches to it — it never rebuilds.
- **Swappable, resizable slots**: every slot's program and size is an option.
  `@workdesk-left-cmd`/`@workdesk-right-cmd`/`@workdesk-bottom-cmd`/`@workdesk-main-cmd` for the
  commands; `@workdesk-left-width`/`@workdesk-right-width`/`@workdesk-bottom-height` for the
  sizes (percentages of the window).
- **Exact proportions independent of split order**: width/height options are
  converted from window percentages to absolute cell counts and passed to
  `split-window -l <cells>`, so the layout matches the spec regardless of the
  order slots are carved, and the floor stays at **tmux 2.4** (no dependency on
  the `-l N%` percentage syntax added in 3.1).
- **Command guard**: if a slot's program is not on `PATH`, that slot opens a
  plain shell instead and a `display-message` says
  `workdesk: <cmd> not found, slot left as shell`.
- **Skip a slot**: setting a slot's `*-cmd` option to an empty string skips that
  split entirely; the neighbouring pane keeps the space.
- **Space-safe cwd**: the layout root (`@workdesk-cwd`, default the triggering pane's
  path) is passed through `split-window -c` with correct quoting, so project
  directories containing spaces work.
- `scripts/teardown.sh` for clean removal (unbind the key + kill the `ide`
  window in every session).
- Headless smoke test suite (`test/smoke.sh`) running on an isolated tmux socket,
  asserting the four-pane geometry (pane `left`/`top`/`width`/`height`), the
  empty-slot and missing-program fallbacks, the no-rebuild toggle, and the
  space-in-cwd path.
- `docs/yazi-integration.md` — recipe for opening the file yazi selects into the
  main pane (roadmap; not bundled in v0.1).

### Naming

- 0.1.0 shipped as `tmux-ide`, sharing that name with several unrelated
  projects (most notably [guysoft/tmux-ide](https://github.com/guysoft/tmux-ide),
  also a one-key IDE layout). The keep-the-name-and-disambiguate stance recorded
  here was **superseded by the 0.3.0 rename to `tmux-workdesk`** — see the
  README's "Why not `tmux-ide`?" section for how this plugin differs (four slots
  with a dedicated file manager and git panel; editor-agnostic; no nvim/RPC
  coupling; tmux 2.4 floor).

### Security note

- `@workdesk-*-cmd` options run commands. They come from your own `~/.tmux.conf`, but
  treat them like any shell command you place in a config file.

### Tested on

- tmux **next-3.8** (macOS, Homebrew HEAD) at 0.1.0; **tmux 3.7b** (macOS,
  Homebrew stable) from 0.2.x on, plus the Ubuntu CI runner's tmux.
  Documented floor: **tmux 2.4**.
