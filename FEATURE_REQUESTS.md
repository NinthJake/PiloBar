# Pilo bar — feature requests

Active, not-yet-implemented ideas. Implemented work is recorded in
`CHANGELOG.md`; review fixes live in `REMINDERS.md`.

---

## 1. Theming in the settings app (switch the whole PC's theme)

### Status

Bar-side shipped (see `CHANGELOG.md`): a `Themes.qml` registry (Vague default +
Gruvbox/Frost/Everforest/Rosé Pine/Catppuccin/Dracula/Material/Nord),
`Theme.qml` resolving
it, a persisted `Settings.theme`, and the **Theming** category picker.
Dolphin/KDE shipped: `KdeTheme.qml` generates and applies a KDE colour scheme;
foot shipped too. Notifications no longer depend on pibble:
`Notifications.qml` is pilo's own daemon and follows `Theme`. Hyprland's look
and feel is no longer Pilo's job: HyprMod owns `hyprland-gui.lua`, and Theming
links to it. **Remaining:** pibble's remaining surfaces, and the Dynamic/Custom
schemes. The rest of this entry covers those.

### Goal

A **Theming** category in the pilo settings app that switches the look of the
whole machine from one place, integrated with Hyprland. Some sources are still
hardcoded or separate:

- the bar's colours now come from `Themes.qml` (done);
- Hyprland's look and feel is delegated to HyprMod, which owns
  `hyprland-gui.lua`; Pilo no longer writes `lookandfeel.lua` or exposes
  `hypr*` settings;
- pibble has its own separate theme picker (`Settings.theme`, presets
  **Amber**, **Frost**, **Moss**, **Rose**, **Custom**, and **Dynamic**
  (matugen)) affecting only pibble's launcher, wallpaper picker, and volume OSD.
  Pilo's notifications now follow Pilo's theme instead.

The current look is the built-in **default theme** ("Vague"), so nothing should
change visibly until another scheme is picked. Picking a theme should update the
bar, Hyprland, and (where possible) the rest of the desktop — today that also
means the files app (Dolphin) and other KDE apps — with one persisted choice.

### Shape

- ~~A **Theming** category whose picker looks like pibble's `ThemeRow`: cards
  with colour swatches and a name, one selected.~~ (done)
- ~~A single persisted `theme` setting in `Settings.qml` is the source of truth;
  applied live and re-applied on login.~~ (done)
- Switching a theme updates:
  - ~~**pilo bar** — `Theme.qml` derives its tokens from the active theme instead
    of constants (same property names, so no widget changes).~~ (done)
  - **Hyprland** — handled by HyprMod; Pilo's Theming only launches it.
  - **pibble** — set pibble's theme so its surfaces follow.
  - **Dolphin / KDE apps** — write a KDE colour scheme and update the active
    `kdeglobals` colours so Dolphin follows (see below).
  - ~~Optionally other apps (foot, btop, GTK/Qt) through per-app templates, the
    way matugen already does for Hyprland and waybar.~~ foot is done
    (`FootTheme.qml` + `foot.ini` include). btop / GTK / Qt still open.

### Theme sources

- ~~**Built-in schemes** — reuse pibble's named palettes (Amber, Frost, Moss,
  Rose) plus the current vague.nvim palette as the default "Vague".~~ (done) —
  current set: **Vague** (default), **Gruvbox**, **Frost**, **Everforest**,
  **Rosé Pine**, **Catppuccin** (Mocha), **Dracula**, **Material**, **Nord**.
- **Dynamic** — colours sampled from the current wallpaper with `matugen`
  (already installed; templates exist under
  `~/.config/fedup/dotfiles/matugen/`). Colour generation was removed when
  Hyprland/waybar went back to vague.nvim, so this has to be wired up again.
- **Custom** — a user accent/foreground/muted picker, seeded from the active
  scheme.

A theme needs the full bar token set, not just three colours: `bg`, `fg`,
`line`, `muted`, accent (`teal`), `steel`, `error`, `warning`, and `plus`.

### Hyprland look and feel (delegated)

No longer part of Pilo. HyprMod is the source of truth and writes
`~/.config/hypr/hyprland-gui.lua`, loaded late by `hyprland.lua`; the Theming
category only provides an **Open HyprMod** button. The old generated
`lookandfeel.lua` is left as a static base but Pilo no longer writes it, applies
compositor colours, or exposes `Settings.hypr*` controls.

### Files app (Dolphin) and KDE integration (done)

Implemented. `KdeTheme.qml` generates a scheme at
`~/.local/share/color-schemes/Pilo-<theme>.colors` and applies it with
`plasma-apply-colorscheme`, which updates `~/.config/kdeglobals` (`[Colors:*]`
groups, `ColorScheme`, `ColorSchemeHash`, `[WM]`) and notifies the session so
running KDE apps reload. KDE needs more roles than the bar's ~10 tokens, so the
scheme derives window/view/button/selection/tooltip backgrounds and the
foreground roles from the palette via `shade()`; Dolphin was verified to render
in the scheme. Triggered from `shell.qml` on start and on `Settings.onThemeChanged`.
Without `plasma-workspace` the bar falls back to
`scripts/kde-apply-colorscheme.sh` (kwriteconfig6), and KDE apps still need
`plasma-integration` for the KDE platform theme.

Open: colour scheme only — icon theme, window decoration, and cursor are
untouched. The generated schemes are per-theme files under
`~/.local/share/color-schemes/` (not cleaned up when a theme is removed).

### Applying and persisting

- ~~Persist the selected theme in pilo's `Settings.qml`.~~ (done)
- On change: bar palette instantly (done); KDE and foot (done); tell pibble
  (remaining). Hyprland is intentionally untouched.
- On login: the bar re-applies the persisted theme (done).

### Technical notes

- ~~Add a `Themes.qml` singleton registry (id, name, palette) and make
  `Theme.qml` read from it, keeping the current token names.~~ (done). Hyprland
  no longer consumes the palette; HyprMod owns compositor colours. KDE may still
  need a per-theme role mapping when that lands.
- pibble's theme lives in its own settings file and has no theme IPC (its
  `IpcHandler` targets `launcher` only). Options: write pibble's settings file
  and signal it, add a pibble IPC (`pibble ipc …`), or agree on a shared
  "active theme" file both read. A shared file under `~/.config` avoids
  coupling the two configs.
- Reintroducing **Dynamic** means running matugen for the current wallpaper and
  writing the theme outputs; `matugen-apply` currently only sets the wallpaper
  and pins/toggles random rotation.
- waybar is disabled, but its matugen template still exists — decide whether to
  keep generating for it.
- The pibble and pilo palettes currently differ (pibble presets vs vague.nvim),
  so a shared theme definition has to reconcile them (or pilo becomes the
  canonical definition and pibble adopts it).

### Open questions

- Does a theme include the wallpaper, or only colours? (Dynamic is
  wallpaper-derived; the named schemes are wallpaper-independent unless a theme
  also chooses one.)
- Scope: Hyprland + the two shells only, or also GTK/Qt/KDE colours, terminal,
  and other apps?
- ~~Live `hyprctl keyword` versus `hyprctl reload` for applying (reload re-runs
  the autostart block).~~ Resolved: `hyprctl eval` (keyword is rejected on
  0.56); the generated file covers the next login.
- Where is the canonical theme definition: pilo, pibble, or a new shared
  `~/.config/themes/` directory? (Hyprland now reads pilo's definition as the
  source of truth.)
- Should pibble keep its own picker, delegate to pilo, or stay in sync with it?
- ~~Dolphin/KDE scope: colour scheme only, or also window decoration, icon theme,
  and the Breeze-vs-custom widget style?~~ Resolved: colour scheme only for now;
  icons/decoration/cursor untouched.
- ~~Where do the KDE schemes live: one `<Theme>.colors` per pilo theme, or a
  single generated scheme that pilo overwrites on each change?~~ Resolved: one
  `Pilo-<theme>.colors` per theme under `~/.local/share/color-schemes/`.
