#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 12/13/16
#
# Name: removeBambooDrivers.sh
#
# Purpose: Remove the Wacom Bamboo drivers if installed

bambooApp="/Applications/Pen Tablet.localized/Pen Tablet Utility.app"

if [[ -e $bambooApp ]]; then
	echo "Bamboo app found, removing."
	/usr/bin/perl "$bambooApp/Contents/Resources/uninstall.pl"
else
	echo "Bamboo app not found, nothing to remove."
	exit 0
fi
