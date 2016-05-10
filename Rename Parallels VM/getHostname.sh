#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 5/10/16
#
# Name: getHostname
#
# Purpose: Gets local hostname and drops it into a file.  This was created for a greater purpose:
# Renaming a Parallels VM automatically.  See more here: https://github.com/jmahlman/uarts-scripts/tree/master/Rename%20Parallels%20VM
#
#
localName='scutil --get LocalHostName'
##########
# Script #
##########
if [ ! -d /Users/Shared ]; then
  mkdir /Users/Shared
fi

$localName | head -c 12 > /Users/Shared/hostname
chmod 777 /Users/Shared/hostname