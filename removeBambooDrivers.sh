#!/bin/sh

# Remove the Wacom Bamboo drivers if installed

bambooApp="/Applications/Pen Tablet.localized/Pen Tablet Utility.app"

if [[ -e $bambooApp ]]; then
	echo "Bamboo app found, removing."
	/usr/bin/perl "$bambooApp/Contents/Resources/uninstall.pl"
else
	echo "Bamboo app not found, nothing to remove."
	exit 0
fi
