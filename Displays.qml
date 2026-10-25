pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Monitor model + actions. Arrange monitors in 2D (drag), change resolution,
// refresh rate and scale. Positions are logical pixels (physical size / scale),
// which is the space Hyprland lays monitors out in. Live-applies via `hyprctl
// keyword monitor` and persists by rewriting monitors.lua, which hyprland.lua
// loads with require(). Shared by the settings app's Displays category and the
// identify overlay.
Singleton {
    id: root

    // [{ name, width, height, refreshRate, scale, x, y, availableModes, disabled }]
    property var monitors: []
    // name -> { x, y } logical top-left
    property var arrangement: ({})
    property var resolutionPick: ({})
    property var refreshPick: ({})
    property var scalePick: ({})
    property var fileScales: ({})
    property bool identifyActive: false

    readonly property string monitorsPath: String(Quickshell.env("HOME")) + "/.config/hypr/monitors.lua"

    readonly property var scaleOptions: [
        { key: "auto", label: "Auto" },
        { key: "1", label: "1x" },
        { key: "1.25", label: "1.25x" },
        { key: "1.5", label: "1.5x" },
        { key: "1.75", label: "1.75x" },
        { key: "2", label: "2x" }
    ]

    // Stable display identity: output names sort the same way regardless of
    // where the monitor is dragged. IDs and the settings cards use this order;
    // physical arrangement is represented separately by `arrangement`.
    readonly property var stableOrder: {
        let names = []
        for (let i = 0; i < monitors.length; i++)
            names.push(monitors[i].name)
        names.sort((p, q) => p.localeCompare(q))
        return names
    }

    readonly property int activeMonitorCount: {
        let count = 0
        for (let i = 0; i < monitors.length; i++) {
            if (!monitors[i].disabled)
                count++
        }
        return count
    }

    function canSetEnabled(name) {
        const monitor = monitorByName(name)
        if (!monitor)
            return false
        return monitor.disabled || activeMonitorCount > 1
    }

    function monitorByName(name) {
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === name)
                return monitors[i]
        }
        return null
    }

    function roundRefresh(v) {
        return Math.round(v)
    }

    // ── resolution ──────────────────────────────────────────

    // Unique "WxH" values the monitor supports, largest first.
    function resolutionOptions(name) {
        const m = monitorByName(name)
        if (!m)
            return []
        const seen = {}
        let out = []
        for (let i = 0; i < m.availableModes.length; i++) {
            const mode = m.availableModes[i]
            const at = mode.indexOf("@")
            if (at < 0)
                continue
            const dim = mode.substring(0, at)
            if (seen[dim])
                continue
            seen[dim] = true
            out.push({ key: dim, label: dim })
        }
        out.sort((a, b) => {
            const pa = a.key.split("x")
            const pb = b.key.split("x")
            return (parseInt(pb[0]) * parseInt(pb[1])) - (parseInt(pa[0]) * parseInt(pa[1]))
        })
        return out
    }

    function resolutionKey(name) {
        if (resolutionPick[name] !== undefined)
            return String(resolutionPick[name])
        const m = monitorByName(name)
        return m ? (m.width + "x" + m.height) : ""
    }

    function resolutionSize(name) {
        const parts = String(resolutionKey(name)).split("x")
        const w = parseInt(parts[0])
        const h = parseInt(parts[1])
        if (!w || !h) {
            const m = monitorByName(name)
            return { w: m ? m.width : 0, h: m ? m.height : 0 }
        }
        return { w: w, h: h }
    }

    // Unique refresh rates available at the picked resolution.
    function refreshOptions(name) {
        const m = monitorByName(name)
        if (!m)
            return []
        const needle = resolutionKey(name) + "@"
        const seen = {}
        let out = []
        for (let i = 0; i < m.availableModes.length; i++) {
            const mode = m.availableModes[i]
            if (mode.indexOf(needle) !== 0)
                continue
            const hz = parseFloat(mode.substring(needle.length))
            if (isNaN(hz))
                continue
            const key = String(Math.round(hz * 100) / 100)
            if (seen[key])
                continue
            seen[key] = true
            out.push({ key: key, label: key + " Hz" })
        }
        out.sort((a, b) => parseFloat(b.key) - parseFloat(a.key))
        return out
    }

    function refreshKey(name) {
        if (refreshPick[name] !== undefined)
            return String(refreshPick[name])
        const m = monitorByName(name)
        if (!m)
            return ""
        const opts = refreshOptions(name)
        if (opts.length === 0)
            return String(roundRefresh(m.refreshRate))
        const size = resolutionSize(name)
        // On the monitor's real resolution, keep the current rate; on a newly
        // picked resolution, default to its highest.
        const target = (size.w === m.width && size.h === m.height) ? m.refreshRate : parseFloat(opts[0].key)
        let best = opts[0].key
        let bestDiff = Infinity
        for (let i = 0; i < opts.length; i++) {
            const diff = Math.abs(parseFloat(opts[i].key) - target)
            if (diff < bestDiff) {
                bestDiff = diff
                best = opts[i].key
            }
        }
        return best
    }

    // "WxH@Hz" for the monitor's picked resolution and refresh.
    function modeFor(name) {
        return resolutionKey(name) + "@" + refreshKey(name)
    }

    function scaleKey(name) {
        if (scalePick[name] !== undefined)
            return String(scalePick[name])
        if (fileScales[name] !== undefined)
            return String(fileScales[name])
        const m = monitorByName(name)
        return m ? String(m.scale) : "1"
    }

    function effectiveScale(name) {
        const key = scaleKey(name)
        if (key !== "auto" && !isNaN(parseFloat(key)))
            return parseFloat(key)
        const m = monitorByName(name)
        return m ? m.scale : 1
    }

    // Logical (layout) size: the picked resolution divided by the scale.
    function logicalWidth(name) {
        return Math.round(resolutionSize(name).w / effectiveScale(name))
    }

    function logicalHeight(name) {
        return Math.round(resolutionSize(name).h / effectiveScale(name))
    }

    // 1-based id shown in the settings list and the identify overlay. It is
    // tied to the output name, not its current position, so dragging a display
    // never renumbers the others. 0 when the monitor is not known yet.
    function idFor(name) {
        return stableOrder.indexOf(name) + 1
    }

    function positionOf(name) {
        const p = arrangement[name]
        if (p)
            return p
        const m = monitorByName(name)
        return m ? { x: m.x, y: m.y } : { x: 0, y: 0 }
    }

    function _rectOf(name, x, y) {
        return { x: x, y: y, w: logicalWidth(name), h: logicalHeight(name) }
    }

    // Snap the dragged monitor's edges and corners to the other monitors,
    // within `tol` logical px. x and y snap independently, so aligning both
    // gives corner snapping.
    function snapPosition(name, x, y, tol) {
        const w = logicalWidth(name)
        const h = logicalHeight(name)
        let bx = x
        let by = y
        let bestDx = tol + 1
        let bestDy = tol + 1
        for (let i = 0; i < monitors.length; i++) {
            const o = monitors[i]
            if (o.name === name || o.disabled)
                continue
            const p = positionOf(o.name)
            const ow = logicalWidth(o.name)
            const oh = logicalHeight(o.name)
            const xs = [p.x, p.x + ow - w, p.x + ow, p.x - w]
            for (let j = 0; j < xs.length; j++) {
                const d = Math.abs(xs[j] - x)
                if (d < bestDx) {
                    bestDx = d
                    bx = xs[j]
                }
            }
            const ys = [p.y, p.y + oh - h, p.y + oh, p.y - h]
            for (let j = 0; j < ys.length; j++) {
                const d = Math.abs(ys[j] - y)
                if (d < bestDy) {
                    bestDy = d
                    by = ys[j]
                }
            }
        }
        return {
            x: Math.round(bestDx <= tol ? bx : x),
            y: Math.round(bestDy <= tol ? by : y)
        }
    }

    function _clonePositions(src) {
        let out = {}
        for (const k in src)
            out[k] = { x: src[k].x, y: src[k].y }
        return out
    }

    function layoutAxis(pos) {
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].disabled)
                continue
            const p = pos[monitors[i].name]
            if (!p)
                continue
            const r = _rectOf(monitors[i].name, p.x, p.y)
            minX = Math.min(minX, r.x)
            minY = Math.min(minY, r.y)
            maxX = Math.max(maxX, r.x + r.w)
            maxY = Math.max(maxY, r.y + r.h)
        }
        if (!isFinite(minX))
            return "x"
        return (maxX - minX) >= (maxY - minY) ? "x" : "y"
    }

    // Keep the dropped monitor where it is and move whole groups on each side
    // of it just far enough to clear it. This preserves the existing layout
    // within each side, makes a monitor dropped between two others slot in
    // cleanly, and avoids the old pairwise solver's oscillation and its habit
    // of separating fully-overlapping displays vertically.
    //
    // `axisHint` is "x" or "y" from the drag direction; `anchorDelta` is the
    // signed movement along that axis. They disambiguate a monitor dropped
    // exactly on top of another one. Without a hint, choose the layout's
    // dominant axis (row vs column).
    function resolveOverlaps(src, anchorName, axisHint, anchorDelta) {
        let pos = _clonePositions(src)
        if (!anchorName || !pos[anchorName])
            return pos

        const axis = (axisHint === "x" || axisHint === "y") ? axisHint : layoutAxis(pos)
        const horizontal = axis === "x"
        const anchor = pos[anchorName]
        const ar = _rectOf(anchorName, anchor.x, anchor.y)
        const anchorStart = horizontal ? ar.x : ar.y
        const anchorEnd = horizontal ? ar.x + ar.w : ar.y + ar.h
        const anchorCenter = (anchorStart + anchorEnd) / 2
        const delta = Number(anchorDelta) || 0

        let left = []
        let right = []
        for (let i = 0; i < monitors.length; i++) {
            const name = monitors[i].name
            if (name === anchorName || monitors[i].disabled)
                continue
            const p = pos[name]
            if (!p)
                continue
            const r = _rectOf(name, p.x, p.y)
            const perpOverlap = horizontal
                ? Math.min(ar.y + ar.h, r.y + r.h) - Math.max(ar.y, r.y)
                : Math.min(ar.x + ar.w, r.x + r.w) - Math.max(ar.x, r.x)
            if (perpOverlap <= 0)
                continue

            const center = horizontal ? (r.x + r.w / 2) : (r.y + r.h / 2)
            let side = center < anchorCenter ? -1 : 1
            // Equal centres mean a full overlap (common when snapping one
            // display exactly onto another). Use the drag direction: a monitor
            // dragged left inserts before the one it covers, so that one moves
            // right, and vice versa.
            if (Math.abs(center - anchorCenter) < 0.001 && delta !== 0)
                side = delta < 0 ? 1 : -1
            if (side < 0)
                left.push(name)
            else
                right.push(name)
        }

        let shiftLeft = 0
        let shiftRight = 0
        for (let i = 0; i < left.length; i++) {
            const p = pos[left[i]]
            const r = _rectOf(left[i], p.x, p.y)
            const overlap = (horizontal ? r.x + r.w : r.y + r.h) - anchorStart
            if (overlap > shiftLeft)
                shiftLeft = overlap
        }
        for (let i = 0; i < right.length; i++) {
            const p = pos[right[i]]
            const r = _rectOf(right[i], p.x, p.y)
            const overlap = anchorEnd - (horizontal ? r.x : r.y)
            if (overlap > shiftRight)
                shiftRight = overlap
        }

        for (let i = 0; i < left.length; i++) {
            if (horizontal)
                pos[left[i]].x -= shiftLeft
            else
                pos[left[i]].y -= shiftLeft
        }
        for (let i = 0; i < right.length; i++) {
            if (horizontal)
                pos[right[i]].x += shiftRight
            else
                pos[right[i]].y += shiftRight
        }

        // The side-group pass handles the normal drag case without moving
        // anything twice. A monitor in an adjacent row can still be nudged
        // into another one in a complex 2D layout, so make a final minimal pass
        // that moves only one monitor per overlap and never moves the anchor.
        pos = resolveResidualOverlaps(pos, anchorName, horizontal ? "x" : "y")

        let out = {}
        for (const k in pos)
            out[k] = { x: Math.round(pos[k].x), y: Math.round(pos[k].y) }
        return out
    }

    function resolveResidualOverlaps(pos, anchorName, axisHint) {
        let names = []
        for (let i = 0; i < monitors.length; i++) {
            if (!monitors[i].disabled && pos[monitors[i].name])
                names.push(monitors[i].name)
        }

        for (let iter = 0; iter < 200; iter++) {
            let changed = false
            for (let i = 0; i < names.length; i++) {
                for (let j = i + 1; j < names.length; j++) {
                    const an = names[i]
                    const bn = names[j]
                    const ra = _rectOf(an, pos[an].x, pos[an].y)
                    const rb = _rectOf(bn, pos[bn].x, pos[bn].y)
                    const ox = Math.min(ra.x + ra.w, rb.x + rb.w) - Math.max(ra.x, rb.x)
                    const oy = Math.min(ra.y + ra.h, rb.y + rb.h) - Math.max(ra.y, rb.y)
                    if (ox <= 0 || oy <= 0)
                        continue

                    changed = true
                    let axis
                    if (an === anchorName || bn === anchorName)
                        axis = axisHint === "x" || axisHint === "y" ? axisHint : (ox <= oy ? "x" : "y")
                    else
                        axis = ox <= oy ? "x" : "y"
                    const amount = axis === "x" ? ox : oy

                    let mover
                    let other
                    if (an === anchorName) {
                        mover = bn
                        other = an
                    } else if (bn === anchorName) {
                        mover = an
                        other = bn
                    } else {
                        const anchor = pos[anchorName]
                        const ar = anchor ? _rectOf(anchorName, anchor.x, anchor.y) : null
                        const anchorCenter = ar
                            ? (axis === "x" ? ar.x + ar.w / 2 : ar.y + ar.h / 2)
                            : 0
                        const ac = axis === "x" ? ra.x + ra.w / 2 : ra.y + ra.h / 2
                        const bc = axis === "x" ? rb.x + rb.w / 2 : rb.y + rb.h / 2
                        if (Math.abs(ac - anchorCenter) > Math.abs(bc - anchorCenter)) {
                            mover = an
                            other = bn
                        } else {
                            mover = bn
                            other = an
                        }
                    }

                    const mr = _rectOf(mover, pos[mover].x, pos[mover].y)
                    const or = _rectOf(other, pos[other].x, pos[other].y)
                    const mc = axis === "x" ? mr.x + mr.w / 2 : mr.y + mr.h / 2
                    const oc = axis === "x" ? or.x + or.w / 2 : or.y + or.h / 2
                    const moveNegative = mc < oc || (Math.abs(mc - oc) < 0.001 && mover === bn)
                    if (axis === "x")
                        pos[mover].x += moveNegative ? -amount : amount
                    else
                        pos[mover].y += moveNegative ? -amount : amount
                }
            }
            if (!changed)
                break
        }
        return pos
    }

    function buildLua(pos) {
        let lines = [
            "-- Monitor configuration.",
            "--",
            "-- Managed by the pilo settings app (Displays). It can be edited by hand;",
            "-- it is rewritten when monitors are arranged, or their resolution, scale",
            "-- or refresh rate is changed. hyprland.lua loads it with require().",
            "--",
            "-- Fields match hl.monitor(): output, mode (\"WxH@Hz\"), position (\"XxY\"",
            "-- logical layout coords), scale (\"auto\" or a number), and",
            "-- disabled = true for outputs switched off in the Displays page.",
            "return {"
        ]
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i]
            const p = pos[m.name]
            if (!p)
                continue
            let fields = 'output = "' + m.name + '", mode = "' + modeFor(m.name) + '", position = "' + Math.round(p.x) + 'x' + Math.round(p.y) + '", scale = "' + scaleKey(m.name) + '"'
            if (m.disabled)
                fields += ", disabled = true"
            lines.push('    { ' + fields + ' },')
        }
        lines.push("}")
        return lines.join("\n") + "\n"
    }

    // Apply a whole arrangement live and persist it.
    function applyArrangement(pos) {
        if (monitors.length === 0)
            return
        const arr = _clonePositions(pos)
        let script = ""
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i]
            const p = arr[m.name]
            if (!p || m.disabled)
                continue
            const spec = m.name + "," + modeFor(m.name) + "," + Math.round(p.x) + "x" + Math.round(p.y) + "," + scaleKey(m.name)
            script += "hyprctl keyword monitor '" + spec + "' ; "
        }
        if (script.length > 0) {
            applyProc.command = ["sh", "-c", script]
            applyProc.running = true
        }
        writeConfig(arr)
        arrangement = arr
    }

    function writeConfig(pos) {
        Quickshell.execDetached(["sh", "-c", "cat > '" + monitorsPath + "' <<'PILO_EOF'\n" + buildLua(pos) + "PILO_EOF"])
    }

    // Re-apply the current arrangement. When `anchorName` is given, resolve any
    // overlaps first (anchored on that monitor), e.g. after a size change.
    function applyAll(anchorName) {
        let arr = arrangement
        const anchor = anchorName !== undefined && anchorName !== null && anchorName !== ""
            ? monitorByName(anchorName)
            : null
        if (anchor && !anchor.disabled)
            arr = resolveOverlaps(arr, anchorName)
        applyArrangement(arr)
    }

    function setEnabled(name, enabled) {
        const monitor = monitorByName(name)
        if (!monitor || stateProc.running)
            return
        if (!enabled && !canSetEnabled(name))
            return

        let next = []
        for (let i = 0; i < monitors.length; i++) {
            const item = monitors[i]
            next.push({
                name: item.name,
                width: item.width,
                height: item.height,
                refreshRate: item.refreshRate,
                scale: item.scale,
                x: item.x,
                y: item.y,
                availableModes: item.availableModes,
                disabled: item.name === name ? !enabled : item.disabled
            })
        }
        monitors = next

        const p = positionOf(name)
        let lua
        if (enabled) {
            lua = 'hl.monitor({ output = "' + name + '", mode = "' + modeFor(name) + '", position = "' + Math.round(p.x) + 'x' + Math.round(p.y) + '", scale = "' + scaleKey(name) + '", disabled = false })'
        } else {
            lua = 'hl.monitor({ output = "' + name + '", disabled = true })'
        }
        stateProc.command = ["hyprctl", "eval", lua]
        stateProc.running = true
    }

    function buildLuaFromPreferred() {
        let lines = [
            "-- Monitor configuration.",
            "--",
            "-- Managed by the pilo settings app (Displays).",
            "return {"
        ]
        for (let i = 0; i < monitors.length; i++)
            lines.push('    { output = "' + monitors[i].name + '", mode = "preferred", position = "auto", scale = "auto" },')
        lines.push("}")
        return lines.join("\n") + "\n"
    }

    function resetAll() {
        resolutionPick = ({})
        refreshPick = ({})
        scalePick = ({})
        let lua = ""
        for (let i = 0; i < monitors.length; i++)
            lua += 'hl.monitor({ output = "' + monitors[i].name + '", mode = "preferred", position = "auto", scale = "auto" })\n'
        if (lua.length > 0) {
            applyProc.command = ["hyprctl", "eval", lua]
            applyProc.running = true
        }
        Quickshell.execDetached(["sh", "-c", "cat > '" + monitorsPath + "' <<'PILO_EOF'\n" + buildLuaFromPreferred() + "PILO_EOF"])
    }

    function setResolution(name, key) {
        let rp = {}
        for (const k in resolutionPick)
            rp[k] = resolutionPick[k]
        rp[name] = key
        resolutionPick = rp
        // The old refresh may not exist at the new resolution.
        let fp = {}
        for (const k in refreshPick) {
            if (k !== name)
                fp[k] = refreshPick[k]
        }
        refreshPick = fp
        applyAll(name)
    }

    function setRefresh(name, key) {
        let pick = {}
        for (const k in refreshPick)
            pick[k] = refreshPick[k]
        pick[name] = key
        refreshPick = pick
        applyAll()
    }

    function setScale(name, key) {
        let pick = {}
        for (const k in scalePick)
            pick[k] = scalePick[k]
        pick[name] = key
        scalePick = pick
        applyAll(name)
    }

    function identify() {
        identifyActive = true
        identifyTimer.restart()
    }

    function stopIdentify() {
        identifyActive = false
    }

    function refresh() {
        if (!monitorsProc.running)
            monitorsProc.running = true
        if (!fileProc.running)
            fileProc.running = true
    }

    function parseMonitors(text) {
        let arr
        try {
            arr = JSON.parse(text)
        } catch (e) {
            return
        }
        let list = []
        let pos = {}
        for (let i = 0; i < arr.length; i++) {
            const m = arr[i]
            list.push({
                name: m.name,
                width: m.width,
                height: m.height,
                refreshRate: m.refreshRate,
                scale: m.scale,
                x: m.x,
                y: m.y,
                availableModes: m.availableModes || [],
                disabled: m.disabled === true
            })
            pos[m.name] = { x: m.x, y: m.y }
        }
        monitors = list
        arrangement = pos
    }

    function parseFileScales(text) {
        let map = {}
        const re = /output\s*=\s*"([^"]+)"[^\n]*?scale\s*=\s*"([^"]+)"/g
        let m
        while ((m = re.exec(text)) !== null)
            map[m[1]] = m[2]
        fileScales = map
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseMonitors(text)
        }
    }

    Process {
        id: stateProc
        onExited: (code) => {
            if (code === 0)
                writeConfig(arrangement)
            monitorsProc.running = true
        }
    }

    Process {
        id: fileProc
        command: ["cat", root.monitorsPath]
        stdout: StdioCollector {
            onStreamFinished: root.parseFileScales(text)
        }
    }

    Process {
        id: applyProc
        stdout: StdioCollector {
            onStreamFinished: monitorsProc.running = true
        }
    }

    Timer {
        id: identifyTimer
        interval: 5000
        repeat: false
        onTriggered: root.identifyActive = false
    }
}
