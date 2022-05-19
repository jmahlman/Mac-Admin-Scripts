#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 12/13/16
#
# Name: removeIntuosCintiqDrivers.sh
#
# Purpose: Remove the Intuos/Cintiq Bamboo drivers if installed


isApp="/Applications/Wacom Tablet.localized/Wacom Tablet Utility.app"

if [[ -e $isApp ]]; then
	echo "Intuos/Cintiq app found, removing."
	/usr/bin/perl "$isApp/Contents/Resources/uninstall.pl"
else
	echo "Intuos/Cintiq app not found, nothing to remove."
	exit 0
fi
