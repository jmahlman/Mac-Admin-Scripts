#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: rename-Machine-by-User.sh
#
# Purpose: Will rename a machine based on the assigned user in the JSS via API.
#          Use this during DEP enrollment to avoid the "admin's MacBook" naming
#
# Changelog
# 2/15/18:  - Initial script creation
#

# Get the JSS URL from the Mac's jamf plist file
if [ -e "/Library/Preferences/com.jamfsoftware.jamf.plist" ]; then
	jssURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
else
	echo "No JSS server set. Exiting..."
	exit 1
fi

# Define API username and password information & JSS Group name from passed parameters
if [ ! -z "$4" ]; then
    apiUser="$4"
else
    echo "No value passed to $4 for api username. Exiting..."
    exit 1
fi

if [ ! -z "$5" ]; then
    apiPass="$5"
else
    echo "No value passed to $5 for api password. Exiting..."
    exit 1
fi

SERIAL=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

USERINFO=$(curl -k ${jssURL}JSSResource/computers/serialnumber/${SERIAL}/subset/location -H "Accept: application/xml" --user "${apiUser}:${apiPass}")
USERNAME=$(echo $USERINFO | /usr/bin/awk -F'<username>|</username>' '{print $2}' | tr [A-Z] [a-z])

DEVICEINFO=$(curl -k ${jssURL}JSSResource/computers/serialnumber/${SERIAL}/subset/hardware -H "Accept: application/xml" --user "${apiUser}:${apiPass}")
MODEL=$(echo $DEVICEINFO | /usr/bin/awk -F'<model_identifier>|</model_identifier>' '{print $2}')

if [ -z "$USERNAME" ]
then
    USERNAME="$SERIAL"
fi

if echo "$MODEL" | grep -q "MacBookAir"
then
    PREFIX="MBA"
elif echo "$MODEL" | grep -q "MacBookPro"
then
    PREFIX="MBP"
else
    echo "No model identifier found."
    PREFIX=""
fi

COMPUTERNAME="${USERNAME}-${PREFIX}"
COMPUTERNAME=`echo ${COMPUTERNAME:0:15}`
echo "Setting computer name to $COMPUTERNAME"
/usr/sbin/scutil --set ComputerName "$COMPUTERNAME"
/usr/sbin/scutil --set LocalHostName "$COMPUTERNAME"
/usr/sbin/scutil --set HostName "$COMPUTERNAME"
dscacheutil -flushcache
