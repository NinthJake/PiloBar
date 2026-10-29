#!/bin/sh
# Apply a KDE colour scheme to ~/.config/kdeglobals without Plasma.
#
# KdeTheme.qml generates ~/.local/share/color-schemes/Pilo-<theme>.colors and
# normally hands it to plasma-apply-colorscheme, which ships with
# plasma-workspace. On a non-Plasma desktop that tool is usually absent, so
# this helper writes the same groups into kdeglobals with kwriteconfig6
# (part of kconfig, which every KDE app already depends on).
#
# KDE apps still need the KDE platform theme to read kdeglobals at all:
# install plasma-integration and set QT_QPA_PLATFORMTHEME=kde.
set -eu

name="${1:?usage: kde-apply-colorscheme.sh <scheme-name>}"
file="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/$name.colors"

if [ ! -f "$file" ]; then
    echo "kde-apply-colorscheme: scheme not found: $file" >&2
    exit 1
fi

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
    echo "kde-apply-colorscheme: kwriteconfig6 not found (install kconfig)" >&2
    exit 1
fi

group=""
while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        ''|'#'*)
            continue
            ;;
        \[*\])
            group="${line#\[}"
            group="${group%\]}"
            ;;
        *=*)
            key="${line%%=*}"
            value="${line#*=}"
            # [General] Name is the scheme's display name, not a global setting.
            if [ "$group" = "General" ] && [ "$key" = "Name" ]; then
                continue
            fi
            kwriteconfig6 --file kdeglobals --group "$group" --key "$key" "$value"
            ;;
    esac
done < "$file"

kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$name"
