# Changelog

All notable changes to the pilo bar. Implemented feature requests and review
fixes are recorded here; active ideas live in `FEATURE_REQUESTS.md`.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **Settings app** — a standalone `FloatingWindow` (`SettingsWindow.qml`),
  opened from the gear or `qs -c pilo ipc call pilo toggle settings`. A
  searchable category sidebar holds **Bar**, **Displays**, **Widgets**,
  **Launcher**, **Calendar**, **System**, and **Advanced**; searching jumps to
  the matching setting. Edits apply to the bar live. Advanced shows the settings
  file location and can export/import a backup or reset everything to defaults.
- **Displays page** — arrange monitors by dragging the screen cards left or
  right, and set each monitor's refresh rate and scale. Changes apply live and
  persist to `~/.config/hypr/monitors.lua`, which `hyprland.lua` loads.
- **Identify** — flashes a large number, output name, and resolution on each
  screen (`pilo-identify` layer surface) so a card in the Displays page is
  unambiguous. It hides after 5s or on click.
- **Movable bar widgets** — a registry (`BarWidgets.qml`) plus a stored
  `layout` setting drive what appears in the Left, Center, and Right sections.
  The Widgets category edits it with a bottom palette of available widgets, a
  `+` menu on each column, and drag-and-drop to add, reorder, move between
  columns, or remove (drag a row back to the palette).
- **Bar spacer** widget, plus shared settings controls (`SettingRow`,
  `IconButton`, `TextField`).
- **Centered chrome** — a content-sized rounded bar centered on the screen with
  the three sections grouped together, flush against the docked edge. Replaces
  the old Pill mode.
- **Rounding** — a corner-radius slider for the Centered and Islands chrome,
  plus a **Round all corners** toggle. With it off, corners on a screen edge
  stay square, and the Islands `Gap` no longer floats the bar off the edge, so
  the bar meets every screen edge it touches squarely.
- **Auto-hide** — a Bar setting that slides the bar off its docked edge and
  reveals it when the pointer touches that edge. The hide delay is adjustable
  (0.1–2s); the reveal trigger is a thin strip on the edge (`pilo-trigger`). A
  companion **Over windows** toggle (shown only while auto-hide is on) keeps the
  bar floating over windows instead of reserving space for it.
- IPC: `toggle monitors` / `toggle displays` opens the settings window on the
  Displays page.

### Changed

- Chrome modes are now **Flush**, **Centered**, and **Islands**; the old Pill
  mode was removed. A stored `pill` value migrates to `centered` on load.
- Settings rows that don't apply (Rounding/Gap, Hide delay/Over windows) are now
  dimmed and disabled instead of hidden, and explain why in a tooltip when
  clicked.
- Monitor configuration moved out of the bar into the settings app; the
  Monitors bar widget and `MonitorsPanel` were removed. Stored layout entries
  for widgets that no longer exist are migrated out on load.
- Panels now anchor generically: the opening widget passes itself to
  `Panels.toggle()`, and every anchored panel is positioned from that anchor.
  Panels opened over IPC center on the screen.
- Left and Right bar sections are capped to the space around the centred group
  and clip overflow, so a section can never overlap the workspaces.
- The gear opens the settings app instead of the old single-column settings
  panel; `panels/SettingsPanel.qml` was removed.
- The opacity slider now ranges 50–100% (was 60–100%).

### Fixed

- Changing the bar edge (Settings -> Bar -> Edge) no longer leaves the bar
  stuck at full opacity until a restart. Re-anchoring a live layer surface on
  Hyprland leaves it without a fresh configure, so it stops repainting; the bar
  window is now recreated when the edge changes so it gets a fresh surface.
- Widgets settings columns are equal width (the add-chip `Flow` no longer
  drives the column width).
- An overfull bar section clips at its inner edge instead of overlapping the
  centre.
- Layout migration is guarded on `FileView.loaded`, so a hot reload can't
  rewrite the settings file from the adapter's defaults.

## [0.1.0] — Initial bar

- Three-section bar on every screen: launcher and running-app icons (left),
  workspaces 1–10 (centre), clock, network/Bluetooth, sound, and settings
  (right).
- Anchored panels and a centered launcher from a single overlay per screen.
- Clock calendar with Swedish holidays, application/file launcher, and the
  original bar settings (chrome, edge, opacity, gap, workspaces, holidays,
  launcher sort, file search, power profile).
