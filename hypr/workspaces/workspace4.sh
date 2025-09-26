#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 4 ]; then
  echo "<span foreground='#fab387'>Δ</span>"
else
  echo "δ"
fi