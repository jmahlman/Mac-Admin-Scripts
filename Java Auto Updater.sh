#!/bin/sh

fileURL="http://javadl.sun.com/webapps/download/AutoDL?BundleId=106241"

fileLocation="/tmp/java.dmg"
mountLocation="/tmp/java"

#Gets latest version of Java from Web
/usr/bin/curl -L "$fileURL" -o "$fileLocation"

#Auto-mounts dmg
/usr/bin/hdiutil attach "$fileLocation" -mountpoint "$mountLocation" -nobrowse -noverify -noautoopen

#Finds package in file
installerName=$(/bin/ls /tmp/java/ | /usr/bin/egrep .pkg$)

#Runs Installer
/usr/sbin/installer -pkg "/tmp/java/$installerName" -target "/"

#Detach mount
/usr/bin/hdiutil detach "$mountLocation"

#Remove mount location
/bin/rm -rf "$mountLocation"

#Remove file downloaded
/bin/rm -f "$fileLocation"