#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 6 ]; then
  echo "<span foreground='#fab387'>Ζ</span>"
else
  echo "ζ"
fi