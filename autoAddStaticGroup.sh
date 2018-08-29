#!/bin/bash
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: autoAddStaticGroup.sh
#
# Purpose: Will add machines to static groups based on the machine name
# Note: If your group names have spaces you have to use '%20' in their place.
#
# Changelog
# 8/24/18 	- Updated all room arrays.
# 					- Changed env to bash
# 10/25/17:	- Updated rooms and cleaned up naming.
#						- Fixed header to conform with my other scripts
# 					- Added StudioA2 array (new studios)
# 8/29/16:	- Renamed Script
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

# Get room number from computer name.
roomNumber=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $1}' | tr "[a-z]" "[A-Z]"`
# Get Department name if not a PUBLIC machine
deptName=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $2}' | tr "[a-z]" "[A-Z]"`
# Building by first letter
building=`scutil --get ComputerName | cut -c -1 | tr "[a-z]" "[A-Z]"`
# Kiosk or Machine (K or M)
machType=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $3}' | cut -c -1 | tr "[a-z]" "[A-Z]"`

# Arrays for all of our different types of rooms
labNumber=(A231 A309 A615 A626 A728 AM11 T1113 T1213 T1223 T1328 T1423 T1429 T1522 T802 T907)
TsmartClass=(T1014 T1028 T1049 T1053 T1703 T202 T511 T513 T602 T604 T606 T702 T704 T706 T710 T712 T714 T716 T806 T831 T833 T902)
AsmartClass=(A212 A815)
GsmartClass=(G404 G405 G408 G410 G411 G415 H312)
StudioT=(T1219 T1215 T1404 T1408 T1421 T1425 T1504 T1513 T510 T512 T514 T518)
StudioA=(A200 A315 A316 A317 A318 A319 A320 A220 A716 A723 A725 A726)
suiteVoice=(T612 T614 T616 T618 T620 T608 T709)
suiteGen=(T1403 T1405 T1407 T1409 T1410 T1412 T1414 T1415) #generic suites
suiteDragon=(T1403 T1405 T1407 T1409)
suiteDragonUM=(T1425B T1425C)
editBay=(T1210 T1212 T1214 T1216 T1218 T1220 T1420 T1422)

# Public Computers: Check the first part of the computer name against the labNumber array
if [[ " ${labNumber[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup=LAB-$roomNumber

elif [[ " ${TsmartClass[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="SMARTCLASS-Terra"

elif [[ " ${AsmartClass[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="SMARTCLASS-Anderson"

elif [[ " ${GsmartClass[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="SMARTCLASS-Gershman"

elif [[ " ${StudioA3[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="Studio-A3"

elif [[ " ${StudioA2[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="Studio-A2"

elif [[ " ${StudioA7[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="Studio-A7"

elif [[ " ${suiteVoice[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="SUITE-Voice"

elif [[ " ${suiteDragon[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="SUITES-Dragon%20Frame"

elif [[ " ${suiteDragonUM[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="SUITES-Dragon%20Frame-Unmanaged"

elif [[ " ${editBay[@]} " =~ " ${roomNumber} " ]]; then
	jssGroup="SUITE-Editing%20Bays"

elif [[ "$roomNumber" == "T1513" ]]; then
	jssGroup=SUITE-$roomNumber

elif [[ "$roomNumber" == "A714" ]]; then
	jssGroup=SUITE-$roomNumber

elif [[ "$roomNumber" == "T1215" ]]; then
	jssGroup=STUDIO-$roomNumber

elif [[ "$roomNumber" == "A220" ]]; then
	jssGroup=STUDIO-$roomNumber

# Office/Department Computers: Check the second part of the computer name for the department and add accordingly
elif [[ "$roomNumber" == "CHECKOUT" ]]; then
	jssGroup="CHECKOUT"

elif [[ "$deptName" == "ADV" ]] || [[ "$deptName" == "PUBL" ]] || [[ "$deptName" == "UCOMM" ]]; then
	jssGroup="OFFICE-ADV-PUBL-UCOMM"

elif [[ "$roomNumber" == "DANCE" ]]; then
	jssGroup="LAB-Dance%20Media"

elif [[ "$deptName" == "CR" ]]; then
	jssGroup="OFFICE-CAMD-AART-Craft%20&%20Material%20Studies"

elif [[ "$deptName" == "FA" ]] || [[ "$deptName" == "AART" ]] || [[ "$deptName" == "CAMD" ]]; then
	jssGroup="OFFICE-CAMD-AART-Fine%20Arts"

elif [[ "$deptName" == "PH" ]]; then
	jssGroup="OFFICE-CAMD-AART-Photography"

elif [[ "$roomNumber" == "F1J" ]] || [[ "$roomNumber" == "SCULPTURE" ]]; then
	jssGroup="OFFICE-CAMD-AART-Fine%20Arts"

elif [[ "$deptName" == "GRAD" ]] && [[ "$building" == "T" ]] ; then
	jssGroup="OFFICE-CAMD-ACAMD-GRAD-Art%20&%20Design%20Education"

elif ([[ "$deptName" == "GRAD" ]] && [[ "$building" == "A" ]]) || [[ "$deptName" == "GP" ]]; then
	jssGroup="OFFICE-CAMD-ACAMD-GRAD-Graduate%20Studies"

elif [[ "$deptName" == "ILL" ]] && [[ "$building" == "A" ]]; then
	jssGroup="OFFICE-CAMD-ACAMD-Illustration"

elif [[ "$deptName" == "LA" ]]; then
	jssGroup="OFFICE-CLAS-ACLAS-Liberal%20Arts"

elif [[ "$deptName" == "FILM" ]]; then
	jssGroup="OFFICE-CAMD-AFLM-Film%20&%20Video"

elif [[ "$deptName" == "MRC" ]] && [[ "$machType" == "M" ]]; then
	jssGroup="OFFICE-OTIS-Media%20Resources"

elif [[ "$deptName" == "CORE" ]]; then
	jssGroup="OFFICE-CAMD-ACAMD-UGRAD-Core%20Studies"

elif [[ "$deptName" == "PROV" ]]; then
	jssGroup="OFFICE-Provost"

elif [[ "$deptName" == "VRC" ]]; then
	jssGroup="KIOSK-Library-Visual%20Resources%20Center"

elif ([[ "$deptName" == "REG" ]] && [[ "$machType" == "M" ]]) || [[ "$roomNumber" == "REG" ]]; then
	jssGroup="OFFICE-Registrar"

# Kiosk Machines
elif [[ "$roomNumber" == "GL" ]] && [[ "$machType" == "K" ]]; then
	jssGroup="KIOSK-Library-Anderson"

elif [[ "$roomNumber" == "ML" ]] && [[ "$machType" == "K" ]]; then
	jssGroup="KIOSK-Library-Merriam"

elif [[ "$deptName" == "MRC" ]] && [[ "$machType" == "K" ]]; then
	jssGroup="KIOSK-Media%20Resources"

elif [[ "$deptName" == "REG" ]] && [[ "$machType" == "K" ]]; then
	jssGroup="KIOSK-Registrar"

elif [[ "$roomNumber" == "M201" ]] && [[ "$deptName" == "SMU" ]]; then
	jssGroup="OFFICE-PCPA-Music"

# If the computer does not have a lab or department that matches, drop it into the NO STATIC GROUP group
else
	echo "$roomNumber or $deptName does not match any PUBLIC or OFFICE names, adding to NO STATIC GROUP group (yes, that's odd)."
	jssGroup="ZZ-NO-STATIC-GROUP"
fi
echo "Group set to $jssGroup"

# Get the JSS Group's data, remove closing section
curl -H "Accept: application/xml" -sfku "${apiUser}:${apiPass}" "${jssURL}JSSResource/computergroups/name/${jssGroup}"| xmllint --format - | awk '/<computer_group>/,/<\/computers>/{print}' | sed 's/<\/computers>//' | sed '/^$/d' > "/private/tmp/tmpgroupfile.xml"

if [ -e "/private/tmp/tmpgroupfile.xml" ]; then
    # Get computer's data
    macName=$(scutil --get ComputerName)
    MACAdd1=$(networksetup -getmacaddress en0 | awk '{print $3}')
    MACAdd2=$(networksetup -getmacaddress en1 | awk '{print $3}')
    SerialNo=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

    # Get the Mac's JSS ID using the API
    jssID=$(curl -H "Accept: application/xml" -sfku "${apiUser}:${apiPass}" "${jssURL}JSSResource/computers/macaddress/${MACAdd1}/subset/General" | xmllint --format - | awk -F'>|<' '/<id>/{print $3; exit}')

    echo "JSS ID found for $macName was: $jssID"

    if [[ "$jssID" ]] && [[ "$macName" ]] && [[ "$MACAdd1" ]] && [[ "$MACAdd2" ]] && [[ "$SerialNo" ]]; then
        # echo the xml section for the computer into the temp xml file
        echo '<computer>
        <id>'$jssID'</id>
        <name>'$macName'</name>
        <mac_address>'$MACAdd1'</mac_address>
        <alt_mac_address>'$MACAdd2'</alt_mac_address>
        <serial_number>'$SerialNo'</serial_number>
        </computer>' >> "/private/tmp/tmpgroupfile.xml"

        # Now finish the xml file
        echo '</computers>
        </computer_group>' >> "/private/tmp/tmpgroupfile.xml"
    else
        echo "Some data values are missing. Can't continue"
        exit 1
    fi
else
    echo "The temp xml file could not be found. It may not have been created successfully"
    exit 1
fi

# If we got this far, check the format of the xml file.
# If it passes the xmllint test, try uploading the xml file to the JSS
if [[ $(xmllint --format "/private/tmp/tmpgroupfile.xml" 2>&1 >/dev/null; echo $?) == 0 ]]; then
    echo "XML creation successful. Attempting upload to JSS"

    curl -sfku "${apiUser}:${apiPass}" "${jssURL}JSSResource/computergroups/name/${jssGroup}" -X PUT -T "/private/tmp/tmpgroupfile.xml"

    # Check to see if we got a 0 exit status from the PUT command
    if [ $? == 0 ]; then
        echo "Computer \"$macName\" was added to group \"$jssGroup\""
        # Clean up the xml file
        rm -f "/private/tmp/tmpgroupfile.xml"
        exit 0
    else
        echo "Add to group failed"
        # Clean up the xml file
        rm -f "/private/tmp/tmpgroupfile.xml"
        exit 1
    fi
else
    echo "XML creation failed"
	rm -f "/private/tmp/tmpgroupfile.xml"
    exit 1
fi
