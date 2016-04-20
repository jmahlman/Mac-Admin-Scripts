#!/bin/sh

fileURL="https://evernote.com/download/get.php?file=EvernoteMac"

fileLocation="/tmp/Evernote.dmg"
newFileLocation="/tmp/Evernote.cdr"
mountLocation="/tmp/Evernote"

/usr/bin/curl -L "$fileURL" -o "$fileLocation"

#tmpMount='usr/bin/mktemp -d /tmp/Evernote.XXXX'

/usr/bin/hdiutil convert -quiet "$fileLocation" -format UDTO -o "$newFileLocation"

/usr/bin/hdiutil attach "$newFileLocation" -mountpoint "$mountLocation" -nobrowse -noverify -noautoopen

# Kill Evernote
/usr/bin/killall Evernote

# Install Evernote into Applications folder
/bin/cp -RL "$mountLocation/Evernote.app" "/Applications"

/usr/bin/hdiutil detach "$mountLocation"

/bin/rm -rf "$mountLocation"

/bin/rm -f "$fileLocation"

/bin/rm -f "$newFileLocation"