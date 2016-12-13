#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 12/13/16
#
# Name: killBrowsers.sh
#
# Purpose: This script will kill all browsers in our environment if the user has been idle for 10 minutes.
# (I wrote this because we have people complaining about the browsers keeping their accounts logged in
# which is actually a problem of users not quitting browsers when done. It just checks idle time and if
# a browser is running and kills it.) I run this at every check-in.
#
# get idle time in seconds
idleTime=`/usr/sbin/ioreg -c IOHIDSystem | /usr/bin/awk '/HIDIdleTime/ {print int($NF/1000000000); exit}'`
# get Chrome pid (is it running?)
chromeOn=`ps -A | grep -m1 '[G]oogle Chrome' | awk '{print $1}'`
# get Sarafi pid (is it running?)
safariOn=`ps -A | grep -m1 [S]afari | awk '{print $1}'`
# get Firefox pid (is it running?)
firefoxOn=`ps -A | grep -m1 [f]irefox | awk '{print $1}'`


if [[ $idleTime -ge "600" ]]; then
	if [[ $chromeOn != "" ]]; then
		echo "Killing Chrome"
		killall "Google Chrome"
	else
		echo "Chrome not running."
	fi
	if [[ $safariOn != "" ]]; then
		echo "Killing Safari"
		killall Safari
	else
		echo "Safari not running."
	fi
	if [[ $firefoxOn != "" ]]; then
		echo "Killing Firefox"
		killall firefox
	else
		echo "Firefox not running."
	fi
fi