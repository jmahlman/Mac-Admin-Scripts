#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: DEP-DEPNotify-firstRunFACSTAFF
#
# Purpose: Install and run DEPNotify at enrollment time and do some final touches
# for the users.  It also checks for software updates and installs them if found.
#
# Changelog
#
# 5/8/18	- Combined with LaunchDaemon script. This will remain for reference.
#         - Changed around a bunch of things since we're moving to a single policy AND LaunchDaemon.
#					-	Moving to DeterminateManual so we can control the progress bar better.
# 5/3/18	-	Trying a new method for setting username and asset tag.  See DEP-DEPNotify-assignAndRename updates. (REVERTED)
# 4/25/18	-	Moved AV install up in the process.
# 4/23/18	-	Added a "wait for dock" loop to it will wait until a user is logged in
#					-	Moved the caffinate command down so it will only run if DEPNotify is running and waiting for user input
# 4/20/18	-	Fixed a small typo...it really didn't change anything.
# 4/19/18 - Added defaults for DEPNotify pref file to allow for assignment
#					- Added the loop for user entry, hopefully that works
#					- Renamed script, will eventually make a generalized script for all cohorts
# 4/10/18 - Rearrange the policies
# 4/9/18  - Added ContinueButtonRegister comment
# 2/22/18	- Initial script creation
#
#
JAMFBIN=$(/usr/bin/which jamf)

# Get the current logged in user that we'll be modifying
if [ ! -z "$3" ]; then
	CURRENTUSER=$3
else
	CURRENTUSER=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
fi

# DEPNotify Log file
DNLOG=/var/tmp/depnotify.log

# Configure DEPNotify
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify PathToPlistFile /var/tmp/
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify RegisterMainTitle "Assignment..."
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify RegistrationButtonLabel Assign
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldUpperLabel "Assigned User"
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldUpperPlaceholder "dadams"
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldLowerLabel "Asset Tag"
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldLowerPlaceholder "UA42LAP1337"

echo "Command: MainTitle: Click Assign to begin Deployment" >> $DNLOG
echo "Command: MainText: This process will assign this device and install base software." >> $DNLOG
echo "Command: Image: /var/tmp/uarts-logo.png" >> $DNLOG
echo "Command: DeterminateManual: 5" >> $DNLOG
#echo "Command: WindowStyle: NotMovable" >> $DNLOG
# re-enable the above line after we update to jamf 10 and add kext whitelisting

# Open DepNotify
sudo -u "$CURRENTUSER" /var/tmp/DEPNotify.app/Contents/MacOS/DEPNotify &
# We'll re-add -fullScreen once we upgrade to jamf 10 probably

# Let's caffinate the mac because this can take long
/usr/bin/caffeinate -d -i -m -u &
caffeinatepid=$!

# get user input...
echo "Command: ContinueButtonRegister: Assign" >> $DNLOG
echo "Status: Just waiting for you..." >> $DNLOG
DNPLIST=/var/tmp/DEPNotify.plist
# hold here until the user enters something
while : ; do
	[[ -f $DNPLIST ]] && break
	sleep 1
done
# grab the username from the plist that is created so we can use it to automaticlaly create the account
USERNAME=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Assigned User'" | tr [A-Z] [a-z])

echo "Command: MainTitle: Preparing the system for Deployment" >> $DNLOG
echo "Command: MainText: Please do not shutdown, reboot, or close your device, it will automatically reboot when complete." >> $DNLOG

echo "Command: DeterminateManualStep:" >> $DNLOG
# Do the things! We're calling a single policy now.
echo "Status: Installing base software..." >> $DNLOG
$JAMFBIN policy -event enroll-firstRunFACSTAFF

echo "Command: DeterminateManualStep:" >> $DNLOG
echo "Status: Creating local user account with password as username..." >> $DNLOG
$JAMFBIN createAccount -username $USERNAME -realname $USERNAME -password $USERNAME -admin

echo "Command: DeterminateManualStep:" >> $DNLOG
echo "Status: Assigning and renaming device..." >> $DNLOG
$JAMFBIN policy -event enroll-assignDevice

echo "Status: Updating Inventory..." >> $DNLOG
$JAMFBIN recon

echo "Command: MainTitle: Almost done!" >> $DNLOG
echo "Command: DeterminateManualStep:" >> $DNLOG
echo "Status: Checking for and installing any OS updates..." >> $DNLOG
/usr/sbin/softwareupdate -ia

kill "$caffeinatepid"

echo "Command: RestartNow:" >>  $DNLOG

# Remove DEPNotify and the logs
/bin/rm -Rf /var/tmp/DEPNotify.app
/bin/rm -Rf /var/tmp/uarts-logo.png
/bin/rm -Rf $DNLOG
/bin/rm -Rf $DNPLIST
