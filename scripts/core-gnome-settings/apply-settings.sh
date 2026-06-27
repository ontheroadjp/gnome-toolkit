#!/bin/bash

# -----------------------------------------
# gnome animation
# -----------------------------------------
gsettings set org.gnome.desktop.interface enable-animations true

# -----------------------------------------
# key repeat settings
#                   Fast    Slightly Faster     Normal  Slow
# deray:            140,    200,                250,    300
# repeat-interval:  10,     20,                 30,     40
# -----------------------------------------
gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard delay 180
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 10

# -----------------------------------------
# FEP toggle to Ctrl + Space
# -----------------------------------------
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Control>space']"

# -----------------------------------------
# Window switching (Ctrl+Tab, keep Alt+Tab)
# switch-panels reset to default (Ctrl+Alt+Tab)
# -----------------------------------------
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab', '<Control>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab', '<Shift><Control>Tab']"
gsettings reset org.gnome.desktop.wm.keybindings switch-panels
gsettings reset org.gnome.desktop.wm.keybindings switch-panels-backward

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
# font
# gsettings set org.gnome.desktop.interface font-hinting 'slight'
# gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
# -----------------------------------------
gsettings set org.gnome.desktop.interface font-hinting 'full'
gsettings set org.gnome.desktop.interface font-antialiasing 'grayscale'
