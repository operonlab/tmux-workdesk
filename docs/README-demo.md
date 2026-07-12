# Demo recording

`docs/demo.gif` is referenced by the README but not yet committed.

To record it (requires [vhs](https://github.com/charmbracelet/vhs)):

1. `cd` into a sample project (ideally one with yazi, lazygit, and an agent CLI
   installed so every slot shows a real program).
2. Record `prefix + i` (build the IDE layout), pause so the four slots are
   visible, then move focus around and press `prefix + i` again from another
   window to show it switching back (not rebuilding).
3. Export as `docs/demo.gif` and commit.
