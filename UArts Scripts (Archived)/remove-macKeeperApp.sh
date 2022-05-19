#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: remove-macKeeperApp
#
# Purpose: Run this on a machine to remove "Mackeeper.app" . This script doesn't check
# specifically for the app running, we scope this to machines that have the app in inventory.
#
# Changelog
#
# 2/28/18 - Newly created script
#
#

# Get the current logged in user that we'll be modifying
if [ ! -z "$3" ]; then
	user=$3
else
	user=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
fi

# delete needed files to remove MacKeeper
rm -rf /Users/$user/Library/LaunchAgents/com.zeobit.MacKeeper.Helper.plist
rm -rf /Users/$user/Library/LaunchAgents/com.mackeeper.MacKeeper.Helper.plist

launchctl unload /Users/$user/Library/LaunchAgents/com.mackeeper.MacKeeper.Helper.plist

sleep 5
# Kill mackeeper processes
killall "MacKeeper Helper"
killall MKCleanService
killall MacKeeper

# Files Outside Home Folder

rm -rf /Applications/MacKeeper.app
rm -rf /Library/Preferences/.3FAD0F65-FC6E-4889-B975-B96CBF807B78

# Files inside Home Folder

rm -rf /Users/$user/Library/Application\ Support/MacKeeper\ Helper
rm -rf /Users/$user/Library/Logs/MacKeeper.log
rm -rf /Users/$user/Library/Logs/MacKeeper.log.signed
rm -rf /Users/$user/Library/Logs/SparkleUpdateLog.log
rm -rf /Users/$user/Library/Preferences/.3246584E-0CF8-4153-835D-C7D952862F9D
rm -rf /Users/$user/Library/Preferences/com.zeobit.MacKeeper.Helper.plist
rm -rf /Users/$user/Library/Preferences/com.zeobit.MacKeeper.plist
rm -rf /Users/$user/Library/Saved\ Application\ State/com.zeobit.MacKeeper.savedState
rm -rf /Users/$user/Library/Application\ Support/MacKeeper
rm -rf /Users/$user/Library/Application\ Support/com.mackeeper.MacKeeper
rm -rf /Users/$user/Library/Application\ Support/com.mackeeper.MacKeeper.Helper
rm -rf /Users/$user/Library/Application\ Support/com.mackeeper.MacKeeper.MKCleanService
rm -rf /Users/$user/Library/Preferences/.3FAD0F65-FC6E-4889-B975-B96CBF807B78
rm -rf /Users/$user/Library/Preferences/com.mackeeper.MacKeeper.Helper.plist
rm -rf /Users/$user/Library/Preferences/com.mackeeper.MacKeeper.plist
rm -rf /Users/$user/Library/Saved\ Application\ State/com.mackeeper.MacKeeper.savedState
