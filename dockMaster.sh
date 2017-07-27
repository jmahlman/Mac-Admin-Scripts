#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: DockMaster.sh
#
# Purpose: Set the contents of the dock on login based on computer type (cohort)
# and what applications are available on the local machine.
#
# Changelog
# 7/26/17:  - Fixed a typo with powerpoint
# 2/20/17:  - Replaced the sleep 5 on line 16 with the wait loop.
#			- Cleaned up script to make it in line with my styling.
#			- I removed the "originally created by" in the header, this is
#			  so customized that it no longer has any part of the original in it.
#			- ALL of the comments!
#
# 9/15/16:  - Removed network connect since we don't use it anymore.
#
#

# we need to wait for the dock to actually start
until [[ $(pgrep Dock) ]]; do
    wait
done

# Find the JAMF binary
jamfbinary=$(/usr/bin/which jamf)

# Chesk to see if we have dockutil installed, install if not
if [ ! -f "/usr/local/bin/dockutil" ]; then
	echo "Installing DockUtil from JSS"
	"$jamfbinary" policy -event dockutil
	if [ ! -f "/usr/local/bin/dockutil" ]; then # Did the install work?
		echo "Unable to install DockUtil, aborting!"
		exit 1
	fi
fi
du="/usr/local/bin/dockutil"

# Get the current logged in user that we'll be modifying
if [ ! -n "$3" ]; then
	user=$3
else
	user=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
fi
echo "Running DockMaster on $user"

# FInd out the type of machine using our COHORT receipt
if [ -f /Library/JAMF\ DM/Cohort/*.txt ]; then
	cohort=$(cat /Library/JAMF\ DM/Cohort/*.txt)
	echo "Cohort set to $cohort"
else
	echo "No cohort available. Adding default icons only."
	cohort="NONE"
fi

# Bundled apps checker functions
officeIcons ()
{
	wordversion=$(defaults read "/Applications/Microsoft Word.app/Contents/Info.plist" CFBundleShortVersionString)
	# Checking for Word/Office 2016
	sleep 2
	if [[ $wordversion == "15."* ]]; then
		echo "Adding Office 2016 apps"
		$du --add "/Applications/Microsoft Word.app" --no-restart /Users/$user
		$du --add "/Applications/Microsoft Excel.app" --no-restart /Users/$user
		$du --add "/Applications/Microsoft Outlook.app" --no-restart /Users/$user
		$du --add "/Applications/Microsoft PowerPoint.app" --no-restart /Users/$user
	else
		# Checking for Office 2011
		if [ -d "/Applications/Microsoft Office 2011/" ]; then
			echo "Adding Office 2011 apps"
			$du --add "/Applications/Microsoft Office 2011/Microsoft Word.app" --no-restart /Users/$user
			$du --add "/Applications/Microsoft Office 2011/Microsoft Excel.app" --no-restart /Users/$user
			$du --add "/Applications/Microsoft Office 2011/Microsoft Outlook.app" --no-restart /Users/$user
			$du --add "/Applications/Microsoft Office 2011/Microsoft PowerPoint.app" --no-restart /Users/$user
		fi
	fi
}

iWorkIcons ()
{
	echo "Adding installed iWork Apps"
	if [ -e "/Applications/Pages.app" ]; then
		$du --add "/Applications/Pages.app" --no-restart /Users/$user
	fi
	if [ -e "/Applications/Numbers.app" ]; then
		$du --add "/Applications/Numbers.app" --no-restart /Users/$user
	fi
	if [ -e "/Applications/Keynote.app" ]; then
		$du --add "/Applications/Keynote.app" --no-restart /Users/$user
	fi
	# We check for every app here one by one because they're installed separately,
	# we don't do this for office because that's a single package that gets laid.
}

# Clear the default dock
echo "Removing all items from the dock"
$du --remove all --no-restart /Users/$user
sleep 2 # we need to give this time to work or we'll get errors with "replacing" items instead of adding them


### The next secion is where you'll want to add your dock items based on computer type/COHORT ###

#######################################
#### Items for all/no cohorts
#######################################
echo "Adding browsers"
$du --add "/Applications/Safari.app" --no-restart /Users/$user
if [ -e "/Applications/Google Chrome.app/" ]; then
	$du --add "/Applications/Google Chrome.app" --no-restart /Users/$user
fi
# We have two different firefox types, lets figure out which one is installed
if [ -e /Applications/Firefox* ]; then
	firefox=$(find /Applications -type d -maxdepth 1 -name Firefox*)
	$du --add "$firefox" --no-restart /Users/$user
fi
# Add Office icons to all cohorts
officeIcons
# Every user gets a downloads folder too
echo "Adding the Downloads folder"
$du --add "~/Downloads" --view fan --display stack --sort dateadded --no-restart /Users/$user

#######################################
#### Add dock items for FACSTAFF cohort
#######################################
if [ $cohort == "FACSTAFF" ]; then
	echo "Adding apps for FACSTAFF"
	$du --add "/Applications/Calendar.app" --no-restart /Users/$user
	$du --add "/Applications/Preview.app" --no-restart /Users/$user
	$du --add "/Applications/iTunes.app" --no-restart /Users/$user
	$du --add "/Applications/Photo Booth.app" --no-restart /Users/$user
	$du --add "/Applications/Time Machine.app" --no-restart /Users/$user
	if [ -e "/Library/KeyAccess/KeyCheckout.app/" ]; then
		$du --add "/Library/KeyAccess/KeyCheckout.app" --no-restart /Users/$user
	fi
	$du --add "/Applications/Self Service.app" --no-restart /Users/$user
	$du --add "/Applications/App Store.app" --no-restart /Users/$user
	$du --add "/Applications/System Preferences.app" --position end --no-restart /Users/$user
	# This should be the end of the applications in the dock, anything after should be a folder
	$du --add "/Applications" --view grid --display folder --sort name --no-restart /Users/$user
	$du --add "~/Documents" --view fan --display stack --sort dateadded --no-restart /Users/$user

#######################################
#### Add dock items for OFFICE cohort
#######################################
elif [ $cohort == "OFFICE" ]; then
	echo "Adding apps for OFFICE cohort"
	$du --add "/Applications/Launchpad.app" --position beginning --no-restart /Users/$user
	$du --add "/Applications/Contacts.app" --no-restart /Users/$user
	$du --add "/Applications/Calendar.app" --no-restart /Users/$user
	$du --add "/Applications/Notes.app" --no-restart /Users/$user
	$du --add "/Applications/Messages.app" --no-restart /Users/$user
	$du --add "/Applications/Self Service.app" --no-restart /Users/$user
	$du --add "/Applications/System Preferences.app" --position end --no-restart /Users/$user
	# This should be the end of the applications in the dock, anything after should be a folder
	$du --add "/Applications" --view grid --display folder --sort name --no-restart /Users/$user

#######################################
#### Add dock items for PUBLIC cohorts
#### This one has a lot of different cohorts,
#### You can break it down as much as you want of course
#######################################
elif [ $cohort == "LAB" ] || [ $cohort == "STUDIO" ] || [ $cohort == "SUITE" ] || [ $cohort == "SMART-CLASSROOM" ]; then
	echo "Adding apps for $cohort cohort"
	iWorkIcons
	$du --add "/Applications/Image Capture.app" --no-restart /Users/$user
	$du --add "/Applications/Preview.app" --no-restart /Users/$user
	# This should be the end of the applications in the dock, anything after should be a folder
	$du --add "/Applications" --view grid --display folder --sort name --no-restart /Users/$user

#######################################
#### Add dock items for CHECKOUT cohort
#######################################
elif [ $cohort == "CHECKOUT" ]; then
	echo "Adding apps for CHECKOUT cohort"
	$du --add "/Applications/Calendar.app" --no-restart /Users/$user
	$du --add "/Applications/Preview.app" --no-restart /Users/$user
	$du --add "/Applications/iTunes.app" --no-restart /Users/$user
	$du --add "/Applications/Photo Booth.app" --no-restart /Users/$user
	$du --add "/Applications/Time Machine.app" --no-restart /Users/$user
	if [ -e "/Library/KeyAccess/KeyCheckout.app/" ]; then
		$du --add "/Library/KeyAccess/KeyCheckout.app" --no-restart /Users/$user
	fi
	$du --add "/Applications/Self Service.app" --no-restart /Users/$user
	$du --add "/Applications/App Store.app" --no-restart /Users/$user
	$du --add "/Applications/System Preferences.app" --position end --no-restart /Users/$user
	# This should be the end of the applications in the dock, anything after should be a folder
	$du --add "/Applications" --view grid --display folder --sort name --no-restart /Users/$user
	$du --add "~/Documents" --view fan --display stack --sort dateadded --no-restart /Users/$user

#######################################
#### Add dock items for KIOSK cohort
#######################################
elif [ $cohort == "KIOSK" ]; then
	echo "Adding apps for KIOSK cohort"

fi #end of cohorts

# Restart the dock after everything is done
sleep 5
killall Dock
exit 0
