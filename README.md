# BitLocker encrypted vhd from batch or PowerShell
These scripts provide a quick and easy way to create Bit Locker encrypted VHD (virtual hard disk) images using Batch or Power Shell. They (mostly) automate creating an encrypted "container" on a local or network drive to store sensitive information. The scripts prompt for the location, name, size, and password for the container (vhd file). "Shortcut" scripts to mount and unmount the container are generated automatically and placed on the user's desktop. These are geared toward end user workstation usage. The idea is very similar to the functionality previously provided by [TrueCrypt](https://en.wikipedia.org/wiki/TrueCrypt).

The BAT method is a little dated and no longer actively maintained.

Feel free to fork/improve - collaboration encouraged. If you encounter a problem, please file an [issue](https://github.com/neil-sabol/bitlocker-encrypted-vhd-from-batch-or-powershell/issues/new/choose) and include your Windows version and the specific error or behavior.


## Requirements
- (BAT/PS) A version of Windows with Bitlocker support (generally 7 or higher, in Professional or higher flavor)

- (BAT/PS) Administrator access on your Windows machine

- (PS version only) PowerShell

- (PS version only) PowerShell execution policy or execution options that permit unsigned scripts


## Usage
1. Download [Create-Encrypted-VHD.bat](https://raw.githubusercontent.com/neil-sabol/bitlocker-encrypted-vhd-from-batch-or-powershell/master/Create-Encrypted-VHD.bat) or [Create-Encrypted-VHD.ps1](https://raw.githubusercontent.com/neil-sabol/bitlocker-encrypted-vhd-from-batch-or-powershell/master/Create-Encrypted-VHD.ps1)

2. Execute the respective file (bypass SmartScreen filter, accept UAC prompts, etc.)

3. In the simplest form, press *Enter* four times, then set a password - a default encrypted VHD container will be created as follows:

* **VHD File Name:** *username*_private.vhd
* **Location:** C:\Users\ *username* \Desktop
* **Size:** 1024 MB (1 GB)
* **Drive letter:** Y:

4. Alternatively, specify options for VHD filename, location (path), size, and drive letter - when prompted, set a password for the encrypted container

As noted, each script generates additional mount/unmount "shortcut" scripts on the user's Desktop. Once mounted, the user must enter the Bit Locker password to access the container.


## Notes
The PowerShell variant places 2 *.txt* files and 2 *.ps1* files in the user's home directory (i.e. C:\Users\yourname). Shortcuts are created on the user's desktop that point to the 2 *.ps1* files.

The Batch variant creates 2 *.bat* files directly on the user's desktop.

If either version of the script aborts after the user selects a password (may occur if the password does not meet the minimum requirements), an orphaned, unencrypted VHD will be left mounted. To unmount it and delete it, do the following:

1. Launch Computer Management (right-click Start menu, select `Computer Management`)

2. Open `Disk Management`, under `Storage`

3. Right-click the VHD disk and select `Detach`

4. Once detached, you can delete the .vhd file


If the Power Shell version does not execute on your computer, you may need to relax your execution policy. Launch a PowerShell prompt and enter the following:

```
Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted
```

Alternatively, you can run `Create-Encrypted-VHD.ps1` as follows (but note, if you do not permanently adjust the execution policy for the user that will mount/unmount the encrypted container, the shortcuts may not work as intended):

```
powershell.exe -executionpolicy bypass -file Create-Encrypted-VHD.ps1
```
