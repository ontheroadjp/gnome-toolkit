#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

if ! command -v google-chrome >/dev/null 2>&1; then
    cd /tmp || exit
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
    echo "Done: Google Chrome installed."
else
    echo "Google Chrome is already installed. Skipped."
fi

mkdir -p "$BIN_DIR" "$APP_DIR"

chmod +x "${SCRIPT_DIR}/google-chrome-cdp"
ln -sf "${SCRIPT_DIR}/google-chrome-cdp" "${BIN_DIR}/google-chrome-cdp"
ln -sf "${SCRIPT_DIR}/google-chrome-cdp.desktop" "${APP_DIR}/google-chrome-cdp.desktop"

update-desktop-database "$APP_DIR"

echo "Done: chrome installed"
exit 0
