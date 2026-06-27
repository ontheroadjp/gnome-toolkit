#!/bin/bash
set -Ceu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
TOGGLE_PATH="${BIN_DIR}/gnome-overview-toggle"

mkdir -p "${BIN_DIR}"

chmod +x "${SCRIPT_DIR}/gnome-overview-toggle"
ln -sf "${SCRIPT_DIR}/gnome-overview-toggle" "${TOGGLE_PATH}"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'gnome-overview-toggle'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "${TOGGLE_PATH}"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Control><Shift>space'

echo "Done: gnome-overview-toggle installed"
exit 0
