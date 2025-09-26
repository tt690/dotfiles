#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 1 ]; then
  echo "<span foreground='#fab387'>Α</span>"
else
  echo "α"
fi