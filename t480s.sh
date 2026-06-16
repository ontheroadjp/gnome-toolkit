#!/bin/bash

# -----------------------------------------
# gnome animation
# gsettings set org.gnome.desktop.interface enable-animations true
# -----------------------------------------
gsettings set org.gnome.desktop.interface enable-animations true

# -----------------------------------------
# key repeat settings
# -----------------------------------------
gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard delay 140
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 10

# -----------------------------------------
# FEP toggle to Ctrl + Space
# -----------------------------------------
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Control>space']"

# -----------------------------------------
# Change workspace
# -----------------------------------------
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Control>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Control>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Control>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Control>4']"

# -----------------------------------------
# window drag with super to ctrl
# -----------------------------------------
gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier "'<Ctrl>'"

# -----------------------------------------
# window resize
# gsettings set org.gnome.desktop.wm.keybindings move-to-side-w "'<Super>Left'"
# gsettings set org.gnome.desktop.wm.keybindings move-to-side-e "'<Super>Right'"
# -----------------------------------------
# gsettings set org.gnome.desktop.wm.keybindings move-to-side-w "['<Ctrl>Left']"
# gsettings set org.gnome.desktop.wm.keybindings move-to-side-e "['<Ctrl>Right']"

# -----------------------------------------
# font
# gsettings set org.gnome.desktop.interface font-hinting 'slight'
# gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
# -----------------------------------------
gsettings set org.gnome.desktop.interface font-hinting 'full'
gsettings set org.gnome.desktop.interface font-antialiasing 'grayscale'


# -----------------------------------------
# power management 30/85, 75/90, 70/85
# -----------------------------------------
echo 30 | sudo tee /sys/class/power_supply/BAT0/charge_start_threshold
echo 85 | sudo tee /sys/class/power_supply/BAT0/charge_stop_threshold

## make it persistent
# sudo apt update
# sudo apt install -y tlp
# sudo vim /etc/tlp.conf
# START_CHARGE_THRESH_BAT0=70
# STOP_CHARGE_THRESH_BAT0=85
# sudo systemctl enable --now tlp
# sudo tlp start
# sudo tlp-stat -b

