#!/bin/bash
set -Ceu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo ln -sf "${SCRIPT_DIR}" /etc/keyd

echo "Done: keyd config installed"
exit 0
