#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 9 ]; then
  echo "<span foreground='#fab387'>Ι</span>"
else
  echo "ι"
fi