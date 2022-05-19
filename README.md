# Mac Admin Scripts

Ths is a repo of scripts that I have written for various needs as a Mac Admin. Lots of shell scripts. If it's in anything marked "Archived" or in a folder with "Archived" means I don't update those anymore.

## Info about the scripts I have here

* __Adobe-RUMWithProgress-jamfhelper__: This script uses jamfhelper to show which updates are available for Adobe CC and asks if they would like to install those updates.  If they choose to install updates it will begin installing updates.

* __Jamf Large Install Helper__: This script will be used to show a user the progress of large installs using DEPNotify and Jamf policies. Will show the user a download and install progress dialog (as well as runs some checks) instead of just a spinning circle in Self Service. I wrote this to use with Jamf but I'm sure it can be altered for other tools. 
  * This script also takes a long of Jamf parameters:
    * Parameter 4: Friendly Application Name (ex: _Apple Xcode_)
    * Parameter 5: Jamf Trigger for caching package( (ex: _cache-xcode_) Note this has to be a policy to CACHE a package, not install.
    * Parameter 6: Package Name (with .pkg) (ex: _Apple-Xcode-13.3.1.pkg_)
    * Parameter 7: Package size in KB (whole numbers only) (ex: _16013572_) I get this with `$PACKAGENAME | awk '{ print $5 }' | awk '{$1/=1024;printf "%.i\n",$1}'`
    * Parameter 8: Minimum drive space required (default 5) (ex: _45_)
    * Parameter 9: Extended timeout time in seconds (default 60) (ex: _10_) How long to wait for the download to start before failing

If you find any of these helpful, feel free to drop me a comment in the macadmins slack, my username is jmahlman.