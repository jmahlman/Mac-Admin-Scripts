#!/bin/sh

#  autoAddZAppGroup.sh
#
#
# Cut from scripts created by Mario Lopez and John Mahlman hacked together by Tom Cason in 08-25-16
#
# This script is designed to detect the room that a computer is
# located in and automatically assign the appropriate cohort and app group
# using a policy triggered by a JAMF "custom event".
#

###############
#  Functions  #
###############


voice () {
echo "Voice" > /Library/JAMF\ DM/AppGroup/AppGroup.txt
}

animation () {
echo "Animation" > /Library/JAMF\ DM/AppGroup/AppGroup.txt
}

photo () {
echo "Photo" > /Library/JAMF\ DM/AppGroup/AppGroup.txt
}

###############
#  Variables  #
###############

# Get room number from computer name.
roomNumber=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $1}' | tr "[a-z]" "[A-Z]"`


# AppGroup room assignment
AppGroupVoice=(T608 T612 T614 T616 T618 T620 T700 T709)
AppGroupAnimation=(T1403 T1405 T1407 T1409 T1412 T1414 T1415 T1416 T1421 T1423 T1425 T1425C T1425B)
AppGroupPhoto=(T1506 T1513 T1504 T1402)

############
#  Script  #
############

# Make "JAMF DM" directory and hide it.
mkdir /Library/JAMF\ DM
mkdir /Library/JAMF\ DM/Cohort
mkdir /Library/JAMF\ DM/AppGroup
chflags hidden /Library/JAMF\ DM

# Automatically choose the appropriate Cohort based on room number.

if [[ " ${AppGroupVoice[@]} " =~ " ${roomNumber} " ]]; then
	voice

elif [[ " ${AppGroupPhoto[@]} " =~ " ${roomNumber} " ]]; then
	photo

elif [[ " ${AppGroupAnimation[@]} " =~ " ${roomNumber} " ]]; then
	animation

else
echo "$roomNumber does not match any specialty app group. No app group will be added."
exit 0

fi
