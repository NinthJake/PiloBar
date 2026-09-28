# Pilo bar

![Pilo bar preview](assets/preview.png)

A desktop status bar for Hyprland. It sits on every monitor and replaces the
old bar, while notifications, the wallpaper picker, and the clipboard keep
working as before.

## The bar

Three sections, left to right:

**Left**
- **Launcher** — opens the application launcher.
- **Running apps** — icons for everything you have open.

**Center**
- **Workspaces** — the 1–10 workspaces. Click a number to switch. The active
  one is highlighted and underlined; occupied ones are brighter. You can show
  all ten or only the ones in use (bar settings).

**Right**
- **Clock** — 24-hour time. Click it to open the calendar.
- **Network & Bluetooth** — connection status and controls.
- **Sound** — volume and output device.
- **Settings** — customize the bar and arrange your screens.

Only one panel is open at a time. Click anywhere else to close it.

## Launcher

Two ways to open it:
- **Click the launcher icon** on the bar — it appears right under the icon.
- **Tap Super** — it opens as a centered window.

Type to search your applications, or switch to searching files. Results can be
sorted by name, most recently used, or most frequently used. Press **Tab** to
switch between apps and files. The buttons along the bottom let you shut down,
reboot, sign out, or suspend; the destructive ones ask for confirmation first.
The search box is empty every time it opens.

## Calendar

Opens under the clock. Move between months with the arrows, the left/right
arrow keys, or the scroll wheel. Today is highlighted. Swedish holidays are
marked in amber; turn them off, or back on, in bar settings. Hovering a holiday
shows its name at the bottom.

## Control panels

- **Network & Bluetooth** — toggle Wi-Fi, pick a network, connect to a new one,
  and connect or disconnect paired Bluetooth devices.
- **Sound** — adjust volume, mute, and choose the output device.
- **Settings** — opens the separate Pilo Settings window (see below), including
  the **Displays** page for arranging and identifying screens.

## Running apps

Icons for everything you have open, across all workspaces and monitors, grouped
by application. The focused app is underlined. More than a handful of apps
collapse into a `+N` button.

- **Left-click** an app to bring it to the front (if it has more than one
  window, you get the menu instead).
- **Right-click** an app for its menu: each window can be focused, closed
  politely, or force-killed (useful for apps that ignore the close button).
  You also get the application's own quick actions, like Steam's
  Store / Library / Friends or Firefox's New Private Window.

## Customizing the bar

Open the gear icon for **Pilo Settings** — a regular desktop window with a
category sidebar and search. Everything applies instantly and is saved.

- **Bar** — *Chrome* (Flush, Pill, Islands), *Edge* (top or bottom), *Opacity*,
  *Gap*, and *Workspaces* (all ten, or only occupied).
- **Displays** — drag the screen cards left or right to set how your monitors
  are arranged, and set each screen's *refresh rate* and *scale*. **Identify**
  flashes a big number on each screen so you can tell which one is which;
  *Reset* restores the recommended settings. Changes apply immediately and are
  saved to `monitors.lua`.
- **Widgets** — choose what sits in the **Left**, **Center**, and **Right**
  sections and in what order. Drag a widget from the **Available widgets**
  palette at the bottom into a column to add it, drag rows to reorder or move
  them between columns, or drop a row back on the palette to remove it. Each
  column's **+** opens a list to add from, and *Reset layout* restores the
  default arrangement.
- **Launcher** — the default result *sort* and *file search*.
- **Calendar** — the *holidays* region.
- **System** — the *power profile* (Battery, Balanced, Performance).
- **Advanced** — the settings file location, export or import a backup, and
  reset everything to defaults.

The search box at the top of the sidebar matches across every category and
jumps straight to the setting you pick.

## Good to know

- The bar appears on every connected screen.
- If a Left or Right section holds more widgets than fit around the centre, the
  extra widgets are clipped instead of overlapping the workspaces.
- Your preferences and your app usage history are saved between sessions.
- The layout is meant to feel consistent with the rest of the desktop: it is
  dark, understated, and keyboard-friendly.
