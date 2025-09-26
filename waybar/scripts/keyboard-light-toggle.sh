#!/bin/bash
# filepath: /home/thomas/.config/waybar/scripts/keyboard-light-toggle.sh

level=$(brightnessctl -d platform::kbd_backlight get 2>/dev/null)
max=$(brightnessctl -d platform::kbd_backlight max 2>/dev/null)

if [[ -z "$level" || -z "$max" ]]; then
  exit 1
fi

# Assume 0 = Off, max = High, anything else = Low
if (( level == 0 )); then
  # Off → Low (set to 1)
  brightnessctl -d platform::kbd_backlight set 1
elif (( level < max )); then
  # Low → High
  brightnessctl -d platform::kbd_backlight set $max
else
  # High → Off
  brightnessctl -d platform::kbd_backlight set 0
fi