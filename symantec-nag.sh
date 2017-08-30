#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: symantec-nag
#
# Purpose: Uses CocoaDialog to nag our users to install Symantec AV
#
#
# Changelog
#
# 8/31/17 - Cleaned up the script a bit, updates user variable
# 8/25/17 - Added ability to customize force date or not; $4 is for a jamf variable
# 8/10/17 - Added sudo -u $(ls -l /dev/console | awk '{print $3}')to the CocoaDialog portions to stop errors on older systems
# 8/4/17 - Initial Creation
#
#

icons=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources
CD_APP=/Applications/Utilities/CocoaDialog.app
CocoaDialog=$CD_APP/Contents/MacOS/CocoaDialog
jamf_bin=$(/usr/bin/which jamf)
user=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
install_date=$4 # $4 is for jamf server
OTISmsg='A new Anti-Virus program needs to be installed on your computer. Please run the "Install Symantec Anti-Virus" policy in Self Service now.

This installation should not take long and will require your machine to reboot.'

# does CocoaDialog Exist?
if [ ! -f $CocoaDialog ] ; then
	echo "Installing Cocoa Dialog from JSS"
	$jamf_bin policy -event installcocoaDialog
	if [ ! -f $CocoaDialog ] ; then
		echo "Couldn't install Cocoa Dialog! Exiting."
		exit 1
	fi
fi

rv=`sudo -u $user $CocoaDialog msgbox --float --icon-file "$icons/ToolbarInfo.icns" --no-cancel \
  --button1 "Open Self Service Now" --button2 "Not Now" --title "New Anti-Virus Available from UArts" \
  --width "450" --height "150" \
  --text "This is an important message from OTIS at UArts" --informative-text "$OTISmsg"`
if [ "$rv" == "1" ]; then
  open /Applications/Self\ Service.app/
  exit 0
elif [ "$rv" == "2" ]; then
	if [[ -z $4 ]]; then
		sudo -u $user $CocoaDialog ok-msgbox --float --no-cancel --icon-file "$icons/ToolbarInfo.icns" \
	  --width "450" --height "150" \
			--title "New Anti-Virus Available from UArts" --text "Please note:" \
	    --informative-text "You will see this alert every day until you install. \
			Thank you."
		else
			sudo -u $user $CocoaDialog ok-msgbox --float --no-cancel --icon-file "$icons/ToolbarInfo.icns" \
		  --width "450" --height "150" \
				--title "New Anti-Virus Available from UArts" --text "Please note:" \
		    --informative-text "After $install_date, the anti-virus will install automatically. You will see this alert every day until you install. Thank you."
				fi
	if [ "$rv" == "1" ]; then
		exit 0
	fi
fi
