#!/bin/sh

# Remove the Wacom Intuos/Cintiq drivers if installed

isApp="/Applications/Wacom Tablet.localized/Wacom Tablet Utility.app"

if [[ -e $isApp ]]; then
	echo "Intuos/Cintiq app found, removing."
	/usr/bin/perl "$isApp/Contents/Resources/uninstall.pl"
else
	echo "Intuos/Cintiq app not found, nothing to remove."
	exit 0
fi
