#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: remove-AWCapp
#
# Purpose: Run this on a machine to remove the "Mac Adware Cleaner.app" adware. This script doesn't check
# specifically for the app running, we scope this to machines that have the app in inventory.
#
# Changelog
#
# 2/28/18 - Newly created script
#
#
awcPID=`ps -A | grep -m1 '[M]ac Adware Cleaner' | awk '{print $1}'`

# Get the current logged in user that we'll be modifying
if [ ! -z "$3" ]; then
	user=$3
else
	user=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
fi

if [[ $awcPID != "" ]]; then
	echo "Killing Mac Adware Cleaner"
	killall "Mac Adware Cleaner"
else
  echo "Mac Adware Cleaner not running/not found"
fi

if [[ -e "/Applications/Mac Adware Cleaner.app" ]]; then
  rm -Rf "/Applications/Mac Adware Cleaner.app"
  echo "Remmoved /Applications/Mac Adware Cleaner.app"
fi

if [[ -e "/Applications/_MACOSX/Mac Adware Cleaner.app" ]]; then
  rm -Rf "/Applications/_MACOSX/Mac Adware Cleaner.app"
  echo "Remmoved /Applications/_MACOSX/Mac Adware Cleaner.app"
fi

if [[ -d "/Users/$user/Library/Mac Adware Cleaner" ]]; then
  rm -Rf "/Users/$user/Library/Mac Adware Cleaner"
  echo "Removed /Users/$user/Library/Mac Adware Cleaner"
fi

if [[ -d "/Users/$user/Library/Application Support/Mac Adware Cleaner" ]]; then
  rm -Rf "/Users/$user/Library/Application Support/Mac Adware Cleaner"
  echo "Removed /Users/$user/Application Support/Library/Mac Adware Cleaner"
fi

if [[ -d "/Users/$user/Library/Application Support/awc" ]]; then
  rm -Rf "/Users/$user/Library/Application Support/awc"
  echo "Removed /Users/$user/Application Support/Library/awc"
fi

# Now the scary part..find a file in /private/var/folders...
find /private/var/folders -name "helperamc" -type d -exec rm -rf {} \;

exit 0
