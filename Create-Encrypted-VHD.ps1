# ###############################
# Neil Sabol
# neil.sabol@gmail.com
# ###############################

# See https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/
# This escalation code is GENIUS!
# Thanks @Ben (https://social.msdn.microsoft.com/profile/Benjamin+Armstrong)

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   # Exit from the current, unelevated, process
   exit
   }

# Begin the actual script (elevated)
Write-Host "---------------------------------------------------------------------"
Write-Host "This script helps you create an encrypted container to store sensitive"
Write-Host "information. You will be prompted to specify a location, name, size,"
Write-Host "and password for the container. If desired, scripts to mount and"
Write-Host "unmount the container will be created and placed on your desktop."
Write-Host ""
Write-Host "DO NOT CLOSE THIS WINDOW - it will close automatically when the process is"
Write-Host "is complete."
Write-Host "---------------------------------------------------------------------"
Write-Host ""
Write-Host ""

$vhdNameDefault=$env:UserName + "_private"
$vhdPathDefault="C:\Users\$env:UserName\Desktop"
$vhdSizeDefault=1024
$vhdLetterDefault="Y:"

Write-Host "To accept the default options, press enter 4 times, then set a password"
Write-Host ""
Write-Host ""
Write-Host "Helpful hints:"
Write-Host "*Paths must be fully qualified (H:, C:\Users\yourname\Desktop, etc.)"
Write-Host "*You can copy/paste paths from Explorer"
Write-Host "*Size must be a number, entered in MB (500, 1024, etc.)"
Write-Host "*There are 1024 MB in 1 GB"
Write-Host ""
Write-Host ""

# Capture user input regarding container creation
$vhdName=Read-Host -Prompt "Encrypted container name? (default is $vhdNameDefault )"
if($vhdName -eq ""){$vhdName=$vhdNameDefault}
$vhdPath=Read-Host -Prompt "Location? (default path is C:\Users\$env:UserName\Desktop )"
if($vhdPath -eq ""){$vhdPath=$vhdPathDefault}
$vhdSize=Read-Host -Prompt "Size in MB? (default is 1024 )"
if($vhdSize -eq ""){$vhdSize=$vhdSizeDefault}
$vhdLetter=Read-Host -Prompt "Drive letter? (default is Y: )"
if($vhdLetter -eq ""){$vhdLetter=$vhdLetterDefault}

# Create diskpart script and execute diskpart
Write-Host ""
Write-Host ""
"CREATE VDISK FILE=`"$vhdPath\$vhdName.vhd`"  MAXIMUM=$vhdSize TYPE=expandable" | Out-File -filepath diskpart.txt
"SELECT VDISK FILE=`"$vhdPath\$vhdName.vhd`"" | Out-File -filepath diskpart.txt -Append
"ATTACH VDISK" | Out-File -filepath diskpart.txt -Append
"CREATE PARTITION PRIMARY" | Out-File -filepath diskpart.txt -Append
"FORMAT QUICK FS=NTFS LABEL=`"$vhdName`"" | Out-File -filepath diskpart.txt -Append
"ASSIGN LETTER=$vhdLetter" | Out-File -filepath diskpart.txt -Append
Type diskpart.txt | diskpart | Out-Null
IF ($lastExitCode -ne 0) {
    del diskpart.txt
    Write-Host "Something went wrong while creating the VHD file - the script will now terminate."
    pause
    exit
}
del diskpart.txt

Write-Host ""
Write-Host "---------------------------------------------------------------------"
Write-Host "PLEASE NOTE, IF YOU LOSE THE PASSWORD YOU SPECIFY FOR THIS CONTAINER,"
Write-Host "YOUR DATA WILL BE UNRECOVERABLE."
Write-Host "---------------------------------------------------------------------"
Write-Host ""

# Enable bitlocker and set password on the new volume
manage-bde -on $vhdLetter -used -Password
IF ($lastExitCode -ne 0) {
    Write-Host "Something went wrong while encrypting the VHD file - the script will now terminate. You may need to open"
    Write-Host "Disk Management and manually detach the VHD file prior to deleting it."
    pause
    exit
}

Write-Host ""
Write-Host ""

# Check if mount/unmount scripts are desired
$confirmscriptcreation=Read-Host -Prompt "Would you like scripts to mount and unmount this container created and placed on your desktop? (y/n)"
if($confirmscriptcreation -eq "y") {
   # Generate mount diskpart commands and scripts
   "select vdisk file=""$vhdPath\$vhdName.vhd""" | Out-File -filepath $env:USERPROFILE\diskpartm-$vhdName.txt
   "attach vdisk" | Out-File -filepath $env:USERPROFILE\diskpartm-$vhdName.txt -Append
   
   # This part is NASTY - ensure the mount script can self-elevate
   "`$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1
   "`$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal(`$myWindowsID)" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "`$adminRole=`[System.Security.Principal.WindowsBuiltInRole]::Administrator" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "if (`$myWindowsPrincipal.IsInRole(`$adminRole))" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "{" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "`$Host.UI.RawUI.WindowTitle = `$myInvocation.MyCommand.Definition `+ `"`(Elevated`)`"" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "`$Host.UI.RawUI.BackgroundColor = `"DarkBlue`"" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "clear-host" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "}" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "else" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "{" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "`$newProcess = new-object System.Diagnostics.ProcessStartInfo `"PowerShell`";" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "`$newProcess.Arguments = `$myInvocation.MyCommand.Definition;" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "`$newProcess.Verb = `"runas`";" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "[System.Diagnostics.Process]::Start(`$newProcess);" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "exit" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "}" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   "type `"$env:USERPROFILE\diskpartm-$vhdName.txt`" | diskpart" | Out-File -filepath $env:USERPROFILE\MOUNT-$vhdName.ps1 -Append
   
   # Generate unmount diskpart commands and scripts
   "select vdisk file=""$vhdPath\$vhdName.vhd""" | Out-File -filepath $env:USERPROFILE\diskpartu-$vhdName.txt
   "detach vdisk" | Out-File -filepath $env:USERPROFILE\diskpartu-$vhdName.txt -Append
   
   # This part is NASTY - ensure the unmount script can self-elevate
   "`$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1
   "`$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal(`$myWindowsID)" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "`$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "if (`$myWindowsPrincipal.IsInRole(`$adminRole))" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "{" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "`$Host.UI.RawUI.WindowTitle = `$myInvocation.MyCommand.Definition + `"(Elevated)`"" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "`$Host.UI.RawUI.BackgroundColor = `"DarkBlue`"" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "clear-host" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "}" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "else" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "{" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "`$newProcess = new-object System.Diagnostics.ProcessStartInfo `"PowerShell`";" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "`$newProcess.Arguments = `$myInvocation.MyCommand.Definition;" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "`$newProcess.Verb = `"runas`";" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "[System.Diagnostics.Process]::Start(`$newProcess);" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "exit" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "}" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   "type `"$env:USERPROFILE\diskpartu-$vhdName.txt`" | diskpart" | Out-File -filepath $env:USERPROFILE\UNMOUNT-$vhdName.ps1 -Append
   
   # Create shortcuts to scripts
   $WshShell = New-Object -comObject WScript.Shell
   $ShortcutMount = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\MOUNT-$vhdName.lnk")
   $ShortcutMount.TargetPath = "$env:USERPROFILE\MOUNT-$vhdName.ps1"
   $ShortcutMount.Save()

   $WshShell = New-Object -comObject WScript.Shell
   $ShortcutUnmount = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\UNMOUNT-$vhdName.lnk")
   $ShortcutUnmount.TargetPath = "$env:USERPROFILE\UNMOUNT-$vhdName.ps1"
   $ShortcutUnmount.Save()
}

# Print friendly exit message and open container in explorer
Write-Host ""
Write-Host "Your encrypted container was created! If you opted for scripts to mount"
Write-Host "and unmount your container, they can be found on your desktop (MOUNT-$vhdName"
Write-Host "and UNMOUNT-$vhdName)."
Write-Host ""
Write-Host ""
pause
EXPLORER.EXE $vhdLetter
EXIT
