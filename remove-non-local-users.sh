#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 6/15/16
#
# Name: remove-non-local-users
#
# Purpose: Removes all non-local accounts on machines to help stop HDs from filling up
# Will spare the 'macadmin,' 'student,' and 'Shared' home directories.
#
#
users=`find /Users -type d -maxdepth 1 | cut -d"/" -f3`
# you can edit this to remove only accounts that haven't logged in for x days: add '-mtime +<# of days>' after maxdepth

##########
# Script #
##########
for i in $users; do
    if [[ $i = "macadmin" ]] || [[ $i = "Shared" ]] || [[ $i = "student" ]]; then continue
    else 
        jamf deleteAccount -username $i -deleteHomeDirectory
        rm -Rf /Users/$i
    fi
done
# Remove the student home directory but leave the account at the end.
rm -Rf /Users/student

