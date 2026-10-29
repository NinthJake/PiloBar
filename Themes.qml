pragma Singleton

import Quickshell

// Registry of the bar's colour schemes. Each theme carries the full token set
// `Theme.qml` paints with, so switching is just a change of `Settings.theme`.
//
// Kept free of any dependency on `Settings` (Theme.qml resolves the active one)
// so there is no singleton cycle.
Singleton {
    id: root

    // The look the bar has always had, so a fresh install changes nothing.
    readonly property string defaultId: "vague"

    readonly property var presets: [
        {
            id: "vague",
            name: "Vague",
            bg: "#141415",
            fg: "#cdcdcd",
            line: "#252530",
            muted: "#606079",
            teal: "#b4d4cf",
            steel: "#6e94b2",
            error: "#d8647e",
            warning: "#f3be7c",
            plus: "#7fa563"
        },
        {
            id: "gruvbox",
            name: "Gruvbox",
            bg: "#282828",
            fg: "#ebdbb2",
            line: "#3c3836",
            muted: "#928374",
            teal: "#fabd2f",
            steel: "#83a598",
            error: "#fb4934",
            warning: "#fe8019",
            plus: "#b8bb26"
        },
        {
            id: "frost",
            name: "Frost",
            bg: "#0f1418",
            fg: "#e6eef4",
            line: "#1e2830",
            muted: "#83919c",
            teal: "#7ab8e0",
            steel: "#5f8bb0",
            error: "#d8647e",
            warning: "#f3be7c",
            plus: "#7fa563"
        },
        {
            id: "everforest",
            name: "Everforest",
            bg: "#2d353b",
            fg: "#d3c6aa",
            line: "#343f44",
            muted: "#859289",
            teal: "#a7c080",
            steel: "#7fbbb3",
            error: "#e67e80",
            warning: "#dbbc7f",
            plus: "#83c092"
        },
        {
            id: "rose-pine",
            name: "Rosé Pine",
            bg: "#191724",
            fg: "#e0def4",
            line: "#26233a",
            muted: "#6e6a86",
            teal: "#c4a7e7",
            steel: "#31748f",
            error: "#eb6f92",
            warning: "#f6c177",
            plus: "#9ccfd8"
        },
        {
            id: "catppuccin",
            name: "Catppuccin",
            bg: "#1e1e2e",
            fg: "#cdd6f4",
            line: "#313244",
            muted: "#7f849c",
            teal: "#89b4fa",
            steel: "#cba6f7",
            error: "#f38ba8",
            warning: "#f9e2af",
            plus: "#a6e3a1"
        },
        {
            id: "dracula",
            name: "Dracula",
            bg: "#282a36",
            fg: "#f8f8f2",
            line: "#44475a",
            muted: "#6272a4",
            teal: "#bd93f9",
            steel: "#8be9fd",
            error: "#ff5555",
            warning: "#f1fa8c",
            plus: "#50fa7b"
        },
        {
            id: "material",
            name: "Material",
            bg: "#263238",
            fg: "#eeffff",
            line: "#314549",
            muted: "#546e7a",
            teal: "#82aaff",
            steel: "#c792ea",
            error: "#f07178",
            warning: "#ffcb6b",
            plus: "#c3e88d"
        },
        {
            id: "nord",
            name: "Nord",
            bg: "#2e3440",
            fg: "#d8dee9",
            line: "#3b4252",
            muted: "#616e88",
            teal: "#88c0d0",
            steel: "#81a1c1",
            error: "#bf616a",
            warning: "#ebcb8b",
            plus: "#a3be8c"
        }
    ]

    // presets[0] is the default, so an unknown id falls back to the look the
    // bar has always had.
    readonly property var defaultTheme: presets[0]

    function find(id) {
        for (let i = 0; i < presets.length; i++) {
            if (presets[i].id === id)
                return presets[i]
        }
        return defaultTheme
    }

    function has(id) {
        for (let i = 0; i < presets.length; i++) {
            if (presets[i].id === id)
                return true
        }
        return false
    }
}
