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

    // [{ name, width, height, refreshRate, scale, x, y, availableModes }]
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

    // Reading order: top to bottom, then left to right.
    readonly property var order: {
        let names = []
        for (let i = 0; i < monitors.length; i++)
            names.push(monitors[i].name)
        const a = arrangement
        names.sort((p, q) => {
            const pp = a[p] || { x: 0, y: 0 }
            const qq = a[q] || { x: 0, y: 0 }
            if (pp.y !== qq.y)
                return pp.y - qq.y
            return pp.x - qq.x
        })
        return names
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

    // 1-based id shown in the settings list and the identify overlay. 0 when
    // the monitor is not known yet.
    function idFor(name) {
        return order.indexOf(name) + 1
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
            if (o.name === name)
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

    // Push overlapping monitors apart until none overlap. The monitor named
    // `anchorName` (the one just dropped) stays put; the others move out of its
    // way, cascading if needed. Pairs separate along their axis of least
    // overlap, so a monitor dropped between two others pushes them sideways.
    function resolveOverlaps(src, anchorName) {
        let pos = _clonePositions(src)
        for (let iter = 0; iter < 120; iter++) {
            let changed = false
            for (let i = 0; i < monitors.length; i++) {
                for (let j = 0; j < monitors.length; j++) {
                    if (i === j)
                        continue
                    const an = monitors[i].name
                    const bn = monitors[j].name
                    const pa = pos[an]
                    const pb = pos[bn]
                    if (!pa || !pb)
                        continue
                    const ra = _rectOf(an, pa.x, pa.y)
                    const rb = _rectOf(bn, pb.x, pb.y)
                    const ox = Math.min(ra.x + ra.w, rb.x + rb.w) - Math.max(ra.x, rb.x)
                    const oy = Math.min(ra.y + ra.h, rb.y + rb.h) - Math.max(ra.y, rb.y)
                    if (ox <= 0 || oy <= 0)
                        continue
                    changed = true
                    if (ox <= oy) {
                        const dir = (ra.x + ra.w / 2) <= (rb.x + rb.w / 2) ? -1 : 1
                        if (bn === anchorName) {
                            pa.x += dir * ox
                        } else if (an === anchorName) {
                            pb.x -= dir * ox
                        } else {
                            pa.x += dir * ox / 2
                            pb.x -= dir * ox / 2
                        }
                    } else {
                        const dir = (ra.y + ra.h / 2) <= (rb.y + rb.h / 2) ? -1 : 1
                        if (bn === anchorName) {
                            pa.y += dir * oy
                        } else if (an === anchorName) {
                            pb.y -= dir * oy
                        } else {
                            pa.y += dir * oy / 2
                            pb.y -= dir * oy / 2
                        }
                    }
                }
            }
            if (!changed)
                break
        }
        let out = {}
        for (const k in pos)
            out[k] = { x: Math.round(pos[k].x), y: Math.round(pos[k].y) }
        return out
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
            "-- logical layout coords), scale (\"auto\" or a number).",
            "return {"
        ]
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i]
            const p = pos[m.name]
            if (!p)
                continue
            lines.push('    { output = "' + m.name + '", mode = "' + modeFor(m.name) + '", position = "' + Math.round(p.x) + 'x' + Math.round(p.y) + '", scale = "' + scaleKey(m.name) + '" },')
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
            if (!p)
                continue
            const spec = m.name + "," + modeFor(m.name) + "," + Math.round(p.x) + "x" + Math.round(p.y) + "," + scaleKey(m.name)
            script += "hyprctl keyword monitor '" + spec + "' ; "
        }
        if (script.length > 0) {
            applyProc.command = ["sh", "-c", script]
            applyProc.running = true
        }
        Quickshell.execDetached(["sh", "-c", "cat > '" + monitorsPath + "' <<'PILO_EOF'\n" + buildLua(arr) + "PILO_EOF"])
        arrangement = arr
    }

    // Re-apply the current arrangement. When `anchorName` is given, resolve any
    // overlaps first (anchored on that monitor), e.g. after a size change.
    function applyAll(anchorName) {
        let arr = arrangement
        if (anchorName !== undefined && anchorName !== null && anchorName !== "")
            arr = resolveOverlaps(arr, anchorName)
        applyArrangement(arr)
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
        let script = ""
        for (let i = 0; i < monitors.length; i++)
            script += "hyprctl keyword monitor '" + monitors[i].name + ",preferred,auto,auto' ; "
        if (script.length > 0) {
            applyProc.command = ["sh", "-c", script]
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
                availableModes: m.availableModes || []
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
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseMonitors(text)
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
