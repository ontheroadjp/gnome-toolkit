#!/bin/bash
set -Ceu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config"

mkdir -p "${BIN_DIR}" "${CONFIG_DIR}"

chmod +x "${SCRIPT_DIR}/espanso-toggle"
ln -sf "${SCRIPT_DIR}/espanso-toggle" "${BIN_DIR}/espanso-toggle"

ln -sf "${SCRIPT_DIR}" "${CONFIG_DIR}/espanso"

echo "Done: espanso installed"
echo ""
echo "=== Manual step: espanso ==="
echo "Run the following to register and start espanso as a user service:"
echo ""
echo "  espanso service register"
echo "  espanso service start"
exit 0
