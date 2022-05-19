#!/bin/bash
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: autoAddPublicCohort.sh
#
# Purpose: This script will add our dummy receipts (which are called cohorts) based on the room/computer name.
#
# Changelog
# 11/6/18 	-	Fixing arrays...again.
# 8/24/18 	- Updated all room arrays.
# 					- Changed env to bash
# 8/23/18		- Adding a generic public cohort if no appropriate room is found.
# 08/10/18 	- Added T1215
# 07/20/19  - Added A815.  Will probably be adding/changing more rooms this summer.
# 02/02/18 	- Forgot to remove the room.  The date reflects the repeat push ;)
# 01/31/18 	- Removed a room from labs and the MUSIC function because it's not needed.
# 10/26/17 	- Added some more suites. Might combine all suites eventually.
# 10/25/17 	- Updated rooms and cleaned up naming.
#						- Fixed header to conform with my other scripts
#						- Removed GALLERY cohort because it's deprecated
#
#

# Creation functions for each cohort
lab () {
	echo "LAB" > /Library/JAMF\ DM/Cohort/RECEIPT-LAB.txt
}

studio () {
	echo "STUDIO" > /Library/JAMF\ DM/Cohort/RECEIPT-STUDIO.txt
}

suite () {
	echo "SUITE" > /Library/JAMF\ DM/Cohort/RECEIPT-SUITE.txt
}

smart_classroom () {
	echo "SMART-CLASSROOM" > /Library/JAMF\ DM/Cohort/RECEIPT-SMART-CLASSROOM.txt
}

# Get room number from system name
roomNumber=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $1}' | tr "[a-z]" "[A-Z]"`

# Arrays for all of our different types of rooms
labNumber=(A231 A309 A615 A626 A728 AM11 T1113 T1213 T1223 T1328 T1423 T1429 T1522 T802 T907)
TsmartClass=(T1014 T1028 T1049 T1053 T1703 T202 T511 T513 T602 T604 T606 T702 T704 T706 T710 T712 T714 T716 T806 T831 T833 T902)
AsmartClass=(A212 A815)
GsmartClass=(G404 G405 G408 G410 G411 G415 H312)
StudioT=(T1219 T1220 T1215 T1404 T1408 T1421 T1425 T1504 T1513 T510 T512 T514 T518)
StudioA=(A200 A315 A316 A317 A318 A319 A320 A220 A716 A723 A725 A726)
suiteVoice=(T612 T614 T616 T618 T620 T608 T709)
suiteGen=(T1403 T1405 T1407 T1409 T1410 T1412 T1414 T1415) #generic suites
suiteDragon=(T1403 T1405 T1407 T1409)
suiteDragonUM=(T1425B T1425C)
editBay=(T1210 T1212 T1214 T1216 T1218 T1220 T1420 T1422)

# Make "JAMF DM" directory and hide it
mkdir /Library/JAMF\ DM
mkdir /Library/JAMF\ DM/Cohort
chflags hidden /Library/JAMF\ DM

# Automatically choose the appropriate Cohort based on room number.
if [[ " ${labNumber[@]} " =~ " ${roomNumber} " ]]; then
	lab

elif [[ " ${StudioT[@]} " =~ " ${roomNumber} " ]]; then
	studio

elif [[ " ${StudioA[@]} " =~ " ${roomNumber} " ]]; then
	studio

elif [[ " ${suiteVoice[@]} " =~ " ${roomNumber} " ]]; then
	suite

elif [[ " ${suiteGen[@]} " =~ " ${roomNumber} " ]]; then
	suite

elif [[ " ${suiteDragon[@]} " =~ " ${roomNumber} " ]]; then
	suite

elif [[ " ${suiteDragonUM[@]} " =~ " ${roomNumber} " ]]; then
	suite

elif [[ " ${editBay[@]} " =~ " ${roomNumber} " ]]; then
	studio

elif [[ " ${TsmartClass[@]} " =~ " ${roomNumber} " ]]; then
	smart_classroom

elif [[ " ${AsmartClass[@]} " =~ " ${roomNumber} " ]]; then
	smart_classroom

elif [[ " ${GsmartClass[@]} " =~ " ${roomNumber} " ]]; then
	smart_classroom

else
	echo "$roomNumber does not match any public spaces. Adding generic PUBLIC cohort."
	echo "PUBLIC" > /Library/JAMF\ DM/Cohort/RECEIPT-PUBLIC.txt
	exit 1

fi
