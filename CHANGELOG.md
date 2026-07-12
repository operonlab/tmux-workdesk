# Changelog

All notable changes to tmux-ide are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-12

Initial release.

### Added

- **One-key IDE layout** (`prefix + i` by default): turns the current project
  into a dedicated window — a full-height file tree on the left (yazi), a main
  workspace in the centre, a git panel below it (lazygit), and an AI-assistant
  CLI on the right (claude, or any command). Rebind or disable with `@ide-bind`
  (set to `none` to disable). The default `prefix + i` overrides tmux's built-in
  `display-message` binding.
- **Toggle**: if the IDE window (named `@ide-window-name`, default `ide`) already
  exists in the session, the key just switches to it — it never rebuilds.
- **Swappable, resizable slots**: every slot's program and size is an option.
  `@ide-left-cmd`/`@ide-right-cmd`/`@ide-bottom-cmd`/`@ide-main-cmd` for the
  commands; `@ide-left-width`/`@ide-right-width`/`@ide-bottom-height` for the
  sizes (percentages of the window).
- **Exact proportions independent of split order**: width/height options are
  converted from window percentages to absolute cell counts and passed to
  `split-window -l <cells>`, so the layout matches the spec regardless of the
  order slots are carved, and the floor stays at **tmux 2.4** (no dependency on
  the `-l N%` percentage syntax added in 3.1).
- **Command guard**: if a slot's program is not on `PATH`, that slot opens a
  plain shell instead and a `display-message` says
  `ide: <cmd> not found, slot left as shell`.
- **Skip a slot**: setting a slot's `*-cmd` option to an empty string skips that
  split entirely; the neighbouring pane keeps the space.
- **Space-safe cwd**: the layout root (`@ide-cwd`, default the triggering pane's
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

### Security note

- `@ide-*-cmd` options run commands. They come from your own `~/.tmux.conf`, but
  treat them like any shell command you place in a config file.

### Tested on

- tmux **next-3.8** (macOS, Homebrew HEAD) and the Ubuntu CI runner's tmux.
  Documented floor: **tmux 2.4**.
