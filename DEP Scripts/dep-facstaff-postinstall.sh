#!/bin/sh
## postinstall

echo  "disable auto updates ASAP" >> /var/log/jamf.log
	/usr/sbin/softwareupdate --schedule off

# Disable diagnostic data
	SUBMIT_DIAGNOSTIC_DATA_TO_APPLE=FALSE
	SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS=FALSE

## Make the main script executable
echo  "setting main script permissions" >> /var/log/jamf.log
	chmod a+x /var/tmp/com.uarts.DEPprovisioning.facstaff.sh

## Set permissions and ownership for launch daemon
echo  "set LaunchDaemon permissions" >> /var/log/jamf.log
	chmod 644 /Library/LaunchDaemons/com.uarts.launch.plist
	chown root:wheel /Library/LaunchDaemons/com.uarts.launch.plist

## Load launch daemon into the Launchd system
echo  "load LaunchDaemon" >> /var/log/jamf.log
	launchctl load /Library/LaunchDaemons/com.uarts.launch.plist

exit 0		## Success
exit 1		## Failure
