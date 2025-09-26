#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 3 ]; then
  echo "<span foreground='#fab387'>Γ</span>"
else
  echo "γ"
fi