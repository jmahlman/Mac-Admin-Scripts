#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: EA-computerName
#
# Purpose: Update our Computer Name receipt EA via the API.
#
#
# Changelog
#
# 7/27/18 - New script
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

serial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

if [ -f /Library/JAMF\ DM/ComputerName/ComputerName.txt ]; then
  computerName=$(cat /Library/JAMF\ DM/ComputerName/ComputerName.txt)
else
  computerName=""
fi

# Create xml
cat << EOF > /var/tmp/name.xml
<computer>
  <extension_attributes>
      <extension_attribute>
          <name>New Computer Name</name>
          <value>$computerName</value>
      </extension_attribute>
  </extension_attributes>
</computer>
EOF
## Upload the xml file
/usr/bin/curl -sfku "$APIUSER":"$APIPASS" "$JSSURL"JSSResource/computers/serialnumber/"$serial" -H "Content-type: text/xml" -T /var/tmp/name.xml -X PUT
