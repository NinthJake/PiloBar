import QtQuick
import QtQuick.Shapes
import qs

// Filled background for the Centered/Islands chrome when `Settings.shape` is a
// custom shape. `rounded` is drawn by the caller with a rounded Rectangle.
//
//   s-curve — concave "cove" at the docked edge, convex toward the other edge,
//             so the block flares into the screen edge with an S profile.
//   bevel   — a straight flare from the docked edge that blends tangentially
//             into a rounded outer corner, so there is no hard edge where they
//             meet; the fillet is sized to match a plain rounded corner.
//
// `shapeLeftDocked`/`shapeRightDocked` square off the left/right docked corner
// where the block is attached to a side screen edge.
//
// Both flare `overhang` past the body on each side of the docked edge; the
// caller must leave room for it. The body occupies x in [overhang, overhang+width].
Item {
    id: root

    property string shape: "s-curve"
    property bool onTop: true
    property color color: Theme.bg
    property real radius: 0

    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0

    // Whether the left/right corner on the docked edge gets the shape. When
    // false it is a square corner (the bar is attached to a side screen edge
    // there).
    property bool shapeLeftDocked: true
    property bool shapeRightDocked: true

    readonly property real _h: Math.max(0, height)
    readonly property real _c: shape === "s-curve" ? Math.min(radius, _h / 2) : 0
    readonly property real _o: shape === "bevel" ? _h : _c
    readonly property real _tl: Math.max(0, Math.min(topLeftRadius, _h / 2))
    readonly property real _tr: Math.max(0, Math.min(topRightRadius, _h / 2))
    readonly property real _bl: Math.max(0, Math.min(bottomLeftRadius, _h / 2))
    readonly property real _br: Math.max(0, Math.min(bottomRightRadius, _h / 2))

    readonly property string pathData: {
        const W = Math.max(0, width)
        const H = _h
        const o = _o
        const r = _c
        const L = shapeLeftDocked
        const R = shapeRightDocked
        let p = ""
        if (shape === "bevel") {
            // Straight flare, blending tangentially into a rounded outer
            // corner. k/m are the tangent offsets for a 45° edge; the fillet is
            // scaled so its corner cut matches a plain rounded corner.
            const k = 0.2928932 // (2 - sqrt(2)) / 2
            const m = 0.4142136 // sqrt(2) - 1
            const blf = Math.min(_bl * 2.4142136, H)
            const brf = Math.min(_br * 2.4142136, H)
            const tlf = Math.min(_tl * 2.4142136, H)
            const trf = Math.min(_tr * 2.4142136, H)
            if (onTop) {
                if (L) {
                    p = "M 0 0 L " + (o - blf * k) + " " + (H - blf * k)
                    p += " A " + blf + " " + blf + " 0 0 0 " + (o + blf * m) + " " + H
                } else {
                    p = "M " + o + " 0 L " + o + " " + H
                }
                p += " L " + (o + W - (R ? brf * m : 0)) + " " + H
                if (R) {
                    p += " A " + brf + " " + brf + " 0 0 0 " + (o + W + brf * k) + " " + (H - brf * k)
                    p += " L " + (o + W + o) + " 0 Z"
                } else {
                    p += " L " + (o + W) + " 0 Z"
                }
            } else {
                if (L) {
                    p = "M 0 " + H + " L " + (o - tlf * k) + " " + (tlf * k)
                    p += " A " + tlf + " " + tlf + " 0 0 1 " + (o + tlf * m) + " 0"
                } else {
                    p = "M " + o + " " + H + " L " + o + " 0"
                }
                p += " L " + (o + W - (R ? trf * m : 0)) + " 0"
                if (R) {
                    p += " A " + trf + " " + trf + " 0 0 1 " + (o + W + trf * k) + " " + (trf * k)
                    p += " L " + (o + W + o) + " " + H + " Z"
                } else {
                    p += " L " + (o + W) + " " + H + " Z"
                }
            }
            return p
        }
        // s-curve: concave cove at the docked corners, convex outer corners.
        if (onTop) {
            p = L ? "M 0 0 A " + r + " " + r + " 0 0 1 " + o + " " + r : "M " + o + " 0"
            p += " L " + o + " " + (H - _bl)
            p += " A " + _bl + " " + _bl + " 0 0 0 " + (o + _bl) + " " + H
            p += " L " + (o + W - _br) + " " + H
            p += " A " + _br + " " + _br + " 0 0 0 " + (o + W) + " " + (H - _br)
            p += R
                ? " L " + (o + W) + " " + r + " A " + r + " " + r + " 0 0 1 " + (o + W + r) + " 0 Z"
                : " L " + (o + W) + " 0 Z"
        } else {
            p = L ? "M 0 " + H + " A " + r + " " + r + " 0 0 0 " + o + " " + (H - r) : "M " + o + " " + H
            p += " L " + o + " " + _tl
            p += " A " + _tl + " " + _tl + " 0 0 1 " + (o + _tl) + " 0"
            p += " L " + (o + W - _tr) + " 0"
            p += " A " + _tr + " " + _tr + " 0 0 1 " + (o + W) + " " + _tr
            p += R
                ? " L " + (o + W) + " " + (H - r) + " A " + r + " " + r + " 0 0 0 " + (o + W + r) + " " + H + " Z"
                : " L " + (o + W) + " " + H + " Z"
        }
        return p
    }

    Shape {
        x: -root._o
        y: 0
        width: root.width + 2 * root._o
        height: root.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: root.color
            PathSvg { path: root.pathData }
        }
    }
}
