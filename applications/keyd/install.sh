#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v keyd >/dev/null 2>&1; then
    sudo add-apt-repository ppa:keyd-team/ppa
    sudo apt update
    sudo apt install -y keyd
    sudo systemctl enable --now keyd
    echo "Done: keyd installed."
else
    echo "keyd is already installed. Skipped."
fi

sudo rm -rf /etc/keyd
sudo ln -sf "${SCRIPT_DIR}" /etc/keyd

echo "Done: keyd config installed"
exit 0
