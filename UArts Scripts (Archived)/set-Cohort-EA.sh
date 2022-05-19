#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: EA-cohort
#
# Purpose: Update our Computer Cohort receipt EA via the API.
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

if [ -f /Library/JAMF\ DM/Cohort/*.txt ]; then
  cohort=$(head -n 1 /Library/JAMF\ DM/Cohort/*.txt)
elif [-f /Library/JAMF\ DM/*.txt]; then
	cohort=$(head -n 1 /Library/JAMF\ DM/*.txt)
else
	cohort=""
fi

# Create xml
cat << EOF > /var/tmp/cohort.xml
<computer>
  <extension_attributes>
      <extension_attribute>
          <name>New Cohort</name>
          <value>$cohort</value>
      </extension_attribute>
  </extension_attributes>
</computer>
EOF
## Upload the xml file
/usr/bin/curl -sfku "$APIUSER":"$APIPASS" "$JSSURL"JSSResource/computers/serialnumber/"$serial" -H "Content-type: text/xml" -T /var/tmp/cohort.xml -X PUT
