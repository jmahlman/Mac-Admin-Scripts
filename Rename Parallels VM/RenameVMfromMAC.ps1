if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$hostMac = Get-Content \\Mac\Shared\hostname
$newName = "vm-$hostMac"

echo "Renaming Compter to $newName"
Rename-Computer -NewName $newName

echo "Setting up UArts-User account to auto-login with no password."
cmd.exe /c 'C:\Users\Public\autoLogin.bat'

echo "RESTARTING VIRTUAL MACHINE NOW!!!!!!!!"
sleep 1
echo "The answer is 42"
Restart-Computer
