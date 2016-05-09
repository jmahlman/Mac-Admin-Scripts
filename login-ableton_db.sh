#!/bin/sh
#
# Written by John Mahlman
# 5/4/2016
#
# Login script for copying and editing Ableton Live database files to match new users
# $3 is current username as defined by Casper Suite.  Obviously this can be changed to $USER is you want to use this standalone
# 
# NOTE: This script actually edits the db file!  
#
# HEY GUESS WHAT?  THIS DOESN'T ACTUALLY WORK.  WELL, THE SCRIPT WORKS FINE BUT ABLETON WILL STILL RE-INDEX UNLESS YOU GET LUCKY.
# SO...THIS SCRIPT IS KINDA USELESS.  BUT I'LL STILL KEEP IT AROUND..MAYBE I CAN FIGURE OUT HOW TO ACTUALLY EDIT THE DB FILE PROPERLY.
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
