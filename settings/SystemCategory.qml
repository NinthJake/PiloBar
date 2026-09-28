import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

ColumnLayout {
    id: root
    spacing: 16

    CategoryHeading {
        title: "System"
        subtitle: "Machine-wide controls exposed by the bar."
    }

    SettingRow {
        label: "Power profile"
        hint: "Forwarded to power-profiles-daemon."

        Item { Layout.fillWidth: true }

        Segmented {
            options: {
                let o = [
                    { key: "powersaver", label: "Battery" },
                    { key: "balanced", label: "Balanced" }
                ]
                if (Power.hasPerformance)
                    o.push({ key: "performance", label: "Performance" })
                return o
            }
            value: Power.profile === "power-saver" ? "powersaver" : (Power.profile === "performance" ? "performance" : "balanced")
            onSelected: (key) => Power.setProfile(key === "powersaver" ? "power-saver" : (key === "performance" ? "performance" : "balanced"))
        }
    }
}