#!/bin/sh
## postinstall

#!/bin/sh

echo  "disable auto updates ASAP" >> /var/log/jamf.log
	defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool NO
	defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist ConfigDataInstall -bool NO
	defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool NO
	defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdateRestartRequired -bool NO
	defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdate -bool NO
	defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool NO


echo  "set power management" >> /var/log/jamf.log
#set power management student settings temporarily
	pmset -c displaysleep 60 disksleep 0 sleep 0 womp 0 ring 0 autorestart 0 halfdim 1 sms 1
	pmset -b displaysleep 5 disksleep 1 sleep 10 womp 0 ring 0 autorestart 0 halfdim 1 sms 1
	pmset -a darkwakes 0 standby 0 standbydelay 0

# Disable powernap
	pmset -a darkwakes 0
	pmset -a standby 0
	pmset -a standbydelay 0

echo  "disable login pop ups" >> /var/log/jamf.log
# Determine OS version and build version to disable the iCloud and Diagnostic pop-up windows
osvers=$(sw_vers -productVersion | awk -F. '{print $2}')
sw_vers=$(sw_vers -productVersion)
sw_build=$(sw_vers -buildVersion)

# Disable the iCloud, Diagnostic and Siri pop-up settings are set for new users
if [[ ${osvers} -ge 7 ]]; then

 for USER_TEMPLATE in "/System/Library/User Template"/*
  do
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool true
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeePrivacy -bool TRUE
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool TRUE
  done
fi


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
