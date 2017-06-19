#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: Adobe-RUMWithProgress
#
# Purpose: This script uses CocoaDialog to show which updates are available for Adobe CC and asks
# if they would like to install those updates.  If they choose to install updates it will
# show a progress bar to the user and begin installing updates. The pregress bar doesn't change,
# it's only there to show the user that something is actucally happening.
#
# Changelog
#
# 6/19/17 - Removed the "wait" command at the end because it was just causing things to hang
#					- Added some wait 0.2 lines to allow the script some time to catch up
#					- Fixed Dreamweaver channel ID
#					- Added jamf_bin to determine which jamf binary to use
# 3/23/17 - Added more to "super-echo" to make it nicer for the user to read what's available for updates
# 2/21/17 - Cleaned up script to make it in line with my styling.
#
#

icons=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources
rumlog=/var/tmp/RUMupdate.log # mmmmmm, rum log
CD_APP=/Applications/Utilities/CocoaDialog.app/
CocoaDialog="$CD_APP/Contents/MacOS/CocoaDialog"
oldRUM=/usr/sbin/RemoteUpdateManager # this is where RUM used to live pre-10.11
rum=/usr/local/bin/RemoteUpdateManager # post-10.11
jamf_bin=$(/usr/bin/which jamf)

# Installer function
installUpdates ()
{
	# create a named pipe
	rm -f /tmp/hpipe
	mkfifo /tmp/hpipe
	wait 0.2

	# create a background job which takes its input from the named pipe
	$CocoaDialog progressbar --indeterminate --float --icon-file "$icons/Sync.icns" \
		--title "UArts Adobe Updater" --text "Downloading and Installing Updates, this may take some time..." \
	--width "500" --height "115" < /tmp/hpipe &

	wait 0.2
	# associate file descriptor 3 with that pipe and send a character through the pipe
	exec 3<> /tmp/hpipe

	echo -n >&3

	# do all of your work here
	$rum --action=install

	# now turn off the progress bar by closing file descriptor 3
	exec 3>&-
	rm -f /tmp/hpipe

	exit 0
}


#############
#  Script   #
#############

# does CocoaDialog Exist?
if [ ! -f $CocoaDialog ] ; then
	echo "Installing Cocoa Dialog from JSS"
	jamf_bin policy -event installcocoaDialog
	if [ ! -f $CocoaDialog ] ; then
		echo "Couldn't install Cocoa Dialog! Exiting."
		exit 1
	fi
fi

# old RUM installed?
if [ -f $oldRUM ] ; then
    rm -rf $oldRUM
fi

# new/current RUM installed?
if [ ! -f $rum ] ; then
	echo "Installing RUM from JSS"
	jamf_bin policy -event installRUM
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
	| sed 's/SPRK/Experience\ Design\ Beta/g' \
	| sed 's/KBRG/Bridge/g' \
	| sed 's/AICY/InCopy/g' \
	| sed 's/ANMLBETA/Character\ Animator\ Beta/g' \
	| sed 's/DRWV/Dreamweaver/g' \
	| sed 's/IDSN/InDesign/g' \
	| sed 's/PPRO/Premiere\ Pro/g' \
	| sed 's/ESHR/Project\ Felix/g' `

if [ "$(grep "Following Updates are applicable" $rumlog)" == "Following Updates are applicable on the system :" ] ; then
	rv=`$CocoaDialog yesno-msgbox --float --icon-file "$icons/ToolbarInfo.icns" --no-cancel \
		--title "UArts Adobe Updater" --text "Do you want to install the following updates?" --informative-text "$secho"`
	if [ "$rv" == "1" ]; then
		installUpdates
	elif [ "$rv" == "2" ]; then
		exit 0
	fi
else
	$CocoaDialog ok-msgbox --float --no-cancel --icon-file "$icons/ToolbarInfo.icns" \
		--title "UArts Adobe Updater" --text "There are no Adobe Updates available."
	if [ "$rv" == "1" ]; then
		exit 0
	fi
fi
