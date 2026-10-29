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
- NetworkManager, iwd (`iwctl`), ConnMan (`connmanctl`), or wpa_supplicant
  (`wpa_cli`) for Wi-Fi controls; any other stack gets read-only kernel status.
- BlueZ (Quickshell native or `bluetoothctl`).
- PipeWire (native), PulseAudio (`pactl`), or ALSA (`amixer`).
- `powerprofilesctl`, `plocate` (file search). None of these are hard
  requirements for the bar to start; the matching feature degrades if one is
  missing. HyprMod is optional and provides Hyprland's own look-and-feel
  settings; Theming only links to it. No external notification daemon (mako,
  dunst, …) is needed or wanted: Pilo owns
  `org.freedesktop.Notifications`.

## File layout

```
pilo/
  shell.qml            ShellRoot: bars, notifications and IPC
  Bar.qml              per-screen PanelWindow, sections, and the overlays
  Theme.qml            colours, font, sizes, motion, glyphs        (singleton)
  Themes.qml           colour-scheme registry (palettes)           (singleton)
  Settings.qml         persisted settings                         (singleton)
  KdeTheme.qml         writes + applies a KDE colour scheme for Dolphin (singleton)
  FootTheme.qml        writes foot colors.ini + SIGUSR1 reloads foot (singleton)
  Panels.qml           which panel is open, on which screen        (singleton)
  Network.qml          network backend facade                      (singleton)
  BluetoothManager.qml Bluetooth backend facade                    (singleton)
  Audio.qml            audio backend facade + PwObjectTracker      (singleton)
  Power.qml            power profile via powerprofilesctl          (singleton)
  Holidays.qml         holiday dates per region                   (singleton)
  Notifications.qml    notification daemon + per-screen toast windows
  RunningApps.qml      running-window model + focus/close/kill     (singleton)
  BarWidgets.qml       available bar widget registry + default layout (singleton)
  SettingsApp.qml      settings window open/category/search state  (singleton)
  Displays.qml         monitor model + arrange/refresh/scale/identify (singleton)
  ClockFormat.qml      formats the bar clock from Settings           (singleton)
  SettingsWindow.qml   standalone settings window (FloatingWindow)
  widgets/             bar buttons and small controls
    BarButton, LauncherButton, NetworkButton,
    SoundButton, SettingsButton, Taskbar, Workspaces, Clock, BarSpacer,
    PanelCard, Segmented, Slider, Toggle, ActionButton,
    SettingRow, IconButton, TextField, BarShape, Dropdown, Pills, Tooltip
  panels/              panel contents (no windows of their own)
    AppLauncher, CalendarPanel, NetworkPanel, SoundPanel, WindowsMenu
  notifications/
    NotificationCard.qml  one themed toast (icon, body image, actions)
  settings/            settings window categories
    BarCategory, ThemingCategory, DisplaysCategory, WidgetsCategory, LauncherCategory,
    ClockCalendarCategory, SystemCategory, AdvancedCategory, SettingsSearch,
    CategoryHeading
  DESIGN.md            original design document
  README.md            user-facing overview
  CHANGELOG.md         implemented changes and added features
  REMINDERS.md         review fixes
  FEATURE_REQUESTS.md  active (not-yet-implemented) feature ideas
```

Singletons use `pragma Singleton` and are imported with `qs`. Cross-directory
imports are `qs`, `qs.widgets`, `qs.panels`, `qs.notifications`. The
neighbouring-file implicit import covers same-directory types.

## Window / overlay model

Everything is a layer-shell `PanelWindow`; there are no xdg-popups and no
focus-grab objects. Per screen, `Bar.qml` creates:

1. **The bar** — namespace `pilo-bar`, layer Top, `exclusiveZone` = bar height
   (+ the islands margin). Holds the three sections. With auto-hide on it slides
   off the edge via `margins` and drops its `exclusiveZone`; a 2px
   `pilo-trigger` strip on the edge reveals it on hover. **Over windows** also
   drops the `exclusiveZone` (so the bar floats over windows) and works on its
   own, without auto-hide.
2. **The panel overlay** — namespace `pilo-popup`, layer Overlay,
   `exclusiveZone: -1`. An invisible full-screen surface whose top/bottom margin
   equals the bar's strip, so it never covers the bar. A backdrop `MouseArea`
   closes the panel on an outside click. Each panel is a child positioned under
   its trigger widget, clamped to the screen. This is what makes clicks inside
   panels work reliably under Hyprland.
3. **The launcher overlay** — namespace `pilo-launcher`, layer Overlay,
   `exclusiveZone: -1`, keyboard focus Exclusive. Holds the centered launcher.

Pilo also creates one separate, content-sized notification surface per screen
(namespace `pilo-notifications`). It is not part of the bar/panel overlays: it
anchors to the bar's edge, sizes itself to the toast stack, and is only visible
while that screen has toasts. Because it is content-sized, empty space cannot
intercept clicks.

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
on click. Which number a screen gets comes from `Displays.idFor()`, which uses
`stableOrder` (output names sorted alphabetically). The number therefore stays
attached to the same monitor when the arrangement changes; the settings cards
use the same stable order instead of re-sorting by physical position.

Panels size their height to their content (`implicitHeight`), with caps on long
lists so they scroll instead of growing forever. The bar sets each panel's
height from that. Widths are fixed. The centered launcher is deliberately fixed
size.

## Notifications

`Notifications.qml` is instantiated once from `shell.qml` and owns the single
`NotificationServer`. Keeping the server out of `Bar.qml`/`Variants` matters:
only one object can own the D-Bus name, and it must survive screen changes.
`keepOnReload` is on; on a hot reload the server re-emits tracked notifications
and the new `Notifications.qml` adopts them again.

`onNotification` sets `notification.tracked = true` before doing anything else;
untracked notifications are discarded when the handler returns. Pilo keeps its
own newest-first `popups` list of `{ notification, screen }` records (not
`trackedNotifications.values`) because it needs to latch each toast to the
focused monitor at arrival. Each record is removed from the list by the
notification's `closed` signal, whatever closed it (timeout, explicit dismiss,
an action, or the sender withdrawing it).

Up to four toasts are shown. A fifth expires the oldest. The timeout comes from
the spec value in **milliseconds** (this is what Quickshell exposes despite the
type docs saying seconds): `-1` uses the defaults (3.5 s low, 6 s normal), `0`
and critical urgency never expire. Hovering pauses the timer; leaving restarts
it. Clicking the card invokes the action with identifier `default` (or dismisses
if there is none), the close button/right-click dismisses, and action chips call
`NotificationAction.invoke()` without force-closing resident notifications.

Capabilities advertised match what is rendered: body and actions on, image on,
markup/hyperlinks/body-images/action-icons/inline-reply/persistence off. Body
text is `Text.PlainText` so markup never leaks through as tags. Both `appIcon`
and `image` need resolution: `notify-send -i <name>` sends `image-path`, which
Quickshell turns into `image://icon/<name>`, and that can be a themed name or an
absolute path. The card routes both through `Quickshell.iconPath(..., true)` (or
a file URL) so a missing icon falls back to the bell glyph instead of Qt's
magenta missing-texture square. An `image` that is not an icon URI is rendered
as a body image.

## Network backends

Quickshell.Networking only has a NetworkManager backend, so using
`Networking.devices` directly reports every device as missing on iwd,
systemd-networkd, dhcpcd, ConnMan, etc. Widgets must go through `Network.qml`:

1. **NetworkManager** — when `Networking.backend` is
   `NetworkBackendType.NetworkManager`, the singleton uses the native
   `Networking` devices/networks and their live properties.
2. **iwd** — if `iwctl` reports an adapter/station, it parses
   `iwctl adapter list`, `station list/show`, `get-networks rssi-dbms`, and
   `known-networks list`. Connect/disconnect, radio power, and scanning run
   through `iwctl`. ANSI colour codes are stripped before parsing; RSSI is
   centi-dBm (`-2900` = `-29 dBm`).
3. **ConnMan** — `connmanctl state`, `technologies`, and `services` provide
   radio state and service lists. Known/open services connect/disconnect and
   scan through `connmanctl`. ConnMan needs its interactive agent for a new
   secured passphrase, so Pilo reports that instead of pretending to support it.
4. **wpa_supplicant** — a control socket found under `/run/wpa_supplicant` or
   `/var/run/wpa_supplicant` selects this backend. `wpa_cli status`,
   `list_networks`, and `scan_results` provide state and networks; known
   profiles use `select_network`, new networks use `add_network`/`set_network`.
   wpa_supplicant cannot power the radio off/on, so that toggle is disabled.
5. **Generic** — `/proc/net/route` gives the default-route interface, and
   `/sys/class/net/*` distinguishes Wi-Fi from wired links. This is read-only
   but distribution-neutral, so systemd-networkd, dhcpcd, netctl, and anything
   else still show the right connection state.

The topology/route poll runs every 5s. iwd details refresh every 15s; ConnMan
and wpa poll with their topology. Opening the panel refreshes and starts a scan
for the active backend. None of these paths install, start, stop, or reconfigure
the system's network manager.

## Bluetooth and audio backends

`BluetoothManager.qml` prefers `Quickshell.Bluetooth` and falls back to
`bluetoothctl show`, `devices Paired`, and `devices Connected` when Quickshell
has no adapter. Power and connect/disconnect go through the same BlueZ daemon;
BlueZ is the standard Linux Bluetooth stack, so there is no second daemon to
choose between.

`Audio.qml` is the only audio consumer of Quickshell services and owns the
`PwObjectTracker`. It prefers native PipeWire, then PulseAudio via `pactl`
(including pipewire-pulse), then ALSA via `amixer`. Pulse polling and ALSA
polling run every 2s only while PipeWire is unavailable. Fallback volume
changes are debounced 60ms so dragging the slider doesn't spawn a process per
pixel. Pulse output switching uses `pactl set-default-sink`; ALSA has a single
Master/PCM/Headphone control and no output list.

## State and settings

`Settings.qml` is a `FileView` + `JsonAdapter` at
`$XDG_STATE_HOME/quickshell/by-shell/<id>/settings.json`. The adapter's
properties are the settings; `onAdapterUpdated: writeAdapter()` persists them.
Keys: `chrome`, `shape`, `edge`, `opacity`, `rounding`, `attachEdges`,
`autoHide`, `autoHideDelay`, `overWindows`, `workspaceMode`, `launcherSort`,
`fileSearch`, `holidays`, `theme`, `layout` (bar widget arrangement), and
`usage` (per-app launch counts/timestamps). Old `hypr*` keys left in existing
files are ignored.
Clock/calendar keys: `clockFormat` (`24`/`12`/`custom`), `clockCustomFormat`,
`clockShow` (`time`/`datetime`/`daytime`/`daydatetime`), `clockDateFormat`,
`clockCustomDate`, `clockDayFormat` (`full`/`short`), `calendarWeekStart`
(`monday`/`sunday`), `calendarWeekNumbers`, `calendarHolidayFooter`.
`ClockFormat.qml` turns those into the bar string (and picks second precision
when a custom pattern contains `s`).
`resetAll()` restores the defaults;
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

## Chrome shape

`Settings.shape` (`rounded` default, `s-curve`, `bevel`) styles how the Centered
and Islands chrome meets the docked screen edge, and `Settings.attachEdges`
(default on) squares off the corners that sit on a screen edge. Corners that
touch no screen edge always round with `Settings.rounding`. `Bar.qml`'s
`cornerRadius(docked, side)` implements this for the `rounded` shape.

S-curve and Bevel are always drawn (not gated on `attachEdges`). When the bar is
attached, `attachEdges` squares only the docked corners that also sit on a
left/right screen edge: for islands that is the outer docked corner of the left
and right islands (`shapeLeftDocked`/`shapeRightDocked` on `BarShape`), while the
centre island and the inner corners keep the shape. `overhang` is how far the
shape flares past the body (`rounding` capped at half the bar height for S-curve,
the full bar height for Bevel) and `sideInset` insets the outer islands while
detached so a flare toward the screen edge is not clipped. Islands are always
flush — the old Gap is gone — so `rounded`, or an attached bar, uses the existing
`centeredBg`/group `Rectangle`s. For a custom shape, `widgets/BarShape.qml` draws
the block with `QtQuick.Shapes`/`PathSvg`: S-curve is a concave cove at the docked
corners with convex outer corners; Bevel is a straight flare that blends
tangentially into a rounded outer corner (the fillet is scaled so its corner cut
matches a plain rounded corner). Island shapes are drawn as unclipped siblings
behind the groups (the groups themselves are `clip: true`); the outer groups sit
at `sideInset` and `maxSideWidth` is reduced by it so they can't overlap the
centre.

## Theming

`Themes.qml` is the colour-scheme registry: a `presets` list of `{ id, name,
bg, fg, line, muted, teal, steel, error, warning, plus }`.
`Theme.qml` resolves `Themes.find(Settings.theme)` into its `readonly property
color` tokens, so every widget keeps its token names and repaints when the scheme
changes. Built-ins are **Vague** (default, the bar's original palette), **Gruvbox**,
**Frost**, **Everforest**, **Rosé Pine**, **Catppuccin** (Mocha), **Dracula**,
**Material**, and **Nord**. The settings window's **Theming** category renders each
preset as a card previewing its own colours; picking one writes `Settings.theme`,
persisted like every other setting and restored on login. `Settings.migrate()`
drops an unknown theme id back to the default.

Pilo's theme is deliberately scoped to the bar, notifications, KDE apps, and
foot. **Hyprland's look and feel is owned by HyprMod**, which writes its own
`~/.config/hypr/hyprland-gui.lua` and is loaded late by `hyprland.lua`. Pilo does
not write `lookandfeel.lua`, does not apply compositor colours, and has no
`hypr*` settings any more. The Theming category's **Look and feel** row probes
for `hyprmod` on `PATH` (or `~/.local/bin/hyprmod`) and launches it. An existing
`lookandfeel.lua` is left untouched as a static base loaded earlier.

A theme drives **KDE apps** (Dolphin): `KdeTheme.qml` writes a scheme to
`~/.local/share/color-schemes/Pilo-<theme>.colors` and applies it with
`plasma-apply-colorscheme`, which updates `~/.config/kdeglobals` and notifies the
session. KDE's role list is much larger than the bar's token set, so `KdeTheme`
derives window/view/button/selection/tooltip backgrounds and all foreground roles
from the palette (`shade()` lightens/darkens). `shell.qml` calls
`KdeTheme.apply()`; `KdeTheme` re-applies on
`Settings.onThemeChanged`. When `plasma-apply-colorscheme` is missing (no
`plasma-workspace`, e.g. Arch with only Dolphin) it falls back to
`scripts/kde-apply-colorscheme.sh`, which writes the same groups into
`kdeglobals` with `kwriteconfig6`. Either way, KDE apps only read those colours
when `plasma-integration` provides the KDE platform theme
(`QT_QPA_PLATFORMTHEME=kde`).

The **foot** terminal follows too: `FootTheme.qml` writes
`~/.config/foot/colors.ini` (generated, gitignored) with the active theme and
sends running foot instances `SIGUSR1` to reload (`foot` re-reads its config on
that signal). `foot.ini` includes the file from its `[main]` section
(`include=~/.config/foot/colors.ini`) and keeps only the structural options
(`alpha`, `blur`) in `[colors-dark]`. foot has a 16-colour ANSI palette, so the
bar tokens are mapped: black=`line`, red=`error`, green=`plus`, yellow=`warning`,
blue=`steel`, magenta=`teal`, cyan=a lightened `steel`, white=`fg`; brights are
lightened and `bright0`=`muted`; selection and cursor use `teal`.

Still future work: pibble, and a wallpaper-derived dynamic scheme (see
`FEATURE_REQUESTS.md` #1).

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
- **Custom app icons.** `RunningApps.qml` looks up `assets/icons/<class>.svg`
  (matched by window class, or its last dotted segment) and uses it when it
  exists, falling back to the desktop-entry icon. The bundled SVGs are drawn
  white so they read on the dark bar (OpenCode is inverted).
- **Monitors are configured in a separate file.** `hyprland.lua` no longer
  lists monitors; it does
  `for _, m in ipairs(require("monitors")) do hl.monitor(m) end`, reading
  `~/.config/hypr/monitors.lua`. `Displays.qml` (used by the settings app's
  Displays page) rewrites that file and applies changes live with
  `hyprctl keyword monitor`. The written file is treated as generated (see
  `.gitignore` in the dotfiles repo). Positions are logical layout pixels
  (`physical / scale`); the page's canvas draws each monitor to scale in that
  space and drags it in 2D, snapping edges/corners while dragging. Overlaps are
  allowed during the drag and resolved on drop: `resolveOverlaps()` keeps the
  dropped monitor fixed, chooses the drag axis (horizontal drags stay
  horizontal even on a full overlap), and shifts the whole group on each side
  of it only as far as needed. This preserves the arrangement within each side
  and makes inserting a display between two others behave like a slot rather
  than scattering monitors.

  `Displays.qml` reads `hyprctl monitors all -j` so disabled outputs remain in
  the model. The per-display **Enabled** toggle calls
  `hl.monitor({ output = ..., disabled = true/false })` through `hyprctl eval`
  (legacy `keyword monitor …,disable` does not work with the Lua config).
  Disabled outputs are hidden from the arrangement canvas but keep their card,
  position, mode, and scale; the generated `monitors.lua` entry gets
  `disabled = true`. Re-enabling restores the stored mode/position/scale.
  `activeMonitorCount`/`canSetEnabled()` prevent disabling the last active
  display. Reset uses `hyprctl eval` so it can re-enable outputs as well as
  restore preferred modes.
- **Hyprland look and feel is owned by HyprMod.** `hyprland.lua` loads
  `~/.config/hypr/hyprland-gui.lua` late, and HyprMod owns the editable
  compositor settings. Pilo only launches `hyprmod` from Theming. Any existing
  `~/.config/hypr/lookandfeel.lua` remains a static base loaded earlier; Pilo no
  longer regenerates it. If that file is deleted on a fresh setup,
  `hyprland.lua`'s `pcall(require, "lookandfeel")` fallback still applies.
- **`hyprctl keyword` is rejected for non-legacy options.** On 0.56
  `hyprctl keyword general:col.active_border …` prints "keyword can't work with
  non-legacy parsers. Use eval." and does nothing. Use
  `hyprctl eval 'hl.config({ … })'` for config changes; `Displays.qml` uses eval
  for monitor enable/disable/reset. `hyprctl keyword monitor` still works
  (legacy parser).
- **Super opens this launcher.** `hyprland.lua`'s `menu` variable is
  `qs -c pilo ipc call pilo toggle launcher`.
- **Layer rules.** `hyprland.lua` blurs `pilo-bar` and sets `no_anim` on
  `pilo-launcher`, `pilo-popup`, `pilo-identify`, and `pilo-notifications`. The
  `no_anim` is required: the config's `fadeLayers` animation runs at speed 60,
  which otherwise makes the overlays take ~4 seconds to fade in. Notification
  cards fade in themselves in QML.

## Process model

Prefer native Quickshell services; shell out only where needed.

| Concern | Source |
|---|---|
| Screens | `Quickshell.screens` |
| Workspaces | `Quickshell.Hyprland` for state; switching via `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'` |
| Clock | `SystemClock` |
| Apps | `DesktopEntries` |
| Files | `plocate` via `Process` |
| Network | `Network.qml`: NetworkManager native; iwd/ConnMan/wpa_supplicant CLIs; kernel route/link fallback |
| Bluetooth | `BluetoothManager.qml`: Quickshell/BlueZ, or `bluetoothctl` |
| Volume | `Audio.qml`: native PipeWire with `PwObjectTracker`, then `pactl`, then `amixer` |
| Power profile | `powerprofilesctl` via `Power.qml` |
| Holidays | `Holidays.qml` |
| Running apps | `hyprctl clients -j`; actions via `hyprctl dispatch 'hl.dsp…'` |
| Monitors | `Displays.qml`: `hyprctl monitors all -j`; `hyprctl keyword monitor` for active layout, `hyprctl eval` for enable/disable/reset |
| Hyprland look and feel | HyprMod (`hyprland-gui.lua`); launched from Theming |
| KDE apps | `KdeTheme.qml`: writes `~/.local/share/color-schemes/Pilo-*.colors`, applies with `plasma-apply-colorscheme` (fallback: `scripts/kde-apply-colorscheme.sh`) |
| foot terminal | `FootTheme.qml`: writes `~/.config/foot/colors.ini`, `pkill -USR1 -x foot` |
| Notifications | Quickshell `NotificationServer` in `Notifications.qml`; no external daemon |
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
- **Settings dropdowns use a Qt `Popup`.** `widgets/Dropdown.qml` opens a
  `QtQuick.Controls` `Popup`, which renders in the settings `FloatingWindow`
  overlay so it is not clipped by the settings `Flickable`. This is unrelated to
  the anchored bar panels above, which stay plain `PanelWindow` layers.
- **Panel heights follow content.** Long lists are capped (Wi-Fi 220, Bluetooth
  180, outputs 180, monitors 460, window menu 400) and scroll.
- **Bar sections cannot overlap.** The left and right groups are capped at
  `(barWidth - centerGroup.width) / 2 - 6` and `clip: true`, so a long section
  (e.g. many taskbar widgets) is clipped at the inner edge rather than running
  under the centered group.
- **`quickshell` state dir.** `Settings.qml` runs `mkdir -p` for the state dir
  at startup; the first launch logs a harmless "File does not exist" read
  warning until a setting is changed.
- **`Quickshell.Networking` is NetworkManager-only.** iwd and other stacks
  return no devices. Use `Network.qml` for status/actions; do not add a system
  network-manager dependency just to make the widget work. ConnMan's new
  passphrase flow and wpa_supplicant's radio power are deliberately limited.
- **Quickshell Bluetooth/Pipewire are single-backend too.** Use
  `BluetoothManager.qml` and `Audio.qml`; never bind widgets straight to
  `Bluetooth.*` or `Pipewire.*`. The fallbacks do not start or replace any
  daemon.
- **Pilo is the notification server.** It owns
  `org.freedesktop.Notifications`; do not start mako/dunst beside it, and do not
  instantiate a second `NotificationServer`. The Hyprland autostart no longer
  starts mako.
- **Notification history is deliberately out of scope.** There is no bell
  widget or history panel; toasts disappear when they expire or are dismissed.
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
- Add a notification capability/control: extend `NotificationCard.qml` and the
  matching `NotificationServer` support flag in `Notifications.qml` together.
  Do not advertise a capability the card cannot render.
- Add a settings category: a `ColumnLayout` in `settings/` built from
  `CategoryHeading` and `SettingRow`, wire it into `SettingsWindow.qml`
  (`categories`, `categoryComponent`, a `Component`), and add its settings to
  the `SettingsSearch` index. Row controls: `Segmented`, `Toggle`, `Slider`,
  `TextField`, or `Dropdown` for a compact select.
- Validate the Lua config after editing it:
  `luajit -bl ~/.config/hypr/hyprland.lua >/dev/null`, then
  `hyprctl reload` and `hyprctl configerrors`.
- Test input with `ydotool` (`mousemove -a -x … -y …`, `click 0xC0` left,
  `0xC1` right) and `wtype` for typing. A real mouse/touchpad is still the last
  word, especially for wheel input.
