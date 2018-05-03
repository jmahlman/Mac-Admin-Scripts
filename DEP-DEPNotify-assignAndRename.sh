#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: DEP-DEPNotify-assignAndRename
#
# Purpose: Will populate the server with appropriate username and rename the machine
# at deployment time. Run AFTER DEPNotify collects information.
#
# Changelog
#
# 5/3/18	-	Using the built-in jamf commands for setting asset tag and end user.
# 		- Changing the prefixes so no extra hyphen gets added if the machine is not MBP or MBA.
# 4/23/18	-	Using the jamf binary to change the computer name instead of the three commands
# 4/19/18 - Initial script creation
#
#
JAMFBIN=$(/usr/bin/which jamf)

MODEL=$(system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}')

DNPLIST=/var/tmp/DEPNotify.plist
USERNAME=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Assigned User'" | tr [A-Z] [a-z])
ASSETTAG=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Asset Tag'" | tr [a-z] [A-Z])

$JAMFBIN recon -assetTag $ASSETTAG -endUsername $USERNAME

if echo "$MODEL" | grep -q "MacBookAir"
then
    PREFIX="-MBA"
elif echo "$MODEL" | grep -q "MacBookPro"
then
    PREFIX="-MBP"
else
    echo "No model identifier found."
    PREFIX=""
fi

# rename the computer
COMPUTERNAME="${USERNAME}${PREFIX}"
COMPUTERNAME=`echo ${COMPUTERNAME:0:15}`
$JAMFBIN setComputerName -name $COMPUTERNAME

# update our extension attribute
mkdir /Library/JAMF\ DM
mkdir /Library/JAMF\ DM/ComputerName
chflags hidden /Library/JAMF\ DM
echo $COMPUTERNAME > /Library/JAMF\ DM/ComputerName/ComputerName.txt
