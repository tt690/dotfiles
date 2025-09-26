#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Rofi Power Menu
#  Provides a simple system power menu integrated with Waybar.
#  Example:
#      ./powermenu.sh
#      # Opens a Rofi menu with power options
# ─────────────────────────────────────────────────────────────────────────────

chosen=$(printf "󰤄  Sleep\n  Reboot\n⏻  Shutdown\n  Logout\n  Lock" | rofi -dmenu -i -p "Power Menu:" -theme ~/.config/rofi/power-menu.rasi)

case "$chosen" in
    "󰤄  Sleep") systemctl suspend ;;
    "  Reboot") systemctl reboot ;;
    "⏻  Shutdown") systemctl poweroff ;;
    "  Logout") hyprctl dispatch exit ;;
    "  Lock") pidof hyprlock || hyprlock ;;
    *) exit 1 ;;
esac