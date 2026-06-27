#!/bin/bash
set -Ceu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"
APP_DIR="${HOME}/.local/share/applications"

mkdir -p "${CONFIG_DIR}" "${APP_DIR}"

ln -sf "${SCRIPT_DIR}" "${CONFIG_DIR}/alacritty"
ln -sf "${SCRIPT_DIR}/Alacritty.desktop" "${APP_DIR}/Alacritty.desktop"

update-desktop-database "${APP_DIR}"

echo "Done: alacritty installed"
exit 0
