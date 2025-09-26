#!/bin/bash
# filepath: /home/thomas/.config/waybar/scripts/mediaplayer.sh

status=$(playerctl status 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)

if [[ "$status" == "Playing" ]]; then
    icon=""
    class="playing"
elif [[ "$status" == "Paused" ]]; then
    icon=""
    class="paused"
else
    icon=""
    class="stopped"
fi

if [[ -n "$artist" && -n "$title" ]]; then
    text="$icon $artist - $title"
    tooltip="$artist - $title"
elif [[ -n "$title" ]]; then
    text="$icon $title"
    tooltip="$title"
elif [[ -n "$artist" ]]; then
    text="$icon $artist"
    tooltip="$artist"
else
    text="$icon"
    tooltip="No media playing"
fi

echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"