#!/bin/bash

CORE_TOOLKIT_FOR_GNOME_PATH="$(ghq root)/github.com/ontheroadjp/core-toolkit-for-gnome"

# ----------------------------------
# keyd
# ----------------------------------
sudo ln -sf ${CORE_TOOLKIT_FOR_GNOME_PATH}/root/etc/keyd /etc

# ----------------------------------
# alacritty
# ----------------------------------
ln -sf ${CORE_TOOLKIT_FOR_GNOME_PATH}/root/home/user/.local/share/applications/Alacritty.desktop $HOME/.local/share/applications
ln -sf ${CORE_TOOLKIT_FOR_GNOME_PATH}/root/home/user/.config/alacritty $HOME/.config

# ----------------------------------
# mpv
# ----------------------------------
ln -sf ${CORE_TOOLKIT_FOR_GNOME_PATH}/root/home/user/.config/mpv $HOME/.config

# ----------------------------------
# settings > keyboard > custom shortcuts
# ----------------------------------
GNOME_OVERVIEW_TOGGLE_PATH="${HOME}/.local/bin/gnome-overview-toggle"

ln -sf ${CORE_TOOLKIT_FOR_GNOME_PATH}/root/home/user/.local/bin/gnome-overview-toggle ${GNOME_OVERVIEW_TOGGLE_PATH}
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'gnome-overview-toggle'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "${GNOME_OVERVIEW_TOGGLE_PATH}"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Control><Shift>space'

# ----------------------------------
# fep-switcher (GNOME extension: core)
# ----------------------------------
rm -rf ${HOME}/.local/share/gnome-shell/extensions/fep-switcher@local
ln -sf ${CORE_TOOLKIT_FOR_GNOME_PATH}/scripts/fep-switcher ${HOME}/.local/share/gnome-shell/extensions/fep-switcher@local

# ----------------------------------
# app-switch-us-input (GNOME extension: window focus client)
# ----------------------------------
rm -rf ${HOME}/.local/share/gnome-shell/extensions/app-switch-us-input@local
ln -sf ${CORE_TOOLKIT_FOR_GNOME_PATH}/scripts/app-switch-us-input ${HOME}/.local/share/gnome-shell/extensions/app-switch-us-input@local

# ----------------------------------
# tmux-switch-us-input
# ----------------------------------
ln -sf ${CORE_TOOLKIT_FOR_GNOME_PATH}/scripts/tmux-switch-us-input/switch-input-to-us ${HOME}/.local/bin/switch-input-to-us

# ----------------------------------
# Manual steps
# ----------------------------------
cat <<'EOF'

=== Manual step 1: enable GNOME extensions ===
Run the following to activate the new extensions (required after first install or logout/login):

  gnome-extensions enable fep-switcher@local
  gnome-extensions enable app-switch-us-input@local

=== Manual step 2: ~/.tmux.conf ===
Add the following line to enable auto-switch to US input on pane focus:

  set-hook -g after-select-pane 'run-shell "switch-input-to-us"'

EOF

exit 0
