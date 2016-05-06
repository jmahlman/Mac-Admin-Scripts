#!/bin/sh
#
# Written by John Mahlman
# 2/10/2016
#
# This script uses CocoaDialog to show which updates are available for Adobe CC and asks
# if they would like to install those updates.  If they choose to install updates it will
# show a progress bar to the user and begin installing updates. The pregress bar doesn't change, 
# it's only there to show the user that something is actucally happening.  
#
#
#############
# Variables #
#############
icons=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources
rumlog=/var/tmp/RUMupdate.log # mmmmmm, rum log
CD_APP=/Applications/Utilities/CocoaDialog.app/
CocoaDialog="$CD_APP/Contents/MacOS/CocoaDialog"
oldRUM=/usr/sbin/RemoteUpdateManager # this is where RUM used to live pre-10.11
rum=/usr/local/bin/RemoteUpdateManager # post-10.11

#############
# Functions #
#############

installUpdates ()
{
	# the code in here was borrowed from the cocoaDialog website. I eventually want the progress bar to show progress
	
	# create a named pipe
	rm -f /tmp/hpipe
	mkfifo /tmp/hpipe

	# create a background job which takes its input from the named pipe
	$CocoaDialog progressbar --indeterminate --float --icon-file "$icons/Sync.icns" \
		--title "Adobe Updates" --text "Installing Updates..." --width "500" --height "115" < /tmp/hpipe &

	# associate file descriptor 3 with that pipe and send a character through the pipe
	exec 3<> /tmp/hpipe
	echo -n >&3

	# do all of your work here
	$rum --action=install

	# now turn off the progress bar by closing file descriptor 3
	exec 3>&-
	# wait for all background jobs to exit
	wait
	rm -f /tmp/hpipe

	exit 0
}


#############
#  Script   #
#############

# does CocoaDialog Exist?
if [ ! -f $CocoaDialog ] ; then
	echo "Installing Cocoa Dialog from JSS"
	jamf policy -event installcocoaDialog
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
	jamf policy -event installRUM
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
secho=`sed -n '/Adobe*/,/\*/p' $rumlog # super-echo!  Echo pretty-ish output to user. 

if [ "$(grep "Following Updates are applicable" $rumlog)" == "Following Updates are applicable on the system :" ] ; then
	rv=`$CocoaDialog yesno-msgbox --float --icon-file "$icons/ToolbarInfo.icns" --no-cancel \
		--title "Adobe Updates" --text "Do you want to install the following updates?" --informative-text "$secho"`
	if [ "$rv" == "1" ]; then 
		installUpdates
	elif [ "$rv" == "2" ]; then
		exit 0
	fi
else
	$CocoaDialog ok-msgbox --float --no-cancel --icon-file "$icons/ToolbarInfo.icns" \
		--title "Adobe Updates" --text "There are no Adobe Updates available."
	if [ "$rv" == "1" ]; then 
		exit 0
	fi
fi
