#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: Adobe-RUMWithProgress-jamfhelper
#
# Purpose: This script uses jamfhelper to show which updates are available for Adobe CC and asks
# if they would like to install those updates.  If they choose to install updates it will begin installing updates.
#
# Changelog
#
# 5/3/18  - Just adding "Uarts" to the window title.
# 4/25/18	-	Thanks for user remyb we've decided to move to using jamfhelper instead of cocoadialog. Instead of
#						updating the old script, I'm just going to create this new one so non-jamf people can still use the other.
# 4/25/18 - Changed all CocoaDialog stuff to jamfHelper - remyb (Thanks!)
# 2/22/18 - Cleaned up some logic to make it prettier
# 1/8/18  - Updated channel ID list with new channels and names
# 9/8/17  - Added link to channel ID list from Adobe
# 8/31/17 - Just some cleaning up
# 8/29/17 - Added a "caffeinate" command when installing updates to stop systems from sleeping during long installs
# 6/19/17 - Removed the "wait" command at the end because it was just causing things to hang
#         - Added some sleep 0.2 lines to allow the script some time to catch up
#         - Fixed Dreamweaver channel ID
#         - Added jamf_bin to determine which jamf binary to use
# 3/23/17 - Added more to "super-echo" to make it nicer for the user to read what's available for updates
# 2/21/17 - Cleaned up script to make it in line with my styling.
#

icons=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources
rumlog=/var/tmp/RUMupdate.log # mmmmmm, rum log
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
oldRUM=/usr/sbin/RemoteUpdateManager # this is where RUM used to live pre-10.11
rum=/usr/local/bin/RemoteUpdateManager # post-10.11
jamf_bin=/usr/local/bin/jamf

# Installer function
installUpdates ()
{
    # Let's caffinate the mac because this can take long
    caffeinate -d -i -m -u &
    caffeinatepid=$!

    # Displaying jamfHelper
    "$jamfHelper" -windowType hud -title "UArts Adobe Updater" -description "Downloading and Installing Updates, this may take some time..." \
    -icon "$icons/Sync.icns" -lockHUD > /dev/null 2>&1 &

    # do all of your work here
    $rum --action=install

    # Kill jamfhelper
    killall jamfHelper > /dev/null 2>&1

    # No more caffeine please. I've a headache.
    kill "$caffeinatepid"

    exit 0
}


#############
#  Script   #
#############


# old RUM installed?
if [ -f $oldRUM ] ; then
    rm -rf $oldRUM
fi

# new/current RUM installed?
if [ ! -f $rum ] ; then
	echo "Installing RUM from JSS"
	$jamf_bin policy -event installRUM
	if [ ! -f $rum ] ; then
		echo "Couldn't install RUM! Exiting."
		exit 1
	fi
fi

# Not that it matters but we'll remove the old log file if it exists
if [ -f $rumlog ] ; then
    rm $rumlog
fi

#run RUM and output to the log file
touch $rumlog
$rum --action=list > $rumlog

# super-echo!  Echo pretty-ish output to user. Replaces Adobes channel IDs with actual app names
# I think it's silly that I have to do this, but whatever. :)
# Adobe channel ID list: https://helpx.adobe.com/enterprise/package/help/apps-deployed-without-their-base-versions.html
secho=`sed -n '/Following*/,/\*/p' $rumlog \
    | sed 's/Following/The\ Following/g' \
    | sed 's/ACR/Acrobat/g' \
    | sed 's/AEFT/After\ Effects/g' \
    | sed 's/AME/Media\ Encoder/g' \
    | sed 's/AUDT/Audition/g' \
    | sed 's/FLPR/Animate/g' \
    | sed 's/ILST/Illustrator/g' \
    | sed 's/MUSE/Muse/g' \
    | sed 's/PHSP/Photoshop/g' \
    | sed 's/PRLD/Prelude/g' \
    | sed 's/SPRK/XD/g' \
    | sed 's/KBRG/Bridge/g' \
    | sed 's/AICY/InCopy/g' \
    | sed 's/ANMLBETA/Character\ Animator\ Beta/g' \
    | sed 's/DRWV/Dreamweaver/g' \
    | sed 's/IDSN/InDesign/g' \
    | sed 's/PPRO/Premiere\ Pro/g' \
    | sed 's/LTRM/Lightroom\ Classic/g' \
    | sed 's/CHAR/Character\ Animator/g' \
    | sed 's/ESHR/Dimension/g' `

if [ "$(grep "Following Updates are applicable" $rumlog)" ] ; then
  userChoice=$("$jamfHelper" -windowType hud -lockHUD -title "UArts Adobe Updater" \
  -icon "$icons/ToolbarInfo.icns" -description "Do you want to install these updates?

$secho" -button1 "Yes" -button2 "No")
    if [ "$userChoice" == "0" ]; then
        echo "User said yes, installing $secho"
        installUpdates
    elif [ "$userChoice" == "2" ]; then
        echo "User said no"
        exit 0
    fi
else
    "$jamfHelper" -windowType hud -title "UArts Adobe Updater" -description "There are no Adobe Updates available." \
    -icon "$icons/ToolbarInfo.icns" -button1 Ok -defaultButton 1
    exit 0
fi
