#!/bin/sh
#
# Written by John Mahlman
# 5/4/2016
#
# Login script for creating and editing Ableton Live database files to match new users
# $3 is current username as defined by Casper Suite.  Obviously this can be changed to $USER is you want to use this standalone
#
# NOTE: This script actually edits the db file!  I have not seen any issues doing this
# but I will not guarantee that it will not cause instability or corruption.
#
#
#############
# Variables #
#############
db='/Users/Shared/Database'

##########
# Script #
##########
if [ -d $db/macadmin ] ; then 		# We need to make sure that the macadmin database is on the local machine first
    if [ ! -d $db/$3 ] ; then 		# If it is, does this user already have a database? If so, just skip it, it not...
        cp -R $db/macadmin $db/$3 	# Copy that folder with the new username
        chown -R $3 $db/$3 			# Give the user ownership 
		LANG=C sed -i "" "s/macadmin/$3/g" $db/$3/Live\ 9.5/Database/files.db 
		# ^ the "fun" part; replace all instances of "macadmin" in the db file with the new username.
    fi
fi
