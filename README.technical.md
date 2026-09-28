# Pilo bar — technical README

Companion to `README.md` (the user guide). This is for working on the bar.
`DESIGN.md` is the original design document; this file is the day-to-day
technical map and the place to record implementation gotchas.

## Running it

- Config name: `pilo`, at `~/.config/quickshell/pilo/`.
- Start: `qs -c pilo` (a normal run). During development, run it in a terminal
  and watch the output; it hot-reloads on save, so most edits need no restart.
- Restart cleanly when a change is not picked up:
  `pkill -x qs` will also kill other Quickshell instances, so kill the pilo PID
  specifically (`pgrep -ax qs` then `kill <pid>`), then `qs -c pilo`.
- Logs: each run prints a path under `/run/user/$(id -u)/quickshell/by-id/<id>/log.qslog`.
  It is a binary-ish log; `strings <file> | rg -i "error|warn"` works.
- IPC: `qs -c pilo ipc call pilo toggle <launcher|calendar|network|sound|settings|monitors>`,
  `qs -c pilo ipc call pilo close`. `toggle settings` opens the standalone
  settings window (not a bar panel); `monitors` (or `displays`) opens it on the
  Displays page; `close` closes both the panels and the settings window.

## Requirements

- Hyprland 0.56+ with the Lua config (`hyprland.lua`).
- Quickshell 0.3.1.
- FiraCode Nerd Font (bar text and glyphs).
- NetworkManager, BlueZ, PipeWire (`wpctl`), `powerprofilesctl`, `plocate`
  (file search). None of these are hard requirements for the bar to start; the
  matching feature degrades if one is missing.

## File layout

```
pilo/
  shell.qml            ShellRoot: one Bar per screen, IPC, audio node tracker
  Bar.qml              per-screen PanelWindow, sections, and the overlays
  Theme.qml            colours, font, sizes, motion, glyphs        (singleton)
  Settings.qml         persisted settings                         (singleton)
  Panels.qml           which panel is open, on which screen        (singleton)
  Power.qml            power profile via powerprofilesctl          (singleton)
  Holidays.qml         holiday dates per region                   (singleton)
  RunningApps.qml      running-window model + focus/close/kill     (singleton)
  BarWidgets.qml       available bar widget registry + default layout (singleton)
  SettingsApp.qml      settings window open/category/search state  (singleton)
  Displays.qml         monitor model + arrange/refresh/scale/identify (singleton)
  SettingsWindow.qml   standalone settings window (FloatingWindow)
  widgets/             bar buttons and small controls
    BarButton, LauncherButton, NetworkButton,
    SoundButton, SettingsButton, Taskbar, Workspaces, Clock, BarSpacer,
    PanelCard, Segmented, Slider, Toggle, ActionButton,
    SettingRow, IconButton, TextField
  panels/              panel contents (no windows of their own)
    AppLauncher, CalendarPanel, NetworkPanel, SoundPanel, WindowsMenu
  settings/            settings window categories
    BarCategory, DisplaysCategory, WidgetsCategory, LauncherCategory,
    CalendarCategory, SystemCategory, AdvancedCategory, SettingsSearch,
    CategoryHeading
  DESIGN.md            original design document
  README.md            user-facing overview
  CHANGELOG.md         implemented changes and added features
  REMINDERS.md         review fixes
  FEATURE_REQUESTS.md  active (not-yet-implemented) feature ideas
```

Singletons use `pragma Singleton` and are imported with `qs`. Cross-directory
imports are `qs`, `qs.widgets`, `qs.panels`. The neighbouring-file implicit
import covers same-directory types.

## Window / overlay model

Everything is a layer-shell `PanelWindow`; there are no xdg-popups and no
focus-grab objects. Per screen, `Bar.qml` creates:

1. **The bar** — namespace `pilo-bar`, layer Top, `exclusiveZone` = bar height
   (+ the pill/islands margin). Holds the three sections.
2. **The panel overlay** — namespace `pilo-popup`, layer Overlay,
   `exclusiveZone: -1`. An invisible full-screen surface whose top/bottom margin
   equals the bar's strip, so it never covers the bar. A backdrop `MouseArea`
   closes the panel on an outside click. Each panel is a child positioned under
   its trigger widget, clamped to the screen. This is what makes clicks inside
   panels work reliably under Hyprland.
3. **The launcher overlay** — namespace `pilo-launcher`, layer Overlay,
   `exclusiveZone: -1`, keyboard focus Exclusive. Holds the centered launcher.

The anchored launcher is a child of the panel overlay; the centered launcher is
a child of the launcher overlay. `Panels.launcherAnchored` selects which one is
shown and which window is visible.

Panel placement no longer binds to specific widget ids. A widget that opens a
panel calls `Panels.toggle(name, screen, this)`; `Panels` stores the widget's
anchor (`anchorX`/`anchorW`, bar-local) and `Bar.qml` positions whichever panel
is open with `panelX(width)`/`panelY(height)`. Panels opened via IPC pass no
widget, so `anchorValid` is false and the panel centers on the screen.

The **settings window** (`SettingsWindow.qml`) is the one exception: a single
`FloatingWindow` created in `shell.qml`, not a layer surface, so the compositor
tiles/floats it like a normal window. `SettingsApp` holds its transient state
(open, target screen, category, search).

Each `Bar.qml` also creates an **identify overlay** — namespace
`pilo-identify`, layer Overlay, `exclusiveZone: -1`. It is visible while
`Displays.identifyActive` is true and shows the display's number, name, and
resolution centered on that screen. It auto-hides after 5s (`Displays`' timer) or
on click. Which number a screen gets comes from `Displays.idFor()`, the same
left-to-right order shown in the settings list.

Panels size their height to their content (`implicitHeight`), with caps on long
lists so they scroll instead of growing forever. The bar sets each panel's
height from that. Widths are fixed. The centered launcher is deliberately fixed
size.

## State and settings

`Settings.qml` is a `FileView` + `JsonAdapter` at
`$XDG_STATE_HOME/quickshell/by-shell/<id>/settings.json`. The adapter's
properties are the settings; `onAdapterUpdated: writeAdapter()` persists them.
Keys: `chrome`, `edge`, `opacity`, `gap`, `workspaceMode`, `launcherSort`,
`fileSearch`, `holidays`, `layout` (bar widget arrangement), and `usage`
(per-app launch counts/timestamps). `resetAll()` restores the defaults;
`exportTo(path)`/`importFrom(path)` copy the file (import reloads the adapter).

`Panels.qml` holds all transient bar-panel UI state: which panel is open, on
which screen, the anchor of the widget that opened it, the launcher
presentation, and the window menu's app list. `SettingsApp.qml` holds the
settings window's transient state.

## Bar layout

`BarWidgets.qml` lists the available widgets (launcher, taskbar, workspaces,
clock, network, sound, settings, spacer) and produces the default
`{ left, center, right }` layout. `Bar.qml` renders each section by repeating
over `Settings.sectionList(section)` and mapping each key to a `Component` via
`componentFor()`; a `Loader` instantiates it (unknown keys render nothing).
The components are declared in
`Bar.qml` so they can bind `screen: bar.screen`. The settings app's Widgets
category edits the stored lists (add, move, remove, reset): a palette of widgets
sits at the bottom, each column has a `+` menu, and drag-and-drop moves rows
between columns or back to the palette to remove. Drag state lives in flat
properties on the category item (in-place mutation of a JS object would not
notify bindings); drops hit-test the column list rectangles and compute an
insertion index from the y position.

`Settings.migrateLayout()` drops stored keys that are no longer in the registry
(e.g. the removed `monitors` widget) on load; it is guarded on `FileView.loaded`
so a hot reload cannot rewrite the file from the adapter's defaults.

## Hyprland integration (and its gotchas)

The compositor runs the Lua config format, which changes how you call
dispatchers:

- **Classic dispatchers are rejected.** `hyprctl dispatch 'workspace 3'` fails
  with `')' expected near '3'`. Use the Lua form through hyprctl, e.g.
  `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`. This is why
  `Workspaces.qml` and `RunningApps.qml` build `hl.dsp…` strings and run them
  with `hyprctl`.
- **Window focus/close/kill.** `hl.dsp.focus({ window = "address:0x…" })`,
  `hl.dsp.window.close({ window = … })` (graceful),
  `hl.dsp.window.kill({ window = … })` (SIGKILL).
- **Running windows** come from `hyprctl clients -j` and are rebuilt on
  Hyprland events (debounced), not bound to `Hyprland.toplevels`, which did not
  stay live.
- **Monitors are configured in a separate file.** `hyprland.lua` no longer
  lists monitors; it does
  `for _, m in ipairs(require("monitors")) do hl.monitor(m) end`, reading
  `~/.config/hypr/monitors.lua`. `Displays.qml` (used by the settings app's
  Displays page) rewrites that file and applies changes live with
  `hyprctl keyword monitor`. The written file is treated as generated (see
  `.gitignore` in the dotfiles repo).
- **Super opens this launcher.** `hyprland.lua`'s `menu` variable is
  `qs -c pilo ipc call pilo toggle launcher`.
- **Layer rules.** `hyprland.lua` blurs `pilo-bar` and sets `no_anim` on
  `pilo-launcher`, `pilo-popup`, and `pilo-identify`. The `no_anim` is required:
  the config's `fadeLayers` animation runs at speed 60, which otherwise makes
  the overlays take ~4 seconds to fade in.

## Process model

Prefer native Quickshell services; shell out only where needed.

| Concern | Source |
|---|---|
| Screens | `Quickshell.screens` |
| Workspaces | `Quickshell.Hyprland` for state; switching via `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'` |
| Clock | `SystemClock` |
| Apps | `DesktopEntries` |
| Files | `plocate` via `Process` |
| Network | `Quickshell.Networking` |
| Bluetooth | `Quickshell.Bluetooth` |
| Volume | `Quickshell.Services.Pipewire` (a `PwObjectTracker` keeps nodes live) |
| Power profile | `powerprofilesctl` via `Power.qml` |
| Holidays | `Holidays.qml` |
| Running apps | `hyprctl clients -j`; actions via `hyprctl dispatch 'hl.dsp…'` |
| Monitors | `Displays.qml`: `hyprctl monitors -j` / `hyprctl keyword monitor` |
| Session | `systemctl` / `hyprctl`, as in the old power menu |

## Known issues / decisions

- **UPower `PowerProfiles` is not used.** Its setter updates its own value but
  does not reach the daemon on this version, so `Power.qml` sets and reads the
  profile through `powerprofilesctl` and reads back after setting. On this
  machine the `amd_pstate` driver rejects `power-saver` and `performance`
  (`Error writing policy11/boost`), so only Balanced takes effect; the UI shows
  the real state rather than an optimistic one.
- **Panels are plain `PanelWindow` items, not popups.** `PopupWindow` +
  `HyprlandFocusGrab` dismissed the panel on the first click under Hyprland, so
  the overlay model above replaced it. Do not reintroduce popups for the
  anchored panels.
- **Panel heights follow content.** Long lists are capped (Wi-Fi 220, Bluetooth
  180, outputs 180, monitors 460, window menu 400) and scroll.
- **Bar sections cannot overlap.** The left and right groups are capped at
  `(barWidth - centerGroup.width) / 2 - 6` and `clip: true`, so a long section
  (e.g. many taskbar widgets) is clipped at the inner edge rather than running
  under the centered group.
- **`quickshell` state dir.** `Settings.qml` runs `mkdir -p` for the state dir
  at startup; the first launch logs a harmless "File does not exist" read
  warning until a setting is changed.
- **Do not start a notification server.** Something else owns
  `org.freedesktop.Notifications`.
- **The settings window is a normal toplevel.** `SettingsWindow.qml` is a
  `FloatingWindow`, so the compositor decides whether to tile or float it; add a
  Hyprland `float` window rule if it should always float. It is deliberately not
  a layer surface and does not join the panel overlay.

## Working on it

- Hot reload: edit and save; the bar reloads. Structural changes (new files,
  imports, a changed singleton) are safer with a restart.
- Add a bar widget: a `BarButton` subclass (or item) in `widgets/`, add a
  `Component { id: comp…; … { screen: bar.screen } }` and a `componentFor()`
  branch in `Bar.qml`, then add it to `BarWidgets.available` and the default
  layout.
- Add a panel: a `PanelCard` root in `panels/` whose content sets
  `implicitHeight`, add it to the panel overlay in `Bar.qml` with
  `x: bar.panelX(width)` / `y: bar.panelY(height)`, and add the panel name to
  `Panels.qml`. Panels are keyed by `Panels.active`; the opening widget passes
  itself to `Panels.toggle()` for anchoring.
- Add a settings category: a `ColumnLayout` in `settings/` built from
  `CategoryHeading` and `SettingRow`, wire it into `SettingsWindow.qml`
  (`categories`, `categoryComponent`, a `Component`), and add its settings to
  the `SettingsSearch` index.
- Validate the Lua config after editing it:
  `luajit -bl ~/.config/hypr/hyprland.lua >/dev/null`, then
  `hyprctl reload` and `hyprctl configerrors`.
- Test input with `ydotool` (`mousemove -a -x … -y …`, `click 0xC0` left,
  `0xC1` right) and `wtype` for typing. A real mouse/touchpad is still the last
  word, especially for wheel input.
