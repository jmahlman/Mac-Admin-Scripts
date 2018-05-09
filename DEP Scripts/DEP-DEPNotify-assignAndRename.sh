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
# 5/8/18  - Reverting to API call so we don't run recon twice.
# 5/3/18	-	Using the built-in jamf commands for setting asset tag and end user.
# 		- Changing the prefixes so no extra hyphen gets added if the machine is not MBP or MBA.
# 4/23/18	-	Using the jamf binary to change the computer name instead of the three commands
# 4/19/18 - Initial script creation
#
#
# Get the JSS URL from the Mac's jamf plist file
if [ -e "/Library/Preferences/com.jamfsoftware.jamf.plist" ]; then
	JSSURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
else
	echo "No JSS server set. Exiting..."
	exit 1
fi

# Define API username and password information & JSS Group name from passed parameters
if [ ! -z "$4" ]; then
    APIUSER="$4"
else
    echo "No value passed to $4 for api username. Exiting..."
    exit 1
fi

if [ ! -z "$5" ]; then
    APIPASS="$5"
else
    echo "No value passed to $5 for api password. Exiting..."
    exit 1
fi

SERIAL=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
MODEL=$(system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}')

DNPLIST=/var/tmp/DEPNotify.plist
USERNAME=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Assigned User'" | tr [A-Z] [a-z])
ASSETTAG=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Asset Tag'" | tr [a-z] [A-Z])

# Create xml
cat << EOF > /var/tmp/tempInfo.xml
<computer>
    <general>
      <asset_tag>$ASSETTAG</asset_tag>
    </general>
    <location>
      <username>$USERNAME</username>
    </location>
</computer>
EOF
	## Upload the xml file
	/usr/bin/curl -sfku "${APIUSER}:${APIPASS}" "${JSSURL}JSSResource/computers/serialnumber/$SERIAL" -X PUT -T /var/tmp/tempInfo.xml

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

# rename the computer
COMPUTERNAME="${USERNAME}-${PREFIX}"
COMPUTERNAME=`echo ${COMPUTERNAME:0:15}`
/usr/local/jamf/bin/jamf setComputerName -name $COMPUTERNAME

# update our extension attribute
mkdir /Library/JAMF\ DM
mkdir /Library/JAMF\ DM/ComputerName
chflags hidden /Library/JAMF\ DM
echo $COMPUTERNAME > /Library/JAMF\ DM/ComputerName/ComputerName.txt
rm -Rf /var/tmp/tempInfo.xml
