# Pilo bar — feature requests

Longer-form ideas, separate from the review fixes in `REMINDERS.md`. New
requests get appended here.

---

## 1. Settings app instead of a settings widget

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
