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

exit 0
