#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 2 ]; then
  echo "<span foreground='#fab387'>Β</span>"
else
  echo "β"
fi