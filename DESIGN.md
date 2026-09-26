# Pilo bar

Design for a Quickshell bar on Fedora + Hyprland. This replaces waybar. It does not replace pibble. The Super-tap launcher bind now opens this shell's launcher.

Inspiration is interaction, not a clone: anchored popups and short motion from Dank Material Shell and Noctalia, drawn in the existing vague.nvim palette.

## Environment

- Hyprland 0.56.2, Lua config at `~/.config/hypr/hyprland.lua` (fedup symlink).
- Quickshell 0.3.1. Launch with `qs -c pilo`.
- Three outputs, each 2560x1440, scale 1. A bar on every screen.
- Waybar is the current bar (`waybar.service` enabled, 32px top reserve). It goes away.
- pibble keeps notifications, volume flyout, wallpaper picker, clipboard, and Super+Space.
- Super tap opens the pilo launcher (was wofi). Super+Escape still opens `power-menu.sh`. pibble's Super+Space launcher is left as a second launcher.
- Tools already present: NetworkManager, BlueZ, PipeWire (`wpctl`), `powerprofilesctl`, `plocate`.

## Visual language

Match waybar. Do not introduce Material You or a lavender theme.

| Token | Value | Use |
|---|---|---|
| bg | `#141415` at 0.92 | Bar and panel fill |
| fg | `#cdcdcd` | Primary text and icons |
| line | `#252530` | Hairline, flush bottom rule |
| muted | `#606079` | Inactive workspace, secondary text |
| teal | `#b4d4cf` | Active workspace, clock, selected chip |
| steel | `#6e94b2` | Hover, links, focus ring |
| error | `#d8647e` | Urgent workspace, destructive confirm |
| warning | `#f3be7c` | Disconnect / weak signal |
| plus | `#7fa563` | Connected |

Font: FiraCode Nerd Font, 13px on the bar. App icons in the launcher come from the desktop entry (`IconImage`), not the nerd font.

Panels are the same surface as the bar: `#141415` at 0.92, 8px radius, 1px `#252530` border. Hyprland blurs the layer. No drop shadow drawn in QML.

Motion is short and only on change. 160–200ms, OutCubic. Popups fade and travel 8px from the widget that opened them. The active workspace mark slides. No looping shaders, no idle animation.

## Bar

One `PanelWindow` per screen via `Variants` over `Quickshell.screens`. Layer namespace `pilo-bar`, layer Top. `exclusiveZone` equals the reserved strip so windows do not slide under it.

Default chrome is flush attached, matching the current waybar:

- Edge: top
- Height: 32
- Radius: 0
- Margin: 0
- Bottom rule: 2px `#252530`
- Horizontal padding inside the bar: 8px

Three sections. Left and right are packed to their edges; the centre holds the workspaces.

### Left

1. Launcher icon. Nerd-font app-grid glyph. Click toggles the launcher on that screen.
2. **Running apps.** One icon per running application, grouped by class, across all workspaces and monitors; the focused app is underlined. Left-click focuses a single-window app, or opens the menu when the app has several windows. Right-click opens the menu (windows plus the app's Desktop Entry actions). More than six apps collapse into a `+N` chip that opens the overflow menu.

### Center

Workspaces 1–10. These are the global ids bound to Super+1…0, not a per-monitor renumber. Special workspace `magic` is hidden.

Each workspace is a number. Empty is muted. Occupied is fg. Active is teal with a 2px underline that slides between ids. Urgent is error. Click switches to it. Scroll is not bound.

Workspace display has two modes, switched in bar settings:

- **All** (default): always show 1–10.
- **Occupied**: show occupied workspaces plus the active one. Never show an empty strip.

### Right

The right cluster is, left to right:

1. **Clock.** `HH:mm`, 24-hour, no seconds. `SystemClock` precision is Minutes. Colour teal, weight bold. Click toggles the calendar on that screen. No date on the bar; the date lives in the calendar header.
2. **Monitors.** Screen glyph. Opens the monitors panel.
3. **Network + Bluetooth.** One icon. It shows the primary link (ethernet, or wifi strength). A small teal pip sits on the icon when a Bluetooth device is connected. Click toggles the network panel.
4. **Sound.** One icon. Glyph follows mute and volume. Click toggles the sound panel. Scroll on the icon changes the default sink by 5%, matching the media-key step, clamped to 100%.
5. **Settings.** Gear. Click toggles bar settings. It does not open the sound or network panels.

Only one panel is open at a time. Opening one closes the others, including the launcher and calendar. Click outside closes the open panel. Panels are not pinned and are not always visible.

## Panels

Anchored panels live in one `PanelWindow` overlay per screen (`exclusiveZone: -1`, layer Overlay), anchored to all edges but with a margin on the bar's edge so it stops at the bar strip and never covers the bar. Each panel card is positioned under the widget that opened it, 6px below the bar, clamped to the screen. A `MouseArea` behind the cards closes the panel on an outside click; `PanelCard` swallows clicks on empty card space so they do not dismiss it. This replaced `PopupWindow` + `HyprlandFocusGrab`, which under Hyprland dismissed the panel on the first click instead of letting the widgets receive it. The launcher is a second, full-screen overlay, centered on the screen.

### Launcher

Two presentations. Clicking the bar icon opens it anchored under the icon (about 460×520), like the other panels, with the bar still clickable. Tapping Super or the IPC `toggle launcher` opens the centered spotlight (about 680×560). In both, the search field is focused on open and cleared when it closes. The scope chips (**Apps | Files**) sit on the left, the sort chips on the right.

Search matches applications by name, generic name, and keywords (`DesktopEntries`). A **Files** chip switches the result list to `plocate`. It is hidden when file search is off in bar settings, and shows a "plocate not installed" note if the binary is missing. Tab toggles between the applications and files scopes. File hits open with `xdg-open`. Application hits launch the desktop entry and record a use.

Scope chips: **Apps**, **Files**. Sort chips, apps only: **Name**, **Recent**, **Frequent** (default), right-aligned. Counts and last-used times persist locally. Files are sorted by path and ignore the sort chips.

Results are a scrolling list: icon, name, and a muted comment or path. Keyboard: type to filter, Up/Down to move, Enter to activate, Escape to close.

Footer, always visible:

| Button | Action | Confirm |
|---|---|---|
| Shutdown | `systemctl poweroff` | yes |
| Reboot | `systemctl reboot` | yes |
| Sign out | `hyprctl dispatch 'hl.dsp.exit()'` | no |
| Suspend | `systemctl suspend` | yes |

Confirm replaces the footer with the action name plus Cancel and Confirm. Escape cancels. No lock button. No user-switching.

### Calendar

Drops from the clock. Header is the weekday and full date. Body is one month grid. Today is teal. Days outside the month are muted. The arrow buttons, the Left/Right arrow keys, and the scroll wheel change the visible month and do not change the clock. A fixed-height footer line shows the holiday name for the hovered day, or today's if none is hovered, without reflowing the grid.

Holidays are drawn from `Holidays.qml`, a singleton that computes dates per region (movable feasts included via the Gregorian computus). Regions: **None**, **Sweden** (default). Holiday dates are warning-coloured with a dot. Only Swedish holidays are defined; the region switch and `forYear(year, region)` shape are set up so more regions can be added later. No external calendars, no event list, no week numbers.

### Network and Bluetooth

Drops from the network icon. Two stacked sections, not two windows.

**Network.** Radio toggle. Current connection name (SSID or "Ethernet"). Scrollable network list: signal, security, connected mark. Click a known network to connect. A secured unknown network reveals a password field and a Connect button. Ethernet has no scan list; it shows link state only.

**Bluetooth.** Power toggle. Paired devices with connect / disconnect. No pairing wizard in this version. Scanning for new devices is out of scope.

### Sound

Drops from the sound icon. In order:

- Sink name, muted if nothing is default.
- Mute toggle.
- Volume slider, 0–100, same sink the scroll action uses.
- Output device list, if more than one sink exists. Click sets the default.

### Power profile

A row in bar settings, not the sound panel, and not its own bar icon:

`Power profile:  Battery | Balanced | Performance`

One of the three is selected. Click sets it immediately. No confirm.

| Label | `powerprofilesctl` value |
|---|---|
| Battery | `power-saver` |
| Balanced | `balanced` |
| Performance | `performance` |

Set and read through `powerprofilesctl` (see `Power.qml`), because Quickshell 0.3.1's UPower `PowerProfiles` setter updates its own value but never reaches the daemon. The read-back after setting keeps the UI honest if the daemon rejects a change (this machine's `amd_pstate` rejects power-saver and performance). Hide Performance when it is not listed.

### Bar settings

Drops from the gear. Changes apply immediately and persist.

| Setting | Values | Default |
|---|---|---|
| Chrome | Flush, Pill, Islands | Flush |
| Edge | Top, Bottom | Top |
| Opacity | 0.6–1.0, step 0.05 | 0.92 |
| Gap | 0–24px | 8 |
| Workspaces | All, Occupied | All |
| Holidays | None, Sweden | Sweden |
| Launcher sort | Name, Recent, Frequent | Frequent |
| File search | On, Off | On |

Chrome modes:

- **Flush.** The default above. Square, edge-to-edge, 2px rule on the inner edge.
- **Pill.** One detached bar. The `Gap` setting is the outer margin, 14px radius, no edge rule. `exclusiveZone` is height plus the margin on the screen edge.
- **Islands.** The strip is transparent and still reserves space. Three capsules (left group, clock, right group), 14px radius, `Gap` from the screen edge and between groups. Each capsule uses the bar fill.

No accent picker, no font picker, no plugin list. The palette stays fixed.

### Monitors

Drops from the monitor icon. One card per output, ordered left to right: name,
resolution, current refresh, move-left / move-right arrows, a refresh chooser
(the refresh rates available at the current resolution) and a scale chooser
(Auto, 1x … 2x). A Reset action sets every output to preferred / auto / auto.

Any change applies live with `hyprctl keyword monitor` and rewrites
`~/.config/hypr/monitors.lua`, which `hyprland.lua` loads. The layout origin is
preserved for refresh/scale changes so the desktop does not jump; arranging
re-anchors to the new leftmost monitor. Vertical arrangement, rotation, VRR,
bit depth, HDR, and mirroring are out of scope.

### Running apps

The window menu, opened from a taskbar icon (right-click, or left-click when the app has several windows) or the `+N` overflow chip. It lists that app's windows, each with the title, workspace and monitor, plus **Close** and **Kill**. Clicking a row focuses that window and closes the menu. Close asks the window to quit (`hl.dsp.window.close`); Kill force-terminates it (`hl.dsp.window.kill`, SIGKILL) for apps that ignore a close request. Focus works across workspaces and monitors. The model is rebuilt from `hyprctl clients -j` on Hyprland events.

For a single app, an **Actions** section lists that application's Desktop Entry actions (`DesktopEntry.actions`, the same jump list KDE's task manager shows — e.g. Steam's Store / Library / Friends, or Firefox's New Window / New Private Window). Clicking one runs it.

## Persistence

`JsonAdapter` in the shell state directory. Stored keys: chrome, edge, opacity, gap, workspace mode, launcher sort, file search enabled, holidays region, and the per-app use count plus last-used timestamp. Missing file means the defaults in the table above.

## Process model

Native Quickshell services first. Shell out only where the service does not cover the action.

| Concern | Source |
|---|---|
| Screens | `Quickshell.screens` |
| Workspaces | `Quickshell.Hyprland` for state; switching uses `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'` (the Lua config rejects the classic dispatcher) |
| Clock | `SystemClock` |
| Apps | `DesktopEntries` |
| Files | `plocate` via `Process` |
| Network | `Quickshell.Networking` |
| Bluetooth | `Quickshell.Bluetooth` |
| Volume | `Quickshell.Services.Pipewire` (nodes kept live by a `PwObjectTracker`) |
| Power profile | `powerprofilesctl` via `Power.qml` |
| Holidays | `Holidays.qml` |
| Monitors | `hyprctl monitors -j` to read, `hyprctl keyword monitor` to apply, and a rewrite of `monitors.lua` to persist |
| Running apps | `hyprctl clients -j` (rebuilt on Hyprland events); focus/close/kill via `hyprctl dispatch 'hl.dsp…'` |
| Session | `systemctl` / `hyprctl`, same commands as `power-menu.sh` |

Do not start a notification server. pibble owns `org.freedesktop.Notifications`.

An `IpcHandler` exposes `toggle launcher`, `toggle calendar`, `toggle network`, `toggle sound`, `toggle settings`, and `toggle monitors`, targeted at the focused screen. No Hyprland bind is added for these. They exist so a bind can be attached later without rewriting the shell.

## Files

```
~/.config/quickshell/pilo/
  DESIGN.md          this document
  REMINDERS.md       open review fixes
  FEATURE_REQUESTS.md  longer-form feature ideas
  shell.qml          ShellRoot, IPC, settings load
  Theme.qml          palette, type, motion
  Settings.qml       persisted settings singleton
  Panels.qml         which panel is open and on which screen
  Power.qml          power profile via powerprofilesctl
  Holidays.qml       holiday dates per region
  RunningApps.qml    running windows model + focus/close/kill actions
  Bar.qml            per-screen PanelWindow, sections, panel overlays
  widgets/
    BarButton.qml    icon button (glyph, hover, pip, wheel)
    LauncherButton.qml
    Workspaces.qml
    Clock.qml
    NetworkButton.qml
    SoundButton.qml
    SettingsButton.qml
    MonitorsButton.qml
    Taskbar.qml      running-app icons + overflow
    PanelCard.qml    shared panel surface
    Segmented.qml    segmented control
    Slider.qml
    Toggle.qml
    ActionButton.qml
  panels/
    AppLauncher.qml
    CalendarPanel.qml
    NetworkPanel.qml
    SoundPanel.qml
    SettingsPanel.qml
    MonitorsPanel.qml
    WindowsMenu.qml
```

Singletons use `pragma Singleton`. Imports are `qs.*` module imports, not `root:` imports.

## Hyprland integration

In `hyprland.lua`:

1. Replace `systemctl --user start waybar.service` with `qs -c pilo -n` (`-n` exits a duplicate on reload).
2. Layer rule for `^pilo-bar$`: blur on, `ignore_alpha` 0.2, `no_anim` true. Same treatment as `blur-waybar`.
3. Layer rules for `^pilo-launcher$` and `^pilo-popup$`: `no_anim` true, no blur. The compositor's `fadeLayers` animation runs at speed 60, which made the full-screen overlays take ~4s to fade in; `no_anim` shows them instantly. Neither gets blur: both are full-screen, so blurring them would frost the whole desktop.
4. Point the Super-tap launcher at this shell: `menu = "qs -c pilo ipc call pilo toggle launcher"` (was `wofi --show drun`). The `SUPER + SUPER_L` release bind is unchanged.
5. Monitor setup moved out of `hyprland.lua` into `monitors.lua`, loaded with `for _, m in ipairs(require("monitors")) do hl.monitor(m) end`. The Monitors widget rewrites that file, so fedup should treat it as generated (or gitignore it).

Then:

```
systemctl --user disable --now waybar.service
```

The unit is enabled today. Disabling it stops a later login from starting waybar beside this bar.

Do not edit pibble autostart, wallpaper, or cliphist. Other Super binds are left alone.

## Out of scope

- Lock screen
- Notification daemon or history
- System tray
- Media player widget
- Bluetooth pairing wizard
- External calendars
- Wallpaper theming or matugen
- Replacing pibble or `power-menu.sh` (the wofi Super-tap launcher is replaced)
- Per-monitor workspace renumbering

## Done when

- Flush bar is on all three screens and reserves 32px at the top.
- Waybar is not running and is not enabled.
- Clock is 24-hour `HH:mm` and opens a month calendar whose arrows, arrow keys, and wheel change the month, with holiday marks and a footer that never reflows the grid.
- Launcher appears instantly, searches apps, can search files through plocate, defaults to frequent, toggles scope with Tab, hides the Files chip when file search is off, and the footer can shut down, reboot, sign out, and suspend.
- Tapping Super opens the launcher.
- Every widget in the launcher, calendar, network, sound, and settings panels receives clicks and acts on them.
- Network icon opens one panel with network and Bluetooth.
- Sound icon opens one panel for volume and output selection.
- Monitor icon opens a panel that arranges outputs left/right, sets refresh rate and scale, applies live, and persists to `monitors.lua`.
- Running apps show as icons across all workspaces and monitors; right-click (or the `+N` chip) opens a menu that can focus, close, or force-kill each window, plus run the app's Desktop Entry actions (jump list).
- Power profile is a row in bar settings, set through `powerprofilesctl`.
- Gear switches chrome among Flush, Pill, and Islands, adjusts the gap, and the choices survive a restart.
- Opening any panel closes whichever panel was already open.
