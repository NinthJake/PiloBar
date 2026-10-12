# Pilo bar — agent notes

Quickshell (QML) status bar for Hyprland. Not a build repo: no package manager,
compiler, linter, or test suite. QML is loaded and hot-reloaded by Quickshell.
`README.technical.md` is the day-to-day technical map; `DESIGN.md` is the design
doc; `CHANGELOG.md` records implemented work; `FEATURE_REQUESTS.md` holds active
ideas. Keep those docs updated with behavior changes.

## Run / iterate

- Start: `qs -c pilo`. Run it in a terminal; it hot-reloads on save.
- Hot reload fires only on **content** changes; `touch` is ignored ("Ignoring
  file change with unchanged content"). To make the shell re-read
  `settings.json` while testing, save a real edit to a watched QML file.
- Structural changes (new files, imports, changed singletons) need a restart.
- Restart by PID, **not** `pkill -x qs` (that kills other Quickshell instances):
  `pgrep -ax qs` then `kill <pid>`.
- Logs: `/run/user/$(id -u)/quickshell/by-id/<id>/log.qslog`; read with
  `strings <file> | rg -i "error|warn"`.
- IPC: `qs -c pilo ipc call pilo toggle <launcher|calendar|network|sound|settings|monitors>`
  and `qs -c pilo ipc call pilo close`. `monitors`/`displays` opens the settings
  window on the Displays page; `settings` opens the standalone window.

## Hard gotchas

- **Hyprland uses the Lua config format.** Classic dispatchers are rejected
  (`hyprctl dispatch 'workspace 3'` fails). Always use the Lua form:
  `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`. Window actions:
  `hl.dsp.focus({ window = "address:0x…" })`, `hl.dsp.window.close({...})`,
  `hl.dsp.window.kill({...})`.
- **Panels are plain `PanelWindow` layers, never `PopupWindow`.** Popups +
  `HyprlandFocusGrab` dismissed on first click under Hyprland. Do not
  reintroduce popups for anchored panels.
- **Do not start a notification server** — something else owns
  `org.freedesktop.Notifications`.
- `pilo-bar`/`pilo-launcher`/`pilo-popup`/`pilo-identify` need `no_anim` layer
  rules; the config's `fadeLayers` otherwise fades overlays in over ~4s.
- Monitor config lives in generated `~/.config/hypr/monitors.lua` (loaded by
  `hyprland.lua`), rewritten by `Displays.qml`; don't hand-edit as source.
- Hyprland's look and feel lives in generated `~/.config/hypr/lookandfeel.lua`,
  loaded by `hyprland.lua` with `pcall(require, "lookandfeel")` and written by
  `HyprTheme.qml` (the pilo Theming category). Both files are gitignored in the
  fedup repo. **`hyprctl keyword` is rejected for these options on 0.56**
  ("keyword can't work with non-legacy parsers. Use eval.") — live-apply with
  `hyprctl eval 'hl.config({ … })'`. (`hyprctl keyword monitor` still works.)
- Only one panel open at a time; opening widget passes itself to
  `Panels.toggle(name, screen, this)` for anchoring. IPC-opened panels center.

## Architecture

- `shell.qml` — ShellRoot: one `Bar.qml` per screen, IPC, audio `PwObjectTracker`.
  `SettingsWindow.qml` is a `FloatingWindow` (normal toplevel, not a layer).
- Singletons (`pragma Singleton`, imported via `qs`): `Theme`, `Themes`,
  `Settings`, `Panels`, `Power`, `Holidays`, `RunningApps`, `BarWidgets`,
  `SettingsApp`, `Displays`, `HyprTheme`, `KdeTheme`, `FootTheme`.
  `HyprTheme`/`KdeTheme`/`FootTheme` push the active theme to the compositor, to
  KDE apps, and to the foot terminal; all apply once from `shell.qml` and
  re-apply on `Settings.onThemeChanged`. (`FootTheme` writes
  `~/.config/foot/colors.ini`, included from `foot.ini`, and reloads foot with
  `pkill -USR1 -x foot`.)
- `widgets/` bar buttons/controls; `panels/` panel contents (no windows);
  `settings/` settings-window categories. Cross-dir imports: `qs.widgets`,
  `qs.panels`; same-dir types use the implicit import.
- Settings persist at `$XDG_STATE_HOME/quickshell/by-shell/<id>/settings.json`
  (`Settings.qml` = `FileView` + `JsonAdapter`; `onAdapterUpdated:
  writeAdapter()`). `Settings.migrateLayout()` drops removed widget keys, guarded
  on `FileView.loaded` so hot reload can't rewrite the file.
- Bar sections are rendered from `Settings.sectionList(section)` via
  `componentFor()` in `Bar.qml`. Left/Right sections are capped and clipped so
  they never overlap the centered group.

## Common tasks

- **Add a bar widget:** item in `widgets/`, a `Component { … screen: bar.screen }`
  + `componentFor()` branch in `Bar.qml`, register in `BarWidgets.available` and
  the default layout.
- **Add a panel:** `PanelCard` root in `panels/` setting `implicitHeight`, add to
  the panel overlay in `Bar.qml` with `x: bar.panelX(width)` / `y:
  bar.panelY(height)`, add the name to `Panels.qml`.
- **Add a settings category:** `ColumnLayout` in `settings/` from
  `CategoryHeading`/`SettingRow`, wire into `SettingsWindow.qml`, add to
  `SettingsSearch`.
- **Validate Lua after editing:** `luajit -bl ~/.config/hypr/hyprland.lua
  >/dev/null`, then `hyprctl reload && hyprctl configerrors`.
- **Test input:** `ydotool` (`mousemove -a -x … -y …`, click `0xC0` left / `0xC1`
  right) and `wtype`; a real pointer is the last word for wheel input.

## Requirements

Hyprland 0.56+ (Lua config), Quickshell 0.3.1, FiraCode Nerd Font. Optional
features degrade gracefully without NetworkManager, BlueZ, PipeWire (`wpctl`),
`powerprofilesctl`, or `plocate`.
