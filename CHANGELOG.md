# Changelog

All notable changes to tmux-workdesk are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

- The name `tmux-workdesk` is shared with several unrelated projects, most notably
  [guysoft/tmux-workdesk](https://github.com/guysoft/tmux-workdesk) (also a one-key IDE
  layout: editor + AI agent + terminal, rooted at the current pane's cwd,
  tmux-resurrect compatible, `@workdesk-*` options). Keeping the name is a deliberate
  choice, not an oversight: installs are namespaced (`operonlab/tmux-workdesk`),
  so there is no install-time ambiguity. See the README's "Relation to other
  `tmux-workdesk` plugins" section for how this plugin differs (four slots with a
  dedicated file manager and git panel; editor-agnostic; no nvim/RPC coupling;
  tmux 2.4 floor).

### Security note

- `@workdesk-*-cmd` options run commands. They come from your own `~/.tmux.conf`, but
  treat them like any shell command you place in a config file.

### Tested on

- tmux **next-3.8** (macOS, Homebrew HEAD) and the Ubuntu CI runner's tmux.
  Documented floor: **tmux 2.4**.
