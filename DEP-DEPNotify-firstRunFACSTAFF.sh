#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: DEP-DEPNotify-firstRunFACSTAFF
#
# Purpose: Install and run DEPNotify at enrollment time and do some final touches
# for the users.  It also checks for software updates and installs them if found.
# Using a custom build of DEPNotify from slack user @fgd.
#
# Changelog
#
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

# Let's caffinate the mac because this can take long
caffeinate -d -i -m -u &
caffeinatepid=$!

# Install DEPNotify
$JAMFBIN policy -event install_depnotify
DNLOG=/var/tmp/depnotify.log

#Configure DEPNotify
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify PathToPlistFile /var/tmp/
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify RegisterMainTitle "Assignment..."
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify RegistrationButtonLabel Assign
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldUpperLabel "Assigned User"
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldUpperPlaceholder "dadams"
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldLowerLabel "Asset Tag"
sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldLowerPlaceholder "UA42LAP1337"

echo "Command: MainTitle: Click Assign to begin Deployment" >> $DNLOG
echo "Status: Just waiting for you..." >> $DNLOG
echo "Command: Image: /var/tmp/uarts-logo.png" >> $DNLOG
echo "Command: Determinate: 8" >> $DNLOG
#echo "Command: WindowStyle: NotMovable" >> $DNLOG
# re-enable the above line after we update to jamf 10 and add kext whitelisting

#Open DepNotify
sudo -u "$CURRENTUSER" /var/tmp/DEPNotify.app/Contents/MacOS/DEPNotify &

# get user input...
echo "Command: ContinueButtonRegister: Assign" >> $DNLOG
DNPLIST=/var/tmp/DEPNotify.plist
# hold here until the user enters something
while : ; do
	[[ -f $DNPLIST ]]	&& break
	sleep 1
done
# grab the username from the plist that is created so we can use it to automaticlaly create the account
USERNAME=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Assigned User'" | tr [A-Z] [a-z])

echo "Command: MainTitle: Preparing the system for Deployment" >> $DNLOG
echo "Command: MainText: Please do not shutdown, reboot, or close your device, it will reboot automatically when complete." >> $DNLOG

# Do the things! Eventually we'll just make one policy to run instead of calling several different ones
echo "Status: Installing Management Framework..." >> $DNLOG
$JAMFBIN policy -event enroll-firstRunFACSTAFF

echo "Status: Installing Pulse VPN client..." >> $DNLOG
$JAMFBIN policy -event enroll-pulse

echo "Status: Installing Pharos..." >> $DNLOG
$JAMFBIN policy -event enroll-pharos

echo "Status: Installing KeyClient..." >> $DNLOG
$JAMFBIN policy -event enroll-keyclient

echo "Status: Installing Microsoft Office 2016..." >> $DNLOG
$JAMFBIN policy -event enroll-office2016

# after we update to jamf 10 and add kext whitelisting we can change what this says
echo "Status: Symantec Antivirus, please approve when asked..." >> $DNLOG
$JAMFBIN policy -event enroll-sep-facstaff

echo "Status: Assigning and renaming device..." >> $DNLOG
$JAMFBIN policy -event enroll-assignDevice

echo "Status: Creating local user account with password as username..." >> $DNLOG
$JAMFBIN createAccount -username $USERNAME -realname $USERNAME -password $USERNAME -admin

echo "Status: Updating Inventory..." >> $DNLOG
$JAMFBIN recon

echo "Command: MainTitle: Almost done!" >> $DNLOG

echo "Status: Checking for and installing any OS updates..." >> $DNLOG
/usr/sbin/softwareupdate -ia

kill "$caffeinatepid"

echo "Command: RestartNow:" >> $DNLOG

# Remove DEPNotify and the logs
rm -Rf /var/tmp/DEPNotify.app
rm -Rf /var/tmp/uarts-logo.png
rm -Rf $DNLOG
rm -Rf $DNPLIST
