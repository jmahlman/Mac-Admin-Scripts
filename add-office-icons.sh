#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 5/27/16
#
# Name: add-office-icons
#
# Purpose: Adds office icons to dock using dockutil after installing Office 2016
# Also installs dockutil if it's not found
#
# Changelog
# 9/5/17:    - Fixed a double negative if-statement
#

jamfbinary=$(/usr/bin/which jamf)

# Make sure we have dockutil, install it if we don't
if [ ! -f "/usr/local/bin/dockutil" ]; then
	echo "Installing DockUtil from JSS"
	"$jamfbinary" policy -event dockutil
	if [ ! -f "/usr/local/bin/dockutil" ]; then
		echo "Unable to install DockUtil, aborting!"
		exit 1
	fi
fi
du="/usr/local/bin/dockutil"

# Get the current user
if [ ! -z "$3" ]; then
	user=$3
else
	user=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
fi

##########
# Script #
##########

# Add dock icons only if word is installed (this happens after a full install, so if that's installed, they're all installed)
if [ -e "/Applications/Microsoft Word.app" ]; then
	echo "Adding Office 2016 apps to dock"
	sleep 3
	$du --add "/Applications/Microsoft Word.app" --replacing "Microsoft Word" --no-restart /Users/$user
	$du --add "/Applications/Microsoft Excel.app" --replacing "Microsoft Excel" --no-restart /Users/$user
	$du --add "/Applications/Microsoft Outlook.app" --replacing "Microsoft Outlook" --no-restart /Users/$user
	$du --add "/Applications/Microsoft Powerpoint.app" --replacing "Microsoft Powerpoint" --no-restart /Users/$user
	# Restart the dock when done
	sleep 3
	killall Dock
	exit 0
else
	echo "Office 2016 not installed!  Exiting."
	exit 1
fi
