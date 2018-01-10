#!/bin/bash

########################################################################
# Author:   Calum Hunter                                               #
# Date:     21/12/2016                                                 #
# Version:  0.7                                                        #
# Purpose:  Fusion Drive Detection and general HD formatting before    #
#           imaging tasks.                                             #
#                                                                      #
########################################################################
#
# Edited John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
#
# Changelog
#
# 1/3/18	- Added CHECK_FOR_APFS function
#
#

SCRIPT_NAME="detect_fusion_format.sh"
VERS="0.8"
SOURCE=""dd

# Setup Logging
# Get the machines serial number to start with
SERIAL_NUMBER=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')
LOG_FILE="/var/tmp/detect_fusion_format_Debug.log"
touch "$LOG_FILE"
LOG_FILE_SIZE=$(du -k $LOG_FILE | awk '{print $1}')
if [ $LOG_FILE_SIZE -gt 1024 ]; then
    rm $LOG_FILE
    echo $(date "+%a %b %d %H:%M:%S") "========================================================================" >> $LOG_FILE
    echo $(date "+%a %b %d %H:%M:%S") "       --- Log file rotated on $(date "+%a %b %d %H:%M:%S") ---" >> $LOG_FILE
fi
# Redirect all output to log file (and also send to STDOUT and STDERR)
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# Start with some variables
MAC_MODEL=$(sysctl hw.model | awk '{print $2}')
# Location of CocoaDialog
CD="/Applications/Utilities/cocoaDialog.app/Contents/MacOS/cocoaDialog"

CHECK_FOR_APFS(){
    # Check to see is this is an APFS formatted drive so we can remove it and let the rest of the script go
    echo $(date "+%a %b %d %H:%M:%S") " - Checking for APFS Container..."
    FSTYPE=$( diskutil apfs list ) # this check is ugly but it works
    if [ "$FSTYPE" != "No APFS Containers found" ]; then
      APFSCONTAINER=$( diskutil apfs list | grep 'APFS Container Reference' | cut -d':' -f 2 | tr -d ' ' )
      echo $(date "+%a %b %d %H:%M:%S") " - [OK] Detected APFS Container at $APFSCONTAINER"
      diskutil apfs deleteContainer $APFSCONTAINER
      echo $(date "+%a %b %d %H:%M:%S") " - [OK] Deleted APFS Container"
    else
      echo $(date "+%a %b %d %H:%M:%S") " - [WARN] No APFS Container found"
    fi
}

CHECK_FOR_FUSION(){
    # Check for the presence of multiple internal drives. If we have 2 or more we should check for SSD's and HDDS
    echo $(date "+%a %b %d %H:%M:%S") " - Checking for Multiple Internal Disks..."
    NUM_INT_HDS=$(diskutil list | grep "internal" | grep -v "virtual" -c)
    if [ "$NUM_INT_HDS" -ge "2" ]; then
        echo $(date "+%a %b %d %H:%M:%S") "     [OK] Detected $NUM_INT_HDS internal disks, checking for SSD and HDD.."
        CHECK_FOR_SSD
    else
        echo $(date "+%a %b %d %H:%M:%S") "     [OK] Detected $NUM_INT_HDS internal disk, not possible to create a fusion drive. Moving on."
        FUSION="FALSE"
    fi
}
CHECK_FOR_SSD(){
    # Loop through the disks and see if we can find an internal SSD
    # Start with the getting the list of internal disks
    echo $(date "+%a %b %d %H:%M:%S") ""
    echo $(date "+%a %b %d %H:%M:%S") " - Checking $NUM_INT_HDS internal disks looking for SSD or HDD and Non Removable Media ..."
    DEV_DISK=$(diskutil list | grep "internal" | grep -v "virtual" | awk '/dev/ {print $1}')
    for DISK in $DEV_DISK; do
        echo $(date "+%a %b %d %H:%M:%S") ""
        echo $(date "+%a %b %d %H:%M:%S") "     - Checking $DISK ..."
        SSD_STATUS=$(diskutil info -plist $DISK | plutil -convert json -o - - | python -c 'import sys, json; print json.load(sys.stdin)["SolidState"]')
        REMOVABLE_STATUS=$(diskutil info -plist $DISK | plutil -convert json -o - - | python -c 'import sys, json; print json.load(sys.stdin)["Removable"]')
        if [[ "$SSD_STATUS" = "False" ]] && [[ "$REMOVABLE_STATUS" = "False" ]]; then
            echo $(date "+%a %b %d %H:%M:%S") "     [OK] Disk Type: HDD - Non Removable"
            HDD_DISK_DEV=$DISK
            continue
        #elif [[ $(echo "$DISK_INFO" | awk '/Solid State:/ {print $3}') = "Yes" ]] && [[ $(echo "$DISK_INFO" | awk '/Removable Media:/ {print $3}') = "No" ]]; then
        elif [[ "$SSD_STATUS" = "True" ]] && [[ "$REMOVABLE_STATUS" = "False" ]]; then
            echo $(date "+%a %b %d %H:%M:%S") "     [OK] Disk Type: SSD - Non Removable"
            SSD_DISK_DEV=$DISK
            continue
        else
            echo $(date "+%a %b %d %H:%M:%S") "     [ERROR] Disk $DISK does not meet our requirements of SSD or HDD and Non Removable Media. Moving on."
        fi
    done
    if [[ ! -z $SSD_DISK_DEV ]] && [[ ! -z $HDD_DISK_DEV ]]; then
        echo $(date "+%a %b %d %H:%M:%S") ""
        echo $(date "+%a %b %d %H:%M:%S") "     [OK] SSD is on: $SSD_DISK_DEV"
        echo $(date "+%a %b %d %H:%M:%S") "     [OK] HDD is on: $HDD_DISK_DEV"
        FUSION="TRUE"
    else
        echo $(date "+%a %b %d %H:%M:%S") "     [ERROR] Did not find a SSD AND HDD!"
        FUSION="FALSE"
    fi
}
THROW_FV_ERROR(){
    # If filevault is locked, let the people know they need to turn it off
    FV_LOCKED=($($CD msgbox --title "Error!" --icon stop --text "Filevault Enabled and Locked" --no-newline --informative-text "Filevault Disk Encryption is enabled on this machine.

Please reboot this machine, disable Filevault and try again" --button1 "Shutdown" --string-output))
    if [ "$FV_LOCKED" = "Shutdown" ]; then
        echo $(date "+%a %b %d %H:%M:%S")  "[ERROR] - User alerted to FV being locked and they selected shutdown now"
        shutdown -h now
    fi
}
CHECK_FOR_FV(){
    # Check to see if we have a FileVault volume and if its locked or unlocked.
    echo $(date "+%a %b %d %H:%M:%S") "     - Checking for FileVault Encryption ...."
    FV_STATUS=$(diskutil cs list | awk '/Encryption Status:/ {print $3}')
    if [[ "$FV_STATUS" ]]; then
        for FV in $FV_STATUS; do
            if [ "$FV" = "Locked" ]; then
                echo $(date "+%a %b %d %H:%M:%S") "         [ERROR] FileVault Enabled. Status: $FV  ...."
                THROW_FV_ERROR
            elif [ "$FV" = "Unlocked" ]; then
                echo $(date "+%a %b %d %H:%M:%S") "         [WARN] FileVault Enabled. Status: $FV  ...."
                echo $(date "+%a %b %d %H:%M:%S") "         - Proceeding to remove CS LVG"
                DELETE_CS_VOLUME
            fi
        done
    else
        echo $(date "+%a %b %d %H:%M:%S") "         [OK] FileVault not enabled"
        DELETE_CS_VOLUME
    fi

}
DELETE_CS_VOLUME(){
    # Remove existing CS Group
    echo $(date "+%a %b %d %H:%M:%S") "     - Locating CoreStorage LVG ..."
    CS_LVG=$(/usr/sbin/diskutil cs list | awk '/-- Logical Volume Group / {print $NF}')
    if [[ "$CS_LVG" ]]; then
        for LVG in $CS_LVG; do
            echo $(date "+%a %b %d %H:%M:%S") "         [OK]  -   Located existing CoreStorage LVG with ID: $LVG"
            echo $(date "+%a %b %d %H:%M:%S") "     - Removing CoreStorage LVG ID: $LVG ..."
            echo $(date "+%a %b %d %H:%M:%S") ""
            /usr/sbin/diskutil cs delete "$LVG"
            sleep 4
        done
        if [ "$FUSION" = "TRUE" ]; then
            CREATE_NEW_FUSION_LVG
        else
            FORMAT_REGULAR_DRIVE
        fi
    else
        echo $(date "+%a %b %d %H:%M:%S") "         [ERROR] - Unable to detect a CoreStorage LVG !"
        exit 1
    fi
}
CREATE_NEW_FUSION_LVG(){
    echo $(date "+%a %b %d %H:%M:%S") ""
    echo $(date "+%a %b %d %H:%M:%S") "     - Creating Fusion Drive ..."
    echo $(date "+%a %b %d %H:%M:%S") "     - Using the following disks: $SSD_DISK_DEV and $HDD_DISK_DEV"
    echo $(date "+%a %b %d %H:%M:%S") ""
    /usr/sbin/diskutil cs create "FusionDrive" $SSD_DISK_DEV $HDD_DISK_DEV
    sleep 4
    LVG_ID=$(/usr/sbin/diskutil cs list | awk '/-- Logical Volume Group / {print $NF}')
    # Create a new Fusion Volume
    echo $(date "+%a %b %d %H:%M:%S") ""
    echo $(date "+%a %b %d %H:%M:%S") " - Creating Volume (Macintosh HD) on Fusion LVG: $LVG_ID ..."
    echo $(date "+%a %b %d %H:%M:%S") ""
    /usr/sbin/diskutil cs createVolume "$LVG_ID" jhfs+ "Macintosh HD" 100%
    sleep 2
    echo $(date "+%a %b %d %H:%M:%S") ""
}
CHECK_FOR_CS(){
    # Check for any CS volumes
    echo $(date "+%a %b %d %H:%M:%S") "     - Checking for CoreStorage Volumes..."
    if [ "$(diskutil cs list)" = "No CoreStorage logical volume groups found" ]; then
        echo $(date "+%a %b %d %H:%M:%S") "     [OK] - No CoreStorage Volumes found."
        if [ "$FUSION" = "TRUE" ]; then
            CREATE_NEW_FUSION_LVG
        else
            FORMAT_REGULAR_DRIVE
        fi
    else
        CS_CHECK_LVG=$(diskutil cs list | awk '/-- Logical Volume Group / {print $NF}')
        for CSLVG in $CS_CHECK_LVG; do
            echo $(date "+%a %b %d %H:%M:%S") "         [OK] - CoreStorage LVG found with ID: $CSLVG"
        done
        CHECK_FOR_FV
    fi
}
NO_DRIVE_AVAIL(){
    NO_INT_PHYS=($($CD msgbox --title "Error!" --icon stop --text "Unable to detect hard drive" --no-newline --informative-text "Unable to locate an internal physical hard drive.

If you feel this is in error, please contact IT." --button1 "Shutdown" --string-output))
        if [ "$NO_INT_PHYS" = "Shutdown" ]; then
            echo $(date "+%a %b %d %H:%M:%S")  "[ERROR] - User alerted and they selected shutdown now"
            shutdown -h now
        fi
}
FORMAT_REGULAR_DRIVE(){
    # Get a list of disks. Loop the through the disks and stop when we find an internal, physical and _non-removable_ disk.
    echo $(date "+%a %b %d %H:%M:%S") ""
    if [[ "$MAC_MODEL" == *VMware* ]]; then # Check to see if we are VMWare Fusion - we have different disk types grrr
        echo $(date "+%a %b %d %H:%M:%S") " [DEBUG] - Yo! Running VMWare Fusion! We will use /external, physical/ for finding a hard disk!"
        # Start by getting a list of disk dev id's
        DEV_DISK_LIST=$(diskutil list | grep "external" | grep -v "virtual" | awk '/dev/ {print $1}')
        for DISK in $DEV_DISK_LIST; do
            echo $(date "+%a %b %d %H:%M:%S") "     - Checking $DISK ..."

            #DISK_INFO=$(diskutil info $DISK)
            SSD_STATUS=$(diskutil info -plist $DISK | plutil -convert json -o - - | python -c 'import sys, json; print json.load(sys.stdin)["SolidState"]')
            REMOVABLE_STATUS=$(diskutil info -plist $DISK | plutil -convert json -o - - | python -c 'import sys, json; print json.load(sys.stdin)["Removable"]')

            #if [[ $(echo "$DISK_INFO" | awk '/Removable Media:/ {print $3}') = "No" ]]; then
            if [[ "$REMOVABLE_STATUS" = "False" ]]; then
                echo $(date "+%a %b %d %H:%M:%S") "     [OK] Disk Type: Non Removable"
                HDD_DISK_DEV=$DISK
                break # Stop when we find an external, physical disk that is non-removable
            #elif [[ $(echo "$DISK_INFO" | awk '/Removable Media:/ {print $3}') = "Yes" ]]; then
            elif [[ "$REMOVABLE_STATUS" = "True" ]]; then
                echo $(date "+%a %b %d %H:%M:%S") "     [ERROR] Disk Type: Removable"
                continue
            fi
        done
        if [ ! -z $HDD_DISK_DEV ]; then
            echo $(date "+%a %b %d %H:%M:%S") "     [OK] Found Eligible Disk: $HDD_DISK_DEV"
        else
            echo $(date "+%a %b %d %H:%M:%S") " [ERROR] - Unable to locate external, non removable disk!"
            NO_DRIVE_AVAIL
        fi
    else
        # Ok now search for disks on a normal non VMWare Fusion Machine
        DEV_DISK_LIST=$(diskutil list | grep "internal" | grep -v "virtual" | awk '/dev/ {print $1}')
        for DISK in $DEV_DISK_LIST; do
            echo $(date "+%a %b %d %H:%M:%S") "     - Checking $DISK ..."

            #DISK_INFO=$(diskutil info $DISK)
            SSD_STATUS=$(diskutil info -plist $DISK | plutil -convert json -o - - | python -c 'import sys, json; print json.load(sys.stdin)["SolidState"]')
            REMOVABLE_STATUS=$(diskutil info -plist $DISK | plutil -convert json -o - - | python -c 'import sys, json; print json.load(sys.stdin)["Removable"]')

            #if [[ $(echo "$DISK_INFO" | awk '/Removable Media:/ {print $3}') = "No" ]]; then
            if [[ "$REMOVABLE_STATUS" = "False" ]]; then
                echo $(date "+%a %b %d %H:%M:%S") "     [OK] Disk Type: Non Removable"
                HDD_DISK_DEV=$DISK
                break # Stop when we find an internal, physical disk that is non-removable
            #elif [[ $(echo "$DISK_INFO" | awk '/Removable Media:/ {print $3}') = "Yes" ]]; then
            elif [[ "$REMOVABLE_STATUS" = "True" ]]; then
                echo $(date "+%a %b %d %H:%M:%S") "     [ERROR] Disk Type: Removable"
                continue
            fi
        done
        if [ ! -z $HDD_DISK_DEV ]; then
            echo $(date "+%a %b %d %H:%M:%S") "     [OK] Found Eligible Disk: $HDD_DISK_DEV"
        else
            echo $(date "+%a %b %d %H:%M:%S") " [ERROR] - Unable to locate internal, physical, non removable disk!"
            NO_DRIVE_AVAIL
        fi
    fi
    echo $(date "+%a %b %d %H:%M:%S") ""
    echo $(date "+%a %b %d %H:%M:%S") "     - Beginning regular drive format."
    echo $(date "+%a %b %d %H:%M:%S") "     - Formating drive $HDD_DISK_DEV as Macintosh HD ..."
    echo $(date "+%a %b %d %H:%M:%S") ""
    /usr/sbin/diskutil partitionDisk $HDD_DISK_DEV 1 GPT jhfs+ "Macintosh HD" R
    echo $(date "+%a %b %d %H:%M:%S") ""
}
#------------------------------------------------------------------------------------------------------------#
# Start the script
echo $(date "+%a %b %d %H:%M:%S") "========================================================================"
echo $(date "+%a %b %d %H:%M:%S") " -  Running Script: $SCRIPT_NAME v. $VERS"
echo $(date "+%a %b %d %H:%M:%S") " "

CHECK_FOR_APFS

if [[ "$MAC_MODEL" == *iMac* ]] || [[ "$MAC_MODEL" == *Macmini* ]]; then
    echo $(date "+%a %b %d %H:%M:%S") " - Mac Model: $MAC_MODEL _may_ have a FUSION DRIVE!"
    echo $(date "+%a %b %d %H:%M:%S") ""
    CHECK_FOR_FUSION
    CHECK_FOR_CS
else
    echo $(date "+%a %b %d %H:%M:%S") " - Mac Model: $MAC_MODEL is NOT an eligible model for a Fusion Drive."
    echo $(date "+%a %b %d %H:%M:%S") " "
    CHECK_FOR_CS
fi
echo $(date "+%a %b %d %H:%M:%S") "==================== Fusion Drive Format Complete! ======================"
open "/Applications/Jamf Imaging.app/"
exit 0
