#!/bin/bash
# filepath: /home/thomas/.config/waybar/scripts/keyboard-light.sh

level=$(brightnessctl -d platform::kbd_backlight get 2>/dev/null)
max=$(brightnessctl -d platform::kbd_backlight max 2>/dev/null)

if (( level == 0 )); then
  icon=" "
  status="off"
elif (( level < max )); then
  icon=" 󰌶"
  status="low"
else
  icon=" 󰌵"
  status="high"
fi

echo $icon