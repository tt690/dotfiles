#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 5 ]; then
  echo "<span foreground='#fab387'>Ε</span>"
else
  echo "ε"
fi