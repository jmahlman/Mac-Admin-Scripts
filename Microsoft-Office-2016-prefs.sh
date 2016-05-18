#!/bin/sh
#
# Original script by Rich Trouton: https://derflounder.wordpress.com/2016/01/17/suppressing-office-2016s-first-run-dialog-windows/#more-7666
# 
# Customized by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Last Updated: 5/17/16
#
# Name: Microsoft-Office-2016-DisableFirstRun
#
# Purpose: Disables office 2016 first run  
#

echo "Disabling First Run"

# disable first-run dialogs
submit_diagnostic_data_to_microsoft=false

DisableOffice2016FirstRun()
{
   # This function will disable the first run dialog windows for all Office 2016 apps.
   # It will also set the desired diagnostic info settings for Office application.
   defaults write /Library/Preferences/com.microsoft."$app" kSubUIAppCompletedFirstRunSetup1507 -bool true
   defaults write /Library/Preferences/com.microsoft."$app" SendAllTelemetryEnabled -bool "$submit_diagnostic_data_to_microsoft"

   # Outlook and OneNote require one additional first run setting to be disabled
   if [[ $app == "Outlook" ]] || [[ $app == "onenote.mac" ]]; then
     defaults write /Library/Preferences/com.microsoft."$app" FirstRunExperienceCompletedO15 -bool true
   fi
}

# Run the DisableOffice2016FirstRun function for each detected Office 2016
# application to disable the first run dialogs for that Office 2016 application.
if [[ -e "/Applications/Microsoft Excel.app" ]]; then
	app=Excel
	DisableOffice2016FirstRun
fi

if [[ -e "/Applications/Microsoft OneNote.app" ]]; then
	app=onenote.mac
	DisableOffice2016FirstRun
fi

if [[ -e "/Applications/Microsoft Outlook.app" ]]; then
	app=Outlook
	DisableOffice2016FirstRun
fi

if [[ -e "/Applications/Microsoft PowerPoint.app" ]]; then
	app=Powerpoint
	DisableOffice2016FirstRun
fi

if [[ -e "/Applications/Microsoft Word.app" ]]; then
	app=Word
	DisableOffice2016FirstRun
fi

# Quit the script without errors.
exit 0