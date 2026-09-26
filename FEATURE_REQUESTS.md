# Pilo bar — feature requests

Longer-form ideas, separate from the review fixes in `REMINDERS.md`. New
requests get appended here.

---

## 1. Hyprland monitors widget — DONE

A widget for arranging monitors and setting refresh rate and scale, without
hand-editing `hyprland.lua`.

Implemented as a new bar icon (monitor glyph, left of the network icon) that
opens a `MonitorsPanel`. Open questions resolved:

- `require()` does resolve a sibling file in the config dir (verified with
  `hyprctl reload` + `hyprctl configerrors`). Monitor setup moved to
  `~/.config/hypr/monitors.lua`, loaded by `hyprland.lua`.
- The widget lives on the bar, not in settings.
- The widget writes `monitors.lua`; fedup should treat it as generated (add it
  to `.gitignore` or accept the churn).

Behaviour: cards ordered left to right, arrow buttons to move a monitor,
refresh/scale segmented controls, a Reset action (preferred/auto/auto). Every
change applies live via `hyprctl keyword monitor` and rewrites `monitors.lua`.
Layout origin is preserved when only refresh/scale changes, so the desktop does
not jump.

### Goal

- Choose where monitors sit relative to each other, **horizontally only**
  (left / right). Vertical placement is out of scope.
- Change each monitor's **refresh rate**.
- Change each monitor's **scale**.
- Make the change apply and persist without touching the rest of the Hyprland
  config.

### Current state (this machine)

Three outputs, all 2560x1440. Left to right: `DP-2`, `HDMI-A-1`, `DP-1`.

`hyprland.lua` lines 11-30:

```lua
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "0x0",      scale = "1"    })
hl.monitor({ output = "DP-1",     mode = "2560x1440@60",  position = "auto-right", scale = "1"  })
hl.monitor({ output = "DP-2",     mode = "2560x1440@60",  position = "auto-left",  scale = "auto" })
```

`~/.config/hypr` is a symlink to `/home/pilo/.config/fedup/dotfiles/hypr`, so
any new file belongs in the fedup dotfiles directory too.

### Config split

Move the monitor block out of `hyprland.lua` into a sibling
`~/.config/hypr/monitors.lua` so the shell can read and rewrite it on its own.

Candidate shape — a Lua table that `hyprland.lua` iterates:

```lua
-- managed by the pilo monitors widget
return {
  { output = "DP-2",     mode = "2560x1440@60",  position = "auto-left",  scale = "auto" },
  { output = "HDMI-A-1", mode = "2560x1440@144", position = "0x0",        scale = "1"    },
  { output = "DP-1",     mode = "2560x1440@60",  position = "auto-right", scale = "1"    },
}
```

and in `hyprland.lua`:

```lua
for _, m in ipairs(require("monitors")) do
    hl.monitor(m)
end
```

Open question: confirm Hyprland's Lua config exposes `require` / `dofile` /
`loadfile` for a sibling file. If it does not, fall back to having the widget
rewrite only a generated block inside a file the config loads.

### Widget behaviour

- One card per connected output, ordered left to right to match the current
  arrangement.
- Card shows output name, resolution, current refresh, current scale.
- **Arrange:** move a monitor left / move right (buttons are enough; drag is a
  nicety). Horizontal only. On apply, rewrite positions, either as
  `auto-left` / `auto-right` or as explicit x offsets.
- **Refresh:** pick from the refresh rates available at the current resolution
  (`availableModes` filtered by resolution), e.g. HDMI-A-1 144 vs 60.
- **Scale:** `auto` plus sane steps (`1`, `1.25`, `1.5`, `1.75`, `2`, ...).
- Disconnected / unknown outputs: show greyed, not editable.
- Stretch goal (not requested): a resolution picker, since `mode` already
  carries it.

### Apply / persist

- Live apply: `hyprctl keyword monitor "<output>,<mode>,<position>,<scale>"`
  per changed output, so it takes effect immediately.
- Persist: write `monitors.lua` (atomic write). No full `hyprctl reload`
  needed if the live keywords are used; the file is for next login.
- "Reset" action: fall back to connected defaults, e.g.
  `hyprctl keyword monitor <name>,preferred,auto,auto`.

### Data sources

- Outputs, current mode / scale / position, and available modes:
  `hyprctl monitors -j` via `Process` (or `HyprlandMonitor.lastIpcObject`).
  `ShellScreen` alone does not carry refresh rate or available modes.
- Apply: `hyprctl keyword monitor ...`.

### Non-goals

- Vertical arrangement.
- Rotation / transform, VRR, bit depth, HDR, colour management.
- Mirroring.
- Per-workspace monitor rules (those stay in `hyprland.lua`).

### Resolved

- `require()` works for a sibling file. `hyprland.lua` now does
  `for _, m in ipairs(require("monitors")) do hl.monitor(m) end`.
- The widget is a new bar icon, not a settings tab.
- The widget writes `monitors.lua` directly; fedup should treat it as
  generated.

---

## 2. Settings app instead of a settings widget

Grow the bar's configuration from a single panel into a real settings window.

### Goal

The gear currently opens one `PanelCard` with a single column of toggles. That
column is already long (chrome, edge, opacity, gap, workspaces, holidays,
launcher sort, file search, power profile) and there is nowhere to put the next
set of options. Replace it with a proper settings **app** — a normal desktop
window, not a bar panel — so the feature set can keep growing.

### Shape

- A standalone window (a `FloatingWindow`, i.e. a regular window the compositor
  tiles/floats), opened from the gear icon (and maybe `qs ipc … settings`).
- A sidebar or tabs for categories, e.g. **Bar**, **Widgets**, **Launcher**,
  **Weather/Calendar**, **System**, **Advanced**. Each category scrolls; search
  filters across all of them.
- Larger layout: two panes (category list + content), room for descriptions,
  previews, and per-item reset.
- Global actions: reset to defaults, export/import the settings file.

### Notes

- The existing `Settings` singleton stays the single source of truth; the app
  is just another editor of it, so the bar updates live.
- Decide whether the gear should still show a small quick panel, open the app
  directly, or open the app at the last-used category.

### Open questions

- Window (tiled/floating) vs a large full-height overlay on the bar's screen?
- One window on the focused monitor, or one per monitor?
- Keep any quick toggles on the bar itself for the most-used options?

---

## 3. Move widgets around the bar from settings

Let the user choose which widgets sit in each bar section and in what order,
instead of the layout being hardcoded.

### Goal

Today the left / centre / right contents are fixed in `Bar.qml`. Make the bar's
building blocks movable: the user picks what goes in **Left**, **Center**, and
**Right**, and drags or nudges them into the order they want. This is a natural
fit for the settings app in #2 (a **Widgets / Layout** category with three
columns).

### Behaviour

- A registry of available bar widgets (launcher button, workspaces, clock,
  running apps, network, bluetooth, sound, power profile, monitors, settings
  gear, spacers, …).
- Three ordered lists (Left, Center, Right) that the user can add to, remove
  from, and reorder.
- Applied live and persisted, like every other setting.
- Sensible defaults matching today's layout, and a "reset layout" action.

### Technical notes

- `Bar.qml` would render each section from a `Repeater`/`ObjectRepeater` over
  the stored lists rather than fixed children. Workspaces and the clock, which
  are currently structural, become registry entries too.
- The hard part is anchoring: panels currently bind their position to specific
  widget ids (e.g. the calendar to the clock, the network panel to the network
  button). With movable widgets the anchor target has to be resolved at open
  time. The running-apps menu already does this by passing the clicked icon's
  x/width into `Panels` — generalise that so every panel receives its anchor
  widget when opened.
- Some widgets are really panel launchers; make sure the panel↔widget link
  survives reordering.

### Open questions

- Drag-and-drop in the settings app, or simple move-left / move-right buttons?
- Per-screen layouts, or one layout for all monitors?
- How to surface widgets that need a minimum width (workspaces, taskbar).
