# uarts-scripts/Rename Parallels VM

I made this in order to get the name from a mac host and rename a parallels VM running windows 10. This was made to work with Casper Suite but you can probably use it with other systems.

Note that I've never written PowerShells scripts before, this is my first.

# Usage

0. Create a VM with your users: Admin and Standard, log into both so initial creation is complete already
	0. Make sure the VM has access to the mac folder ~/Public, this is where "getHostname.sh" drops the hostname file, you can change it if you want, but you also have to change the PowerShell script
	0. Set the windows administrator account to auto-login (You need admin privileges)
	0. Drop "firstrun.bat", "autoLogin.bat", and "RenameVMfromMAC.ps1" into "C:/Users/Public/"
	0. When you are completely updated and ready to roll in Windows, run the "FirstRun.reg" file.  This creates a RunOnce object in the registry that will run the "firstrun.bat" file on the next reboot
	0. Shutdown the VM
0. Package your VM and parallels however you prefer and upload to your JSS along with "getHostname.sh"
0. In your JSS, make a policy that installs your Parallels package and runs "getHostName.sh" (before or after is fine)
	0. When the user starts the VM up it will automatically log in as the admin, run the batch file which calls "RenameVMfromMAC.ps1" and will show the name change progress, set the standard user to automatically login (you can change this also), and reboots the machine, no user intervention is needed unless.... 
		0. Note that the scripts to not check for NETBIOS name length, this can prbably be accomplished easy enough.  If the name is too long the user will have to press 'Y' for the rename to continue.
0. Once rebooted the VM is named vm-\<hostname\> and the standard user now automatically logs in
