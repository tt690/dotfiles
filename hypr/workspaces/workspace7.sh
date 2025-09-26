#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 7 ]; then
  echo "<span foreground='#fab387'>Η</span>"
else
  echo "η"
fi