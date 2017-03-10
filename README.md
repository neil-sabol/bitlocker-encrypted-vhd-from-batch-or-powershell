# bitlocker-encrypted-vhd-from-batch
Quick and easy creation of BitLocker encrypted VHD images using a BATCH script.

This BATCH (.bat) script helps you create an encrypted container to store sensitive information. It prompts for location, name, size, and password for the container. Scripts to mount and unmount the container are generated automatically and placed on your desktop.

# Requirements
-A version of Windows with Bitlocker support (generally 7 or higher, in Professional or higher flavor)
-Administrator access on your Windows machine

# Usage
1) Download Create-Encrypted-VHD.bat
2) Execute the batch file (accept UAC prompts/etc.)
3) In its simplest form, press enter 4 times, then set a password and a default encrypted VHD container will be created
4) Alternatively, specify options for VHD filename, location (path), size, and drive letter
