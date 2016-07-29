#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 7/29/16
#
# Name: ea-whitelistNetboot
#
# Purpose: Casper extension attribute to get the whitelisted netboot servers on 10.11 systems
#
osvers_major=$(sw_vers -productVersion | awk -F. '{print $1}')
osvers_minor=$(sw_vers -productVersion | awk -F. '{print $2}')

# Checks to see if the OS on the Mac is 10.x.x. If it is not, the 
# following message is displayed without quotes:
#
# "Unknown Version Of Mac OS X"

if [[ ${osvers_major} -ne 10 ]]; then
  echo "Unknown Version of Mac OS X"
fi

# Checks to see if the OS on the Mac is 10.11.x or higher.
if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -lt 11 ]]; then
  echo "System Integrity Protection Not Available For `sw_vers -productVersion`"
fi

if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -ge 11 ]]; then
	# Checks System Integrity Protection status on Macs
	# running 10.11.x or higher
	SIP_status=`/usr/bin/csrutil status | awk '/status/ {print $5}' | sed 's/\.$//'`
	# If it's disabled, just print disabled
	if [[ $SIP_status == "disabled" ]]; then
		echo "<result>SIP Disabled</result>"
		# if it's enabled, we'll get the netboot list
	elif [[ $SIP_status == "enabled" ]]; then
		netbootList=`/usr/bin/csrutil netboot list`
		echo "<result>$netbootList</result>"
	fi
fi
