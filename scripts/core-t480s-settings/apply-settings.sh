#!/bin/bash

# -----------------------------------------
# power management 30/85, 75/90, 70/85
# ThinkPad 固有: thinkpad_acpi カーネルモジュールが必要
# 他機種では /sys/class/power_supply/BAT0/charge_*_threshold が存在しない
# -----------------------------------------
echo 30 | sudo tee /sys/class/power_supply/BAT0/charge_start_threshold
echo 85 | sudo tee /sys/class/power_supply/BAT0/charge_stop_threshold

## make it persistent for power management
# sudo apt update
# sudo apt install -y tlp
# sudo vim /etc/tlp.conf
# START_CHARGE_THRESH_BAT0=70
# STOP_CHARGE_THRESH_BAT0=85
# sudo systemctl enable --now tlp
# sudo tlp start
# sudo tlp-stat -b
