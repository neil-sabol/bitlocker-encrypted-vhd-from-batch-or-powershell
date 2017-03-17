# bitlocker-encrypted-vhd-from-batch-or-powershell
Quick and easy creation of BitLocker encrypted VHD (virtual hard disk) images using a BATCH script or PowerShell. BAT method is a little dated (oldie but goodie maybe?). Feel free to fork/improve - collaboration encouraged.

These scripts help you create an encrypted container on your local or network drive to store sensitive information. They prompt for location, name, size, and password for the container (vhd file). Scripts to mount and unmount the container are generated automatically and placed on your desktop. These are intended for end user workstations.

## Requirements
- (BOTH) A version of Windows with Bitlocker support (generally 7 or higher, in Professional or higher flavor)

- (BOTH) Administrator access on your Windows machine

- (PS1 version only) PowerShell

- (PS1 version only) PowerShell execution policy that permits unsigned scripts

## Usage
1. Download `Create-Encrypted-VHD.bat` or `Create-Encrypted-VHD.ps1`

2. Execute the respective file (accept UAC prompts/etc.)

3. In the simplest form, press enter 4 times, then set a password and a default encrypted VHD container will be created

4. Alternatively, specify options for VHD filename, location (path), size, and drive letter - when prompted, set a password for the encrypted container


As noted, each script generates additional mount/unmount scripts on your Desktop. Once mounted, you must enter the Bit Locker password you set to access the container.

## Notes
The PowerShell variant places 2 .txt files and 2 .ps1 files on your Windows user (home) directory (i.e. C:\Users\<<yourname>>). Shortcuts are created on your desktop that point to the 2 .ps1 files.

The BATCH variant creates 2 .bat files directly on your desktop.

If either version of the script aborts after you select a password (may occur if you select a password that does not meet the minimum requirments), the VHD will be left mounted. To unmount it, delete it, and try again, you must do the following:

1. Launch Computer Management (right-click Start menu, select `Computer Management`)

2. Open `Disk Management`, under `Storage`

3. Right-click the VHD disk and select `Detach`

4. Once detached, you can delete the .vhd file from disk


If the Power Shell version does not execute on your computer, you may need to relax your execution policy. Launch a PowerShell prompt and enter the following:

>Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted
