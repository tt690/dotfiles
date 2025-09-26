#!/bin/bash
# ── battery.sh ─────────────────────────────────────────────
# Description: Shows battery % with ASCII bar + dynamic tooltip
# Usage: Waybar `custom/battery` every 10s
# Dependencies: upower, awk, seq, printf
#  ──────────────────────────────────────────────────────────

capacity=$(cat /sys/class/power_supply/BAT0/capacity)
status=$(cat /sys/class/power_supply/BAT0/status)

# Get detailed info from upower
time_to_empty=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | awk -F: '/time to empty/ {print $2}' | xargs)
time_to_full=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | awk -F: '/time to full/ {print $2}' | xargs)

# Icons
charging_icons=(󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅)
default_icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)

index=$((capacity / 10))
[ $index -ge 10 ] && index=9

if [[ "$status" == "Charging" ]]; then
    icon=${charging_icons[$index]}
elif [[ "$status" == "Full" ]]; then
    icon="󰂅"
else
    icon=${default_icons[$index]}
fi

# ASCII bar
if [ "$capacity" -ge 100 ]; then
  filled=10
  empty=0
else
  filled=$((capacity / 10))
  empty=$((10 - filled))
fi

bar=$(printf '█%.0s' $(seq 0 $filled))
pad=$(printf '░%.0s' $(seq 0 $empty))
ascii_bar="|$bar$pad|"
ascii_bar="[${ascii_bar:1:10}]"

# Color thresholds
if [ "$capacity" -lt 20 ]; then
    fg="#bf616a"  # red
    class="low"
elif [ "$capacity" -lt 55 ]; then
    fg="#fab387"  # orange
    class="medium"
else
    fg="#fab387"  # cyan
    class="high"
fi

# Tooltip content
tooltip="Status: $status"
[ -n "$time_to_empty" ] && tooltip+="\nTime to empty: $time_to_empty"
[ -n "$time_to_full" ] && tooltip+="\nTime to fill: $time_to_full"

# JSON output
echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar $capacity%</span>\",\"tooltip\":\"$tooltip\",\"class\":\"$class\"}"
