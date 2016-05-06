#!/bin/sh
#
########################################################################
# Original created By: Colin Bohn, Stanwood-Camano School District
# 
# Customized by John Mahlman, University of the Arts Philadelphia
# Last Updated May 6, 2016
#
# Name: DockMaster
# Purpose: Set the contents of the dock on login based on
# cohort and what applications are available on the local machine.
########################################################################


#######################################
#### Where's our JAMF binary?
#######################################
jamfbinary=$(/usr/bin/which jamf)

#######################################
##### Lets make sure we have DockUtil
#######################################
if [ ! -f "/usr/local/bin/dockutil" ]; then
	echo "Installing DockUtil from JSS"
	"$jamfbinary" policy -event dockutil
	if [ ! -f "/usr/local/bin/dockutil" ]; then
		echo "Unable to install DockUtil, aborting!"
		exit 1
	fi
fi
du="/usr/local/bin/dockutil"

#######################################
##### Find out who we are modifying
#######################################
if [ ! -n "$3" ]; then
	user=$3
else
	user=$(/usr/bin/who | /usr/bin/awk '/console/{ print $1 }')
fi

echo "Running DockMaster on $user"

#######################################
##### Let's find that cohort...
#######################################
if [ -f /Library/JAMF\ DM/Cohort/*.txt ]; then
	cohort=`cat /Library/JAMF\ DM/Cohort/*.txt`
	echo "Cohort set to $cohort"
else
	echo "No cohort available! Using settings for NO COHORT."
	cohort=""
fi

#######################################
#### Office Checker Function
#######################################
officeIcons ()
{
	wordversion=$(/usr/bin/mdls -name kMDItemVersion "/Applications/Microsoft Word.app/")
	# Checking for Office 2016
	if [[ $wordversion  == *" 15."* ]]; then
		echo "Adding Office 2016 apps"
		$du --add "/Applications/Microsoft Word.app" --no-restart /Users/$user
		$du --add "/Applications/Microsoft Excel.app" --no-restart /Users/$user
		$du --add "/Applications/Microsoft Outlook.app" --no-restart /Users/$user
		$du --add "/Applications/Microsoft Powerpoint.app" --no-restart /Users/$user
	else
		# Checking for Office 2011
		if [ -d "/Applications/Microsoft Office 2011/" ]; then
			echo "Adding Office 2011 apps"
			$du --add "/Applications/Microsoft Office 2011/Microsoft Word.app" --no-restart /Users/$user
			$du --add "/Applications/Microsoft Office 2011/Microsoft Excel.app" --no-restart /Users/$user
			$du --add "/Applications/Microsoft Office 2011/Microsoft Outlook.app" --no-restart /Users/$user
			$du --add "/Applications/Microsoft Office 2011/Microsoft Powerpoint.app" --no-restart /Users/$user
		fi
	fi # End office additions here
}

#######################################
#### Get a clean slate going here
#######################################
echo "Removing all items from the dock"
$du --remove all --no-restart /Users/$user

#######################################
#### Everyone likes a Downloads folder
#######################################
echo "Adding the Downloads folder"
$du --add '~/Downloads' --view fan --display stack --sort dateadded --no-restart /Users/$user

#######################################
#### Add universal apps
#### This runs for all cohorts
#######################################
echo "Adding browsers"
$du --add "/Applications/Safari.app" --no-restart /Users/$user

if [ -d "/Applications/Google Chrome.app/" ]; then
	$du --add "/Applications/Google Chrome.app" --no-restart /Users/$user
fi

if [ -d "/Applications/Firefox-ESR-38.app/" ]; then
	$du --add "/Applications/Firefox-ESR-38.app" --no-restart /Users/$user
fi

#######################################
#### Add dock items for FACSTAFF only
#######################################
if [ $cohort == "FACSTAFF" ]; then
	echo "Adding apps for FACSTAFF"
	officeIcons
	$du --add "/Applications/Calendar.app" --no-restart /Users/$user
	$du --add "/Applications/Preview.app" --no-restart /Users/$user
	$du --add "/Applications/iTunes.app" --no-restart /Users/$user
	$du --add "/Applications/Photo Booth.app" --no-restart /Users/$user
	$du --add "/Applications/Time Machine.app" --no-restart /Users/$user
	if [ -d "/Library/KeyAccess/KeyCheckout.app/" ]; then
		$du --add "/Library/KeyAccess/KeyCheckout.app" --no-restart /Users/$user
	fi
	if [ -d "/Applications/Network Connect.app/" ]; then
		$du --add "/Applications/Network Connect.app" --no-restart /Users/$user
	fi
	$du --add "/Applications/Self Service.app" --no-restart /Users/$user
	$du --add "/Applications/App Store.app" --no-restart /Users/$user
	$du --add "/Applications/System Preferences.app" --position end --no-restart /Users/$user
	# This should be the end of the applications in the dock, anything after should be a folder
	$du --add "/Applications" --view grid --display folder --sort name --no-restart /Users/$user
	$du --add '~/Documents' --view fan --display stack --sort dateadded --no-restart /Users/$user
fi

#######################################
#### Add dock items for OFFICE only
#######################################
if [ $cohort == "OFFICE" ]; then
	echo "Adding apps for OFFICE only"
	officeIcons
	$du --add "/Applications/Launchpad.app" --position beginning --no-restart /Users/$user
	$du --add "/Applications/Contacts.app" --no-restart /Users/$user
	$du --add "/Applications/Calendar.app" --no-restart /Users/$user
	$du --add "/Applications/Notes.app" --no-restart /Users/$user
	$du --add "/Applications/Messages.app" --no-restart /Users/$user	
	$du --add "/Applications/Self Service.app" --no-restart /Users/$user
	$du --add "/Applications/System Preferences.app" --position end --no-restart /Users/$user
	# This should be the end of the applications in the dock, anything after should be a folder
	$du --add "/Applications" --view grid --display folder --sort name --no-restart /Users/$user
fi

#######################################
#### Add dock items for PUBLIC cohorts
#### This one has a lot of different cohorts,
#### You can break it down as much as you want
#######################################
if [ $cohort == "PUBLIC" ]; then
	echo "Adding apps for PUBLIC only"
fi

#######################################
#### Add dock items for CHECKOUT only
#######################################
if [ $cohort == "CHECKOUT" ]; then
	echo "Adding apps for CHECKOUT only"
fi

#######################################
#### Add dock items for KIOSK only
#######################################
if [ $cohort == "KIOSK" ]; then
	echo "Adding apps for KIOSK only"
fi

# Restart the dock after everything is done
killall Dock
