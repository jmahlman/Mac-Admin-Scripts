#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: autoAddPublicCohort.sh
#
# Purpose: This script will add our dummy receipts (which are called cohorts) based on the room/computer name.
#
# Changelog
# 10/26/17:	- Added some more suites. Might combine all suites eventually.
# 10/25/17:	- Updated rooms and cleaned up naming.
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

music () {
	echo "MUSIC" > /Library/JAMF\ DM/Cohort/RECEIPT-MUSIC.txt
}

# Get room number from system name
roomNumber=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $1}' | tr "[a-z]" "[A-Z]"`

# Arrays for all of our different types of rooms
labNumber=(A309 A615 A626 A728 AB9 AM11 M209 M707 T1113 T1212 T1213 T1219 T1223 T1328 T1402 T1421 T1423 T1425 T1506 T802 T907)
TsmartClass=(T1014 T1049 T1053 T1102 T1106 T1121 T1202 T1703 T202 T511 T602 T604 T608 T702 T704 T706 T710 T712 T714 T716 T806 T831 T833 T902)
AsmartClass=(AB16)
GsmartClass=(G405 G408 G410 G411 G415 H312)
StudioT=(T1404 T1408)
StudioA=(A315 A316 A317 A318 A319 A231 A220 A716 A723 A725 A726)
suiteVoice=(T612 T614 T616 T618 T620 T700 T709)
suiteGen=(T1112 T1403 T1405 T1407 T1409 T1410 T1412 T1414 T1415 T1416 T1513) #generic suites
suiteDragon=(T1403 T1405 T1407 T1409)
suiteDragonUM=(T1421A T1421B T1425B T1425C)
editBay=(T1108 T1109 T1111 T1114 T1115 T1116 T1117 T1118 T1119)

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
	echo "$roomNumber does not match any public spaces. No cohort will be added."
	exit 1

fi
