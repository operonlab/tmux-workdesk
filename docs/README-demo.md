# Demo recording

`docs/demo.gif` shows `prefix + i` opening the layout menu and picking a
layout — the IDE layout is one of the choices, built as plain shells; picking
it again from another window jumps straight back without rebuilding.

It's produced by an automated, self-contained pipeline (requires
[vhs](https://github.com/charmbracelet/vhs)) instead of a manual recording:

1. `docs/demo-setup.sh` stages an anonymous sample project and starts an
   isolated, cockpit-themed tmux server (socket `wd-demo`) — your real tmux
   server and config are never touched.
2. `vhs docs/demo.tape` records the session against that server.
3. `bash docs/demo-overlay.sh` composites KeyCastr-style key-bezel overlays
   onto the raw capture and writes the final `docs/demo.gif`.

Re-record from the repo root with:

```sh
vhs docs/demo.tape && bash docs/demo-overlay.sh
```
