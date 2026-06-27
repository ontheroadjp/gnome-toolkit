#!/bin/bash
set -Ceu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"

mkdir -p "${CONFIG_DIR}"

ln -sf "${SCRIPT_DIR}" "${CONFIG_DIR}/yt-dlp"

echo "Done: yt-dlp config installed"
exit 0
