#!/bin/sh

if [[ ! -e "/Install Wacom Tablet.pkg" ]]; then
  rm -Rf /ChineseS
  rm -Rf /ChineseT
  rm -Rf /Dutch
  rm -Rf /English
  rm -Rf /French
  rm -Rf /German
  rm -Rf /Italian
  rm -Rf /Japanese
  rm -Rf /Korean
  rm -Rf /Polish
  rm -Rf /Portuguese
  rm -Rf /Russian
  rm -Rf /Spanish
  rm -Rf "/Install Wacom Tablet.pkg"
  exit 0
else
  echo "Files not found"
  exit 0
fi
