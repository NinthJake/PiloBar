# Pilo bar — reminders / backlog

All review items are done. Feature ideas live in `FEATURE_REQUESTS.md`.

## Done

1. **Workspace clicks did nothing.** Hyprland's Lua config rejects the classic
   `workspace N` dispatcher. `Workspaces.qml` dispatches
   `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'`.
2. **Calendar / network / sound faded in slowly.** Compositor `fadeLayers`
   runs at speed 60. Added `no_anim` layer rules for `^pilo-launcher$` and
   `^pilo-popup$` in `hyprland.lua`. Overlays appear instantly.
3. **Calendar holiday hover shifted the grid.** The footer is now a fixed
   16px row, so the grid never reflows when the holiday name appears.
4. **Calendar keyboard + wheel month switching.** Left/Right arrows change the
   month (the panel takes focus when shown). Wheel over the calendar changes
   the month via a transparent `MouseArea` (`acceptedButtons: Qt.NoButton`),
   which does not block clicks.
5. **Power profile moved into bar settings.** Removed from `SoundPanel.qml`;
   added a Power profile row to `SettingsPanel.qml`, still driven by
   `Power.qml` (`powerprofilesctl`).
6. **Configurable chrome gap.** New `gap` setting (0–24, default 8) with a
   slider in bar settings; `Bar.qml` uses it for the pill/islands margin and
   `exclusiveZone`.
7. **File search off but Files chip shown.** The launcher's scope chips are
   built from `Settings.fileSearch`; the Files chip is hidden when it is off,
   and switching to it is blocked.
8. **Launcher keyboard scope toggle.** Tab toggles between applications and
   files (when file search is enabled).
9. **Super invokes the Quickshell launcher.** `hyprland.lua` `menu` is now
   `qs -c pilo ipc call pilo toggle launcher`; the Super-tap bind is unchanged
   and now opens the shell launcher. pibble's Super+Space launcher is left as
   a second launcher.

## Feature requests

Kept in `FEATURE_REQUESTS.md`. First entry: **Hyprland monitors widget**
(horizontal arrangement, refresh rate, scale; splits the monitor config out of
`hyprland.lua`).
