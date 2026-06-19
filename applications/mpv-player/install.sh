#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
TARGET_PATH="${TARGET_DIR}/mpv-player"

mkdir -p "${TARGET_DIR}"
chmod +x "${REPO_DIR}/mpv-player.py"
ln -sf "${REPO_DIR}/mpv-player.py" "${TARGET_PATH}"

echo "Installed ${TARGET_PATH}"
