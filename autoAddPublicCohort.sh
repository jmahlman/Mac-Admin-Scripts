#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 8/29/16
#
# Name: autoAddPublicCohort.sh
#
# Purpose: This script will add our dummy receipts (which are called cohorts) based on the room/computer name.
#

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

gallery () {
	echo "GALLERY" > /Library/JAMF\ DM/Cohort/RECEIPT-GALLERY.txt
}

music () {
	echo "MUSIC" > /Library/JAMF\ DM/Cohort/RECEIPT-MUSIC.txt
}

# Get room number from system name
roomNumber=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $1}' | tr "[a-z]" "[A-Z]"`

# Make "JAMF DM" directory and hide it
mkdir /Library/JAMF\ DM
mkdir /Library/JAMF\ DM/Cohort
chflags hidden /Library/JAMF\ DM

# Arrays for all rooms that we care about
labRooms=(A309 A615 A626 A728 AB9 AM11 T802 T907 T1113 T1212 T1213 T1219 T1223 T1328 T1402 T1421 T1423 T1425 T1506 DANCE TEMP)
studioRooms=(A315 A316 A317 A318 A319 A320 T510 T512 T514 T518 T1215 A716 A723 A725 A726 H160 T1404 T1408 T1504)
suiteRooms=(A714 T1112 T1410 T1405 T1403 T1407 T1412 T1415 T1414 T1421A T1421B T1425B T1108 T1109 T1111 T1114 T1115 T1116 T1117 T1118 T1119 FTC AM28 T1427A T1427I T1513 T612 T614 T616 T618 T620 T700 T701 T709 T1209 T1409)
musicRooms=(M205 M206 M208 M209 M210 M605 M707)
smartClassrooms=(T511 T513 A212 A815 AB16 G404 G405 G408 G410 G411 G415 H312 T1014 T1028 T1049 T1053 T1102 T1106 T1107 T1121 T1123 T1202 T1221 T202 T602 T604 T606 T608 T702 T704 T706 T710 T712 T714 T806 T831 T833 T902 T1703)
galleryRooms=(HG2)

# Write COHORT based on room here
if [[ " ${labRooms[@]} " =~ " ${roomNumber} " ]]; then
	lab
	
elif [[ " ${studioRooms[@]} " =~ " ${roomNumber} " ]]; then
	studio
	
elif [[ " ${suiteRooms[@]} " =~ " ${roomNumber} " ]]; then
	suite
	
elif [[ " ${musicRooms[@]} " =~ " ${roomNumber} " ]]; then
	music
	
elif [[ " ${smartClassrooms[@]} " =~ " ${roomNumber} " ]]; then
	smart_classroom
	
elif [[ " ${galleryRooms[@]} " =~ " ${roomNumber} " ]]; then
	gallery

else
	echo "$roomNumber does not match any public spaces. No cohort will be added."
	exit 1

fi
