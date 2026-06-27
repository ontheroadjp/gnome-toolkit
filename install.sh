#!/bin/bash

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------
# core tools (no config in this repo)
# ----------------------------------
"${REPO_DIR}/scripts/core-tools/install.sh"

# ----------------------------------
# keyd
# ----------------------------------
"${REPO_DIR}/applications/keyd/install.sh"

# ----------------------------------
# alacritty
# ----------------------------------
"${REPO_DIR}/applications/alacritty/install.sh"

# ----------------------------------
# mpv
# ----------------------------------
"${REPO_DIR}/applications/mpv-player/install.sh"

# ----------------------------------
# yt-dlp
# ----------------------------------
"${REPO_DIR}/applications/yt-dlp/install.sh"

# ----------------------------------
# espanso
# ----------------------------------
"${REPO_DIR}/applications/espanso/install.sh"

# ----------------------------------
# chrome
# ----------------------------------
"${REPO_DIR}/applications/chrome/install.sh"

# ----------------------------------
# settings > keyboard > custom shortcuts
# ----------------------------------
# Uncomment to install gnome-overview-toggle and register keyboard shortcut:
# "${REPO_DIR}/gnome-extensions/gnome-overview-toggle/install.sh"

# ----------------------------------
# fep-switcher (GNOME extension: core)
# ----------------------------------
rm -rf "${HOME}/.local/share/gnome-shell/extensions/fep-switcher@local"
ln -sf "${REPO_DIR}/scripts/fep-switcher" "${HOME}/.local/share/gnome-shell/extensions/fep-switcher@local"
gnome-extensions enable fep-switcher@local

# ----------------------------------
# app-switch-us-input (GNOME extension: window focus client)
# ----------------------------------
rm -rf "${HOME}/.local/share/gnome-shell/extensions/app-switch-us-input@local"
ln -sf "${REPO_DIR}/scripts/app-switch-us-input" "${HOME}/.local/share/gnome-shell/extensions/app-switch-us-input@local"
gnome-extensions enable app-switch-us-input@local

# ----------------------------------
# tmux-switch-us-input
# ----------------------------------
ln -sf "${REPO_DIR}/scripts/tmux-switch-us-input/switch-input-to-us" "${HOME}/.local/bin/switch-input-to-us"

# ----------------------------------
# Manual steps
# ----------------------------------
cat <<'EOF'

=== Manual step: ~/.tmux.conf ===
Add the following line to enable auto-switch to US input on pane focus:

  set-hook -g after-select-pane 'run-shell "switch-input-to-us"'

NOTE: On Wayland, newly installed GNOME extensions take effect after logout/login.

EOF

exit 0
