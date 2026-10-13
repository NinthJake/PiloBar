# Changelog

All notable changes to the pilo bar. Implemented feature requests and review
fixes are recorded here; active ideas live in `FEATURE_REQUESTS.md`.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **Theming** — a `Themes.qml` registry of colour schemes and a **Theming**
  category in the settings app. Each scheme is previewed as a card (its own
  colours) and picking one repaints the bar live; the choice is persisted as
  `Settings.theme` and restored on login. Built-ins: **Vague** (default, the
  bar's original palette), **Gruvbox**, **Frost**, **Everforest**,
  **Rosé Pine**, **Catppuccin** (Mocha), **Dracula**, **Material**, **Nord**.
- **Hyprland themes with the bar** — the Hyprland "Look and feel" block moved
  out of `hyprland.lua` into a generated `~/.config/hypr/lookandfeel.lua`, which
  the bar writes from a `HyprTheme.qml` singleton (structural values plus the
  active theme's border/background colours) and `hyprland.lua` loads with
  `require()`. Switching a theme recolours the compositor instantly via
  `hyprctl eval` (Hyprland 0.56 rejects `hyprctl keyword` for these options);
  the file covers the next login. The Theming category also exposes **inner/outer
  gaps, border size, window rounding, and blur** as persisted settings, applied
  live the same way. The file is gitignored like `monitors.lua`. pibble is still
  future work.
- **KDE apps (Dolphin) theme with the bar** — `KdeTheme.qml` generates a KDE
  colour scheme under `~/.local/share/color-schemes/Pilo-<theme>.colors` from the
  active theme and applies it with `plasma-apply-colorscheme`, which rewrites
  `~/.config/kdeglobals` and notifies the session. KDE needs more colour roles
  than the bar's tokens, so the scheme derives window/view/button/selection/
  tooltip backgrounds and the foreground roles from the palette. Dolphin follows
  (verified).
- **foot terminal themes with the bar** — `FootTheme.qml` generates
  `~/.config/foot/colors.ini` (gitignored) from the active theme and sends
  running foot instances `SIGUSR1` to reload. `foot.ini` includes the file from
  its `[main]` section and keeps only the structural options (`alpha`, `blur`)
  in `[colors-dark]`. The 16-colour ANSI palette maps the bar tokens (black=line,
  red=error, green=plus, yellow=warning, blue=steel, magenta=accent, cyan=a
  lightened steel, white=fg), with selection and cursor on the accent.
- **Settings app** — a standalone `FloatingWindow` (`SettingsWindow.qml`),
  opened from the gear or `qs -c pilo ipc call pilo toggle settings`. A
  searchable category sidebar holds **Bar**, **Displays**, **Widgets**,
  **Launcher**, **Calendar**, **System**, and **Advanced**; searching jumps to
  the matching setting. Edits apply to the bar live. Advanced shows the settings
  file location and can export/import a backup or reset everything to defaults.
- **Displays page** — a to-scale canvas lays the monitors out at their real
  (logical) resolution and drags them in 2D. Edges and corners snap while
  dragging; dropping a display over others pushes them out of the way so
  nothing ever overlaps, and the preview keeps a small readability gap. Each
  monitor has resolution and refresh-rate dropdowns plus scale pill buttons. Changes apply live
  and persist to `~/.config/hypr/monitors.lua`, which `hyprland.lua` loads.
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
- **Custom app icons** — the running-apps taskbar and its window menu use a
  per-app SVG from `assets/icons/<class>.svg` when one exists (matched by window
  class, or the last dotted segment of it), and fall back to the desktop-entry
  icon otherwise.
- **Centered chrome** — a content-sized rounded bar centered on the screen with
  the three sections grouped together, flush against the docked edge. Replaces
  the old Pill mode.
- **Rounding** — a corner-radius slider for the Centered and Islands chrome.
  It applies to corners that touch no screen edge, and to every corner while
  **Attach to screen edges** is off.
- **Shape** — a Bar setting choosing how the Centered and Islands chrome meets
  the docked screen edge: **Rounded** (the previous look), **S-curve** (a concave
  cove at the edge, convex away from it), or **Bevel** (a straight flare that
  blends smoothly into a rounded outer corner; the fillet is scaled to match a
  plain rounded corner).
  S-curve and Bevel are drawn in Centered and Islands; the **Attach to screen
  edges** toggle squares off the left/right screen-edge corners.
- **Attach to screen edges** — replaces the old **Round all corners** toggle.
  When on (default), the corners that meet a screen edge are square, so the bar
  merges with the edge. With S-curve/Bevel this squares only the left/right
  edge corners, keeping the shape along the top; turn it off to shape/round them
  too.
- **Auto-hide** — a Bar setting that slides the bar off its docked edge and
  reveals it when the pointer touches that edge. The hide delay is adjustable
  (0.1–2s); the reveal trigger is a thin strip on the edge (`pilo-trigger`).
- **Over windows** — a Bar setting that keeps the bar floating over windows
  instead of reserving screen space for it. It works on its own, with or without
  Auto-hide.
- IPC: `toggle monitors` / `toggle displays` opens the settings window on the
  Displays page.

### Changed

- Chrome modes are now **Flush**, **Centered**, and **Islands**; the old Pill
  mode was removed. A stored `pill` value migrates to `centered` on load.
- Settings rows that don't apply (e.g. Hide delay) are now dimmed and disabled
  instead of hidden, and explain why in a tooltip when clicked.
- The Islands **Gap** setting was removed; islands always sit flush against the
  screen edge, so a shaped or rounded bar never floats away from it.
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
- The Displays page lays each monitor out as a box in a wrapping, responsive
  grid (aiming for ~280px boxes) with the resolution and refresh-rate dropdowns
  and scale pills, instead of a full-width list. The arrangement canvas scales
  every display to fit, so it works with many screens.

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
- The Displays refresh dropdown now shows the current mode. The reported rate is
  matched to the nearest available mode key (e.g. 239.95799 → "239.96");
  previously the rounded value matched no option and the picker was blank.

## [0.1.0] — Initial bar

- Three-section bar on every screen: launcher and running-app icons (left),
  workspaces 1–10 (centre), clock, network/Bluetooth, sound, and settings
  (right).
- Anchored panels and a centered launcher from a single overlay per screen.
- Clock calendar with Swedish holidays, application/file launcher, and the
  original bar settings (chrome, edge, opacity, gap, workspaces, holidays,
  launcher sort, file search, power profile).
