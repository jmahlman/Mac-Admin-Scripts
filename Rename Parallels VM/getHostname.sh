#!/bin/sh
#
#
# I wrote this simple script because we wanted to rename our Parallels VMs to the local Mac hostname
# We set the VM to automatically log into an admin account and run a powershell script to get the name
# from this file and rename the machine.  It then enables autologin for the student account and reboots
#
#

if [ ! -d /Users/Shared ]; then
  mkdir /Users/Shared
fi
scutil --get LocalHostName > /Users/Shared/hostname
chmod 777 /Users/Shared/hostname