# ###############################
# BitLocker encrypted vhd from batch or PowerShell
# https://github.com/neil-sabol/bitlocker-encrypted-vhd-from-batch-or-powershell
# Neil Sabol
# neil.sabol@gmail.com
# ###############################

# Allow parameters to be passed (for automation) - note that $vhdCredential must be
# a PowerShell credential object.
param ($vhdName, $vhdPath, $vhdSize, $vhdLetter, $vhdCredential, $confirmscriptcreation)

# Ensure either the BitLocker PowerShell Module or manage-bde command line tool is available
# https://docs.microsoft.com/en-us/powershell/module/bitlocker/?view=win10-ps
# https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/manage-bde
# One of these is required to programmatically encrypt the VHD container
if((Get-Module -ListAvailable -Name "BitLocker")) {
    $encryptMethod = "powershell"
} elseif((Test-Path "C:\Windows\System32\manage-bde.exe")) {
    $encryptMethod = "manage-bde"
    if($vhdCredential) {
        Write-Host ""
        Write-Host "WARNING: The -cred parameter will be ignored since the BitLocker"
        Write-Host "PowerShell Module is not available on this system. You will need"
        Write-Host "to set your container password manually when prompted."
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "Sorry, no suitable BitLocker management commands are available. This script will now exit."
    Write-Host ""
    if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) { pause }
    exit 1
}

# See https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/
# This escalation code is GENIUS!
# Thanks @Ben (https://social.msdn.microsoft.com/profile/Benjamin+Armstrong)

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole)) {
   # We are running "as Administrator" - no action needed
} else {
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
# Print friendly introduction unless running non-interactively
if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) {
    Write-Host ""
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
}

$vhdNameDefault=$env:UserName + "_private"
$vhdPathDefault="C:\Users\$env:UserName\Desktop"
$vhdSizeDefault=1024
$vhdLetterDefault="Y:"

# Print hints unless running non-interactively
if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) {
    Write-Host "To accept the default options, press enter four times and set a password"
    Write-Host ""
    Write-Host ""
    Write-Host "Helpful hints:"
    Write-Host "--------------"
    Write-Host "*Paths must be fully qualified (i.e. H:, C:\Users\yourname\Desktop, etc.)"
    Write-Host "*You can copy/paste paths from Explorer"
    Write-Host "*Size must be a number in MB (500, 1024, etc.)"
    Write-Host "*There are 1024 MB in 1 GB"
    Write-Host ""
    Write-Host ""
}

# Capture user preferences regarding container creation - skip setting supplied via parameters
if(-not $vhdName) {
    $vhdName=Read-Host -Prompt "Encrypted container name? (default is $vhdNameDefault )"
    if($vhdName -eq ""){$vhdName=$vhdNameDefault}
}

if(-not $vhdPath) {
    $vhdPath=Read-Host -Prompt "Location? (default path is C:\Users\$env:UserName\Desktop )"
    if($vhdPath -eq ""){$vhdPath=$vhdPathDefault}
}

if(-not $vhdSize) {
    $vhdSize=Read-Host -Prompt "Size in MB? (default is 1024 )"
    if($vhdSize -eq ""){$vhdSize=$vhdSizeDefault}
}

if(-not $vhdLetter) {
    $vhdLetter=Read-Host -Prompt "Drive letter? (default is Y: )"
    if($vhdLetter -eq ""){$vhdLetter=$vhdLetterDefault}
}

# Create a diskpart script and execute diskpart
if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) { Write-Host "" }
"CREATE VDISK FILE=`"$vhdPath\$vhdName.vhd`"  MAXIMUM=$vhdSize TYPE=expandable" | Out-File -filepath diskpart.txt
"SELECT VDISK FILE=`"$vhdPath\$vhdName.vhd`"" | Out-File -filepath diskpart.txt -Append
"ATTACH VDISK" | Out-File -filepath diskpart.txt -Append
"CREATE PARTITION PRIMARY" | Out-File -filepath diskpart.txt -Append
"FORMAT QUICK FS=NTFS LABEL=`"$vhdName`"" | Out-File -filepath diskpart.txt -Append
"ASSIGN LETTER=$vhdLetter" | Out-File -filepath diskpart.txt -Append
Type diskpart.txt | diskpart | Out-Null
if($lastExitCode -ne 0) {
    del diskpart.txt
    Write-Host "ERROR: Something went wrong while creating the VHD file - the script will now terminate."
    if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) { pause }
    exit 1
}
del diskpart.txt

# diskpart accepts a drive letter or drive letter with a colon (i.e. F -or- F:) - manage-bde DOES NOT and always requires a colon (i.e F:)
# This is not a perfect fix, but appending a colon if one is missing catches some issues.
if(! $vhdLetter.EndsWith(":") ) {
    $vhdLetter=$vhdLetter+":"
}

# Print password warning unless running non-interactively
if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) {
    Write-Host ""
    Write-Host "---------------------------------------------------------------------"
    Write-Host "PLEASE NOTE, IF YOU LOSE THE PASSWORD YOU SPECIFY FOR THIS CONTAINER,"
    Write-Host "YOUR DATA WILL BE UNRECOVERABLE."
    Write-Host "---------------------------------------------------------------------"
    Write-Host ""
}

# Enable bitlocker using PowerShell (Enable-BitLocker) and prompt for a password on the new volume if not supplied via parameter
if($encryptMethod -eq "powershell") {
    if($vhdCredential) {
        Enable-BitLocker -MountPoint $vhdLetter -EncryptionMethod Aes256 -UsedSpaceOnly -Password $vhdCredential -PasswordProtector | Out-Null
    } else {
        # Enable-Bitlocker oes not prompt for a password (it must be supplied as a secure string)
        # Replicate the password prompt and behavior from manage-bde and apply it to the enable-bitlocker cmdlet
        $vhdCredential=Read-Host -AsSecureString -Prompt "Type the password to use to protect the volume"
        $vhdCredentialConfirm=Read-Host -AsSecureString -Prompt "Confirm the password by typing it again"
        
        # This is not ideal, but secure strings must be converted back to plain text for comparison
        # See https://www.roelvanlisdonk.nl/2010/03/23/show-password-in-plaintext-by-using-get-credential-in-powershell/
        $vhdCredentialAsText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($vhdCredential))
        $vhdCredentialConfirmAsText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($vhdCredentialConfirm))
        if($vhdCredentialAsText -eq $vhdCredentialConfirmAsText) {
            # Clear the plain-text password values as soon as possible
            $vhdCredentialAsText = ""
            $vhdCredentialConfirmAsText = ""
            Enable-BitLocker -MountPoint $vhdLetter -EncryptionMethod Aes256 -UsedSpaceOnly -Password $vhdCredential -PasswordProtector | Out-Null
        } else {
            # Clear the plain-text password values as soon as possible
            $vhdCredentialAsText = ""
            $vhdCredentialConfirmAsText = ""
            # Try to clean up the mounted VHD and file
            Dismount-DiskImage -ImagePath "$vhdPath\$vhdName.vhd"
            sleep 2
            Remove-Item -Path "$vhdPath\$vhdName.vhd" -Force | Out-Null
            write-host ""
            write-host "ERROR: The values you have entered do not match - the script will now terminate."
            write-host "You may need to open Disk Management and manually detach the VHD file prior"
            Write-Host "to deleting it."
            write-host ""
            if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) { pause }
            exit 1
        }
    }
    if($lastExitCode -ne 0) {
        # Try to clean up the mounted VHD and file
        Dismount-DiskImage -ImagePath "$vhdPath\$vhdName.vhd"
        sleep 2
        Remove-Item -Path "$vhdPath\$vhdName.vhd" -Force | Out-Null
        Write-Host ""
        Write-Host "ERROR: Something went wrong while encrypting the VHD file - the script will now terminate. You may need to open"
        Write-Host "Disk Management and manually detach the VHD file prior to deleting it."
        Write-Host ""
        if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) { pause }
        exit 1
    }
}

# Enable bitlocker using manage-bde if the PowerShell module is not available (and prompt for a password on the new volume)
if($encryptMethod -eq "manage-bde") {
    manage-bde -on $vhdLetter -EncryptionMethod aes256 -used -Password
    if($lastExitCode -ne 0) {
        # Try to clean up the mounted VHD and file
        Dismount-DiskImage -ImagePath "$vhdPath\$vhdName.vhd" | Out-Null
        sleep 2
        Remove-Item -Path "$vhdPath\$vhdName.vhd" -Force
        Write-Host ""
        Write-Host "ERROR: Something went wrong while encrypting the VHD file - the script will now terminate."
        Write-Host "You may need to open Disk Management and manually detach the VHD file prior to deleting it."
        Write-Host ""
        if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) { pause }
        exit 1
    }
}

if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) {
    Write-Host ""
    Write-Host ""
}

# Ask the user if mount/unmount scripts are desired (unless supplied via parameter)
if(-not $confirmscriptcreation) {
    $confirmscriptcreation=Read-Host -Prompt "Would you like scripts to mount and unmount this container created and placed on your desktop? (y/n)"
}
if($confirmscriptcreation -eq "y") {
   # Create a PowerShell script on the user's Desktop to MOUNT the container 
   # This part is NASTY - ensure the MOUNT script can self-elevate
   "`$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1
   "`$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal(`$myWindowsID)" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "`$adminRole=`[System.Security.Principal.WindowsBuiltInRole]::Administrator" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "if (`$myWindowsPrincipal.IsInRole(`$adminRole))" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "{" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "}" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "else" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "{" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "`$newProcess = new-object System.Diagnostics.ProcessStartInfo `"PowerShell`";" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "`$newProcess.Arguments = `$myInvocation.MyCommand.Definition;" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "`$newProcess.Verb = `"runas`";" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "[System.Diagnostics.Process]::Start(`$newProcess);" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "exit" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "}" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   "Mount-DiskImage -ImagePath `"$vhdPath\$vhdName.vhd`"" | Out-File -filepath $env:USERPROFILE\Desktop\MOUNT-$vhdName.ps1 -Append
   
   # Create a PowerShell script on the user's Desktop to UNMOUNT the container 
   # This part is NASTY - ensure the UNMOUNT script can self-elevate
   "`$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1
   "`$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal(`$myWindowsID)" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "`$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "if (`$myWindowsPrincipal.IsInRole(`$adminRole))" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "{" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "}" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "else" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "{" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "`$newProcess = new-object System.Diagnostics.ProcessStartInfo `"PowerShell`";" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "`$newProcess.Arguments = `$myInvocation.MyCommand.Definition;" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "`$newProcess.Verb = `"runas`";" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "[System.Diagnostics.Process]::Start(`$newProcess);" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "exit" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "}" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
   "Dismount-DiskImage -ImagePath `"$vhdPath\$vhdName.vhd`"" | Out-File -filepath $env:USERPROFILE\Desktop\UNMOUNT-$vhdName.ps1 -Append
}

# Print a friendly exit message and open the container in explorer unless running non-interactively
if(-not ($vhdName -and $vhdPath -and $vhdSize -and $vhdLetter -and $vhdCredential -and $confirmscriptcreation)) {
    Write-Host ""
    Write-Host "Your encrypted container was created! If you opted for scripts to mount"
    Write-Host "and unmount your container, they can be found on your desktop (MOUNT-$vhdName"
    Write-Host "and UNMOUNT-$vhdName). You can use them to mount and unmount the container"
    Write-Host "going forward. This script already mounted the container and will open"
    Write-Host "it when you press a key."
    Write-Host ""
    Write-Host ""
    pause
    explorer.exe $vhdLetter
}

exit 0
