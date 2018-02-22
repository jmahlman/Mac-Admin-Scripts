#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: DEPNotify-Jamf
#
# Purpose: Install and run DEPNotify at enrollment time and do some final touches
# for the users.  It also checks for software updates and installs them if found.
#
# Changelog
#
# 2/22/18	- Initial script creation
#
#

# Install DEPNotify
/usr/local/jamf/bin/jamf policy -event install_depnotify

#Configure DEPNotify
echo "Command: MainTitle: Preparing the system for Deployment" >> /var/tmp/depnotify.log
echo "Command: MainText: Installing some base software... \n \n \
Please do not shutdown, reboot, or close your laptop until this is complete." >> /var/tmp/depnotify.log
echo "Command: Image: /var/tmp/uarts-logo.png" >> /var/tmp/depnotify.log
echo "Command: Determinate: 8" >> /var/tmp/depnotify.log
echo "Command: WindowStyle: NotMovable" >> /var/tmp/depnotify.log

#Open DepNotify
/var/tmp/DEPNotify.app/Contents/MacOS/DEPNotify -fullScreen &

# Do the things!
echo "Status: Installing Self Service..." >> /var/tmp/depnotify.log
# I know this isn't REALLY installing self service, it's just easier for the user to see
/usr/local/jamf/bin/jamf policy -event $4

echo "Status: Installing Pulse VPN client..." >> /var/tmp/depnotify.log
/usr/local/jamf/bin/jamf policy -event enroll-pulse

echo "Status: Installing Pharos..." >> /var/tmp/depnotify.log
/usr/local/jamf/bin/jamf policy -event enroll-pharos

echo "Status: Installing Microsoft Office 2016..." >> /var/tmp/depnotify.log
/usr/local/jamf/bin/jamf policy -event enroll-office2016

echo "Status: Renaming machine..." >> /var/tmp/depnotify.log
/usr/local/jamf/bin/jamf policy -event renameByAPI

echo "Status: Updating server inventory..." >> /var/tmp/depnotify.log
/usr/local/jamf/bin/jamf recon

# Take care of software updates here
echo "Status: Checking for system updates..." >> /var/tmp/depnotify.log
/usr/sbin/softwareupdate -l >> /var/tmp/swupdate.log
if [ "$(grep "No new software available." /var/tmp/swupdate.log)" ] ; then
  echo "Status: No updates available." >> /var/tmp/depnotify.log
  echo "Command: Quit: Your machine is ready to use." >> /var/tmp/depnotify.log
else
  echo "Status: Updates available, installing..." >> /var/tmp/depnotify.log
  /usr/sbin/softwareupdate -a -i
  echo "Command: Restart: Deployment complete, your computer will now restart." >> /var/tmp/depnotify.log
fi

# Remove DEPNotify and the log
rm -Rf /var/tmp/DEPNotify.app
rm -Rf /var/tmp/uarts-logo.png
rm -Rf /var/tmp/depnotify.log
rm -Rf /var/tmp/swupdate.log
