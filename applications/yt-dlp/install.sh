#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"

if ! command -v yt-dlp >/dev/null 2>&1; then
    sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
    echo "Done: yt-dlp installed."
else
    echo "yt-dlp is already installed. Upgrading ..."
    sudo yt-dlp -U
fi

mkdir -p "${CONFIG_DIR}"
ln -sf "${SCRIPT_DIR}" "${CONFIG_DIR}/yt-dlp"

echo "Done: yt-dlp config installed"
exit 0
