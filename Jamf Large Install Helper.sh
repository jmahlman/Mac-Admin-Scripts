#!/bin/zsh
# shellcheck shell=bash

# Script Info variables
SCRIPT_AUTHOR="John Mahlman"
SCRIPT_AUTHOR_EMAIL="john.mahlman@gmail.com"
SCRIPT_NAME="large-app-install-helper"
SCRIPTVER="1.10.1"

# Purpose: This script will be used to show a user the progress of large installs using DEPNotify and Jamf policies.
#
#
# Author: John Mahlman <john.mahlman@gmail.com>
# Creation Date: May 10, 2022
#
# v1.10.1
# 2022-05-19 - John Mahlman
# Added some better error checking for a failed package install.
# Added a popup for a failed download or a failed install (instead of just quitting).
# Change logs file name to include date so we don't accidentally get false reports from old installs.
# Fixed the free space checker.
#
# v1.6
# 2022-05-18 - John Mahlman
# Learned that Jamf has an install flag that will also give us percentages, so we're going to try to use that instead. 
# Updated to use the Jamf Waiting room, this means that the Jamf policy you call should be a CACHE package policy, not an install.
#
# v1.3
# 2022-05-17 - John Mahlman
# Refactored some variables and also updated the installer loop to be dumber but to actually work :)
# Added a check in the main portion of the script, if the package is downloaded fully already, just have it install instead of running a policy.
#
# v1.1
# 2022-05-16 - John Mahlman
# When a user exits with cmd+ctrl+c we want to make it as a clean quit, so I changed the exit code from 2 to 0
#
# v1.0
# 2022-05-16 - John Mahlman
# Jamf trial ready!
#
# v0.1
# 2022-05-10 - John Mahlman
# Initial Creation
#

# JAMF Parameters
# Parameter 4: Friendly Application Name
[ -z "$4" ] && exit 14 || APPNAME="$4"
# Parameter 5: Jamf Trigger for caching package
[ -z "$5" ] && exit 15 || JAMF_TRIGGER="$5"
# Parameter 6: Package Name (with .pkg)
[ -z "$6" ] && exit 16 || PKG_NAME="$6"
# Parameter 7: Package size in KB (whole numebrs only)
[ -z "$7" ] && exit 17 || PKG_Size="$7"
# Parameter 8: Minimum drive space required (default 5) (Optional)
[ -z "$8" ] && min_drive_space="5" || min_drive_space="$8"
# Parameter 9: Extended tout time (default 60) (Optional)
[ -z "$9" ] && TIMEOUT="60" || TIMEOUT="$9"

RUNTIME=$(/bin/date +'%Y-%m-%d_%H%M%S')
# all output from now on is written also to a log file
LOG_FILE="/var/tmp/install-helper.$RUNTIME.log"
exec > >(tee "${LOG_FILE}") 2>&1

# Grab currently logged in user to set the language for Dialogue messages
CURRENT_USER=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}')

# Jamf Variables
JAMFBINARY=/usr/local/jamf/bin/jamf
JAMF_DOWNLOADS="/Library/Application Support/JAMF/Downloads"
JAMF_WAITING_ROOM="/Library/Application Support/JAMF/Waiting Room"
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# DEPNotify varaibles
DN_APP="/Applications/Utilities/DEPNotify.app"
DNLOG="/var/tmp/depnotify.log"
DN_CONFIRMATION="/var/tmp/com.depnotify.provisioning.done"
DNPLIST="/Users/$CURRENT_USER/Library/Preferences/menu.nomad.DEPNotify.plist"

# DEPNotify UI Elements and text
DOWNLOAD_ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarDownloadsFolder.icns"
INSTALL_ICON="/System/Library/CoreServices/Installer.app/Contents/Resources/package.icns"
DN_TITLE="$APPNAME Install Helper"
DOWNLOAD_DESC="Your machine is currently downloading $APPNAME. This process will take a long time, please be patient.\n\nIf you want to cancel this process press CMD+CTRL+C."
INSTALL_DESC="Your machine is now installing $APPNAME. This process may take a while, please be patient.\n\nIf you want to cancel this process press CMD+CTRL+C."
IT_SUPPORT="IT Support"

# shellcheck disable=SC2012
CURRENT_PKG_SIZE=$(ls -l "$JAMF_WAITING_ROOM/$PKG_NAME" | awk '{ print $5 }' | awk '{$1/=1024;printf "%.i\n",$1}')

# icon for error dialog
ALERT_ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"
# Error dialogs
FREESPACE_ERROR="There is not enough space on the drive to complete this install. You need to have at least ${min_drive_space} GB available."
DL_ERROR="There was a problem starting the download, this process will now quit. Please try again or open a ticket with $IT_SUPPORT."
INSTALL_ERROR="The installation failed. Please open a ticket with $IT_SUPPORT."

# Check if DEPNotify is installed, if it's not install from Jamf.
if [[ ! -d $DN_APP ]]; then
    echo "DEPNotify does not exist, installing."
    $JAMFBINARY policy -event main-depnotify
    if [[ ! -d $DN_APP ]]; then
        echo "DEPNotify Install failed, exiting"
        exit 20
    fi
fi

check_free_space() {
    # determine if the amount of free and purgable drive space is sufficient for the upgrade to take place.
    free_disk_space=$(osascript -l 'JavaScript' -e "ObjC.import('Foundation'); var freeSpaceBytesRef=Ref(); $.NSURL.fileURLWithPath('/').getResourceValueForKeyError(freeSpaceBytesRef, 'NSURLVolumeAvailableCapacityForImportantUsageKey', null); Math.round(ObjC.unwrap(freeSpaceBytesRef[0]) / 1000000000)")  # with thanks to Pico

    if [[ ! "$free_disk_space" ]]; then
        # fall back to df -h if the above fails
        free_disk_space=$(df -Pk . | column -t | sed 1d | awk '{print $4}')
    fi
    
    if [[ $free_disk_space -ge $min_drive_space ]]; then
        echo "   [check_free_space] OK - $free_disk_space GB free/purgeable disk space detected"
    else
        echo "   [check_free_space] ERROR - $free_disk_space GB free/purgeable disk space detected"
        "$jamfHelper" -windowType "utility" -description "${FREESPACE_ERROR}" -alignDescription "left" -icon "$ALERT_ICON" -button1 "OK" -defaultButton "0" -cancelButton "1"
        exit 1
    fi
}

dep_notify() {
    # This function will open DEPNotify and set up the initial parameters.
    # configuration taken from https://github.com/jamf/DEPNotify-Starter
    /usr/bin/defaults write "$DNPLIST" statusTextAlignment "center"
    # Set the help bubble information
    /usr/bin/defaults write "$DNPLIST" helpBubble -array "About this tool" \
    "This utility was designed to provide you with feedback for large installs like Xcode. \nThe progress bar will update based on your current download size and during install will update based on feedback from the installer. \n\nIf you have issues, pelase contact $IT_SUPPORT. \n\nWritten by $SCRIPT_AUTHOR, $SCRIPT_AUTHOR_EMAIL \nVersion $SCRIPTVER"
    chown "$CURRENT_USER":staff "$DNPLIST"

    # Configure the window's look
    {
        echo "Command: Image: $DOWNLOAD_ICON"
        echo "Command: MainTitle: $DN_TITLE"
        /bin/echo "Command: MainText: $DOWNLOAD_DESC"
        echo "Command: QuitKey: c"
    } >> "$DNLOG"
    
    # Launch DEPNotify if it's not open
    if ! pgrep DEPNotify ; then
            sudo -u "$CURRENT_USER" open -a "$DN_APP" --args -path "$DNLOG"
    fi
}

# Call this with "install" or "download" to update the DEPNotify window and progress dialogs
depNotifyProgress() {
    last_progress_value=0
    current_progress_value=0

    if [[ "$1" == "download" ]]; then
        echo "Command: MainTitle: Downloading $APPNAME" >> $DNLOG

        # Wait for for the download to start, if it doesn't we'll bail out.
        while [ ! -f "$JAMF_DOWNLOADS/$PKG_NAME" ]; do
            userCancelProcess
            if [[ "$TIMEOUT" == 0 ]]; then
                echo "ERROR: (depNotifyProgress) Timeout while waiting for the download to start."
                {
                /bin/echo "Command: MainText: $DL_ERROR"
                echo "Status: Error downloading $PKG_NAME"
                echo "Command: DeterminateManualStep: 100"
                echo "Command: Quit: $DL_ERROR"
                } >> $DNLOG
                exit 1
            fi
            sleep 1
            ((TIMEOUT--))
        done

        # Download started, lets set the progress bar
        echo "Status: Downloading - 0%" >> $DNLOG
        echo "Command: DeterminateManual: 100" >> $DNLOG

        # Until at least 100% is reached, calculate the downloading progress and move the bar accordingly
        until [[ "$current_progress_value" -ge 100 ]]; do
            # shellcheck disable=SC2012
            until [ "$current_progress_value" -gt "$last_progress_value" ]; do
                # Check if the download is in the waiting room (it moves from downloads to the waiting room after it's fully downloaded)
                if [[ ! -e "$JAMF_DOWNLOADS/$PKG_NAME" ]]; then
                    CURRENT_DL_SIZE=$(ls -l "$JAMF_WAITING_ROOM/$PKG_NAME" | awk '{ print $5 }' | awk '{$1/=1024;printf "%.i\n",$1}')
                    userCancelProcess
                    current_progress_value=$((CURRENT_DL_SIZE * 100 / PKG_Size))
                    sleep 2
                else
                    CURRENT_DL_SIZE=$(ls -l "$JAMF_DOWNLOADS/$PKG_NAME" | awk '{ print $5 }' | awk '{$1/=1024;printf "%.i\n",$1}')
                    userCancelProcess
                    current_progress_value=$((CURRENT_DL_SIZE * 100 / PKG_Size))
                    sleep 2
                fi
            done
            echo "Command: DeterminateManualStep: $((current_progress_value-last_progress_value))" >> $DNLOG
            echo "Status: Downloading - $current_progress_value%" >> $DNLOG
            last_progress_value=$current_progress_value
        done
    elif [[ "$1" == "install" ]]; then
        echo "Command: MainTitle: Installing $APPNAME" >> $DNLOG
        # Install started, lets set the progress bar
        {
            echo "Command: Image: $INSTALL_ICON"
            /bin/echo "Command: MainText: $INSTALL_DESC"
            echo "Status: Preparing to Install $PKG_NAME"
            echo "Command: DeterminateManual: 100"
        } >> $DNLOG
        until grep -q "progress status" "$LOG_FILE" ; do
            sleep 2
        done
        # Update the progress using a timer until it's at 100%
        until [[ "$current_progress_value" -ge "100" ]]; do
            until [ "$current_progress_value" -gt "$last_progress_value" ]; do
                INSTALL_STATUS=$(sed -nE 's/installer:PHASE:(.*)/\1/p' < $LOG_FILE | tail -n 1)
                INSTALL_FAILED=$(sed -nE 's/installer:(.*)/\1/p' < $LOG_FILE | tail -n 1 | grep -c "The Installer encountered an error")
                if [[ $INSTALL_FAILED -ge "1" ]]; then
                    echo "Install failed, notifying user."
                    echo "Command: Quit: $INSTALL_ERROR" >> $DNLOG 
                fi
                userCancelProcess
                current_progress_value=$(sed -nE 's/installer:%([0-9]*).*/\1/p' < $LOG_FILE | tail -n 1)
                sleep 2
            done
            echo "Command: DeterminateManualStep: $((current_progress_value-last_progress_value))" >> $DNLOG
            echo "Status: $INSTALL_STATUS - $current_progress_value%" >> $DNLOG
            last_progress_value=$current_progress_value
        done
    # The code below is the install logic to use when "estimating" the time of an install instead of using JAMF
    # It mostly works but I want to keep it for historical sake ;)
    elif [[ "$1" == "manualInstall" ]]; then
        echo "Command: MainTitle: Installing $APPNAME" >> $DNLOG
        # Install started, lets set the progress bar
        {
            echo "Command: Image: $INSTALL_ICON"
            /bin/echo "Command: MainText: $INSTALL_DESC"
            echo "Status: Preparing to Install $PKG_NAME"
            echo "Command: DeterminateManual: $INSTALL_TIMER"
        } >> $DNLOG

        # Update the progress using a timer until a receipt is found. If it gets full it'll just wait for a receipt.
        until [[ "$current_progress_value" -ge $INSTALL_TIMER ]] && [[ $(receiptIsPresent) -eq 1 ]]; do
            userCancelProcess
            sleep 5
            current_progress_value=$((current_progress_value + 5))
            echo "Command: DeterminateManualStep: 5" >> $DNLOG
            echo "Status: Installing $PKG_NAME" >> $DNLOG
            receiptIsPresent && break
            last_progress_value=$current_progress_value
        done
    fi
}

receiptIsPresent() {
    if [[ $(find "/Library/Application Support/JAMF/Receipts/$PKG_NAME" -type f -maxdepth 1) ]]; then
        current_progress_value="100"
        # If it finds the receipt, just set the progress bar to full
        {
        echo "Installer is not running, exiting."
        echo "Command: DeterminateManualStep: 100"
        echo "Status: $PKG_NAME successfully installed."
        } >> $DNLOG
        sleep 10
        return 0
    fi
return 1
}

cachePackageWithJamf() {
    $JAMFBINARY policy -event "$1" &
    JAMF_PID=$!
    echo "Jamf policy running with a PID of $JAMF_PID"
}

installWithJamf() {
    $JAMFBINARY install -path "$JAMF_WAITING_ROOM" -package "$PKG_NAME" -showProgress -target / 2>&1 | tee $LOG_FILE &
    JAMF_PID=$!
    echo "Jamf install running with a PID of $JAMF_PID"
}

cleanupWaitingRoom() {
    echo "Sweeping up the waiting room..."
    rm -f "$JAMF_WAITING_ROOM/$PKG_NAME" &
    rm -f "$JAMF_WAITING_ROOM/$PKG_NAME".cache.xml
}

# Checks if DEPNotify is open, if it's not, it'll exit, causing the trap to run
userCancelProcess () {
    if ! pgrep DEPNotify ; then
        kill -9 $JAMF_PID
        killall installer
        echo "User manually cancelled with the quit key."
        # We don't want to mark this as a failure, so let's exit gracefully.
        exit 0
    fi
}

dep_notify_quit() {
    # quit DEP Notify
    echo "Command: Quit" >> "$DNLOG"
    # reset all the settings that might be used again
    /bin/rm "$DNLOG" "$DN_CONFIRMATION" 2>/dev/null
    # kill dep_notify_progress background job if it's already running
    if [ -f "/tmp/depnotify_progress_pid" ]; then
        while read -r i; do
            kill -9 "${i}"
        done < /tmp/depnotify_progress_pid
        /bin/rm /tmp/depnotify_progress_pid
    fi
}

kill_process() {
    process="$1"
    echo
    if process_pid=$(/usr/bin/pgrep -a "$process" 2>/dev/null) ; then 
        echo "   [$SCRIPT_NAME] attempting to terminate the '$process' process - Termination message indicates success"
        kill "$process_pid" 2> /dev/null
        if /usr/bin/pgrep -a "$process" >/dev/null ; then 
            echo "   [$SCRIPT_NAME] ERROR: '$process' could not be killed"
        fi
        echo
    fi
}

finish() {
    # kill caffeinate
    kill_process "caffeinate"
    kill_process "jamfHelper"
    dep_notify_quit
}

###############
## MAIN BODY ##
###############
echo "$SCRIPT_NAME version $SCRIPTVER"
# ensure the finish function is executed when exit is signaled
trap "finish" EXIT

# ensure computer does not go to sleep while running this script
echo "   [$SCRIPT_NAME] Caffeinating this script (pid=$$)"
/usr/bin/caffeinate -dimsu -w $$ &

check_free_space
# Let's first check if the package existis in the downloads and it matches the size...
# this avoids us having to run the policy again and causing the sceript to re-download the whole thing again.
if [[ -e "$JAMF_WAITING_ROOM/$PKG_NAME" ]] && [[ $CURRENT_PKG_SIZE == "$PKG_Size" ]]; then
    echo "Package already download, installing with jamf binary."
    dep_notify
    installWithJamf
    depNotifyProgress install
    cleanupWaitingRoom
else
    dep_notify
    cachePackageWithJamf "$JAMF_TRIGGER"
    depNotifyProgress download
    sleep 5
    dep_notify_quit
    dep_notify
    installWithJamf
    depNotifyProgress install
    cleanupWaitingRoom
fi