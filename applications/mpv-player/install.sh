#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config"

sudo apt install -y ffmpeg mpv

mkdir -p "${BIN_DIR}" "${CONFIG_DIR}"

chmod +x "${SCRIPT_DIR}/mpv-player.py"
ln -sf "${SCRIPT_DIR}/mpv-player.py" "${BIN_DIR}/mpv-player"

ln -sf "${SCRIPT_DIR}" "${CONFIG_DIR}/mpv"

echo "Done: mpv-player installed"
exit 0
