#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: OS-Out-of-date
#
# Purpose: This literally just gets the currently running OS and alerts the user that they should update.
#
# Changelog
#
# 1/8/18	- Newly created script
#
#

jamf_bin=$(/usr/bin/which jamf)
osvers_major=$(sw_vers -productVersion | awk -F. '{print $1}')
osvers_minor=$(sw_vers -productVersion | awk -F. '{print $2}')

if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -lt 11 ]]; then
  $jamf_bin displayMessage -message \
  "You are currently running Mac OS version $osvers_major.$osvers_minor, you should be running at least Mac OS 10.11 to install most software.

It is HIGHLY recommended that you update to Mac OS 10.12 or newer.

You can upgrade to free using the Mac App Store. If you need assistance, please visit the OTIS Help Desk."
fi
