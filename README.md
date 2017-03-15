# bitlocker-encrypted-vhd-from-batch-or-powershell
Quick and easy creation of BitLocker encrypted VHD images using a BATCH script or PowerShell. BAT method is a little dated (oldie but goodie maybe?). Feel free to fork/improve - collaboration encouraged.

These scripts help you create an encrypted container on your local or network drive to store sensitive information. They prompt for location, name, size, and password for the container (vhd file). Scripts to mount and unmount the container are generated automatically and placed on your desktop.

# Requirements
- (BOTH) A version of Windows with Bitlocker support (generally 7 or higher, in Professional or higher flavor)

- (BOTH) Administrator access on your Windows machine

- (PS1 version only) PowerShell

- (PS1 version only) PowerShell execution policy that permits unsigned scripts

# Usage
1. Download Create-Encrypted-VHD.bat or Create-Encrypted-VHD.ps1

2. Execute the respective file (accept UAC prompts/etc.)

3. In the simplest form, press enter 4 times, then set a password and a default encrypted VHD container will be created

4. Alternatively, specify options for VHD filename, location (path), size, and drive letter - when prompted, set a password for the encrypted container


As noted, the each script generates additional mount/unmount scripts on your Desktop. Once mounted, you must enter the BitLocker password you set to access the container.
