#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 8 ]; then
  echo "<span foreground='#fab387'>Θ</span>"
else
  echo "θ"
fi