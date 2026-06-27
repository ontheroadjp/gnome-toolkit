#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config"

if ! command -v espanso >/dev/null 2>&1; then
    cd /tmp || exit
    wget https://github.com/espanso/espanso/releases/latest/download/espanso-debian-wayland-amd64.deb
    sudo apt install -y ./espanso-debian-wayland-amd64.deb
    rm espanso-debian-wayland-amd64.deb
    echo "Done: espanso installed."
else
    echo "espanso is already installed. Skipped."
fi

mkdir -p "${BIN_DIR}" "${CONFIG_DIR}"

chmod +x "${SCRIPT_DIR}/espanso-toggle"
ln -sf "${SCRIPT_DIR}/espanso-toggle" "${BIN_DIR}/espanso-toggle"

ln -sf "${SCRIPT_DIR}" "${CONFIG_DIR}/espanso"

echo "Done: espanso config installed"
echo ""
echo "=== Manual step: espanso ==="
echo "Run the following to register and start espanso as a user service:"
echo ""
echo "  espanso service register"
echo "  espanso service start"
exit 0
