# BitLocker encrypted vhd "containers" from PowerShell
This script provides a quick and easy way to create Bit Locker encrypted VHD (virtual hard disk) images using Power Shell. It automates creating an encrypted "container" on a local or network drive to store sensitive information. The script prompts for the location, name, size, and password for the container (vhd file); alternatively, the script can be executed unattended (silently) using parameters. "Shortcut" scripts to mount and unmount the container are generated automatically (if desired) and placed on the user's desktop. 

This project is geared toward end-user workstation usage. The idea is very similar to the functionality previously provided by [TrueCrypt](https://en.wikipedia.org/wiki/TrueCrypt).

```diff
-The BAT script is dated and no longer actively maintained or supported.
```

Feel free to fork/improve - collaboration encouraged. If you encounter a problem, please start a [discussion](https://github.com/neil-sabol/bitlocker-encrypted-vhd-from-batch-or-powershell/discussions/new) and include your Windows version and the specific error or behavior.


## Requirements
- A version of Windows Server 2012+ or Windows 8.1+ with Bitlocker support (generally Professional or higher flavor)

- Administrator access on your Windows machine

- PowerShell (and an execution policy or execution options that permit unsigned scripts)


## Usage
1. Download [Create-Encrypted-VHD.ps1](https://raw.githubusercontent.com/neil-sabol/bitlocker-encrypted-vhd-from-batch-or-powershell/master/Create-Encrypted-VHD.ps1)

2. Execute the script (bypass SmartScreen filter, accept UAC prompts, etc.)

3. In the simplest form, press *Enter* four times, then set a password - a default encrypted VHD container will be created as follows:

    * **VHD File Name:** *username*_private.vhd
    * **Location:** C:\Users\ *username* \Desktop
    * **Size:** 1024 MB (1 GB)
    * **Drive letter:** Y:

4. Alternatively:
    * Specify options interactively for VHD filename, location (path), size, and drive letter - when prompted, set a password for the encrypted container

    ![Screenshot of Create-Encrypted-VHD.ps1 with manually specifie options](https://blog.neilsabol.site/images/create-encrypted-VHD-screenshot-with-options.png)

    * Run the script non-interactively using the supported parameters (vhdName, vhdPath, vhdSize, vhdLetter, vhdCredential, confirmscriptcreation)

            $myPassword = ("Abcd-1234" | ConvertTo-SecureString -AsPlainText -Force)
            .\Create-Encrypted-VHD.ps1 -vhdName "MySecureContainer" -vhdPath C:\Users\Baymax" -vhdSize "256" -vhdLetter "X:" -vhdCredential $myPassword -confirmscriptcreation "y"

If the *script creation* option is "y", Create-Encrypted-VHD.ps1 generates mount/unmount "shortcut" scripts on the user's Desktop. Once mounted, the user must enter the Bit Locker password to access the container.


## Notes
The script places 2 *.ps1* files directly on the user's desktop for quick mounting and unmounting of the container (if desired).

The script attempts to use the "best" Bitlocker management mechanism available. The preference is the [BitLocker PowerShell module](https://docs.microsoft.com/en-us/powershell/module/bitlocker/?view=win10-ps), but if that is unavailable, it falls back to the [manage-bde command](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/manage-bde). The advantage of the PowerShell module is the ability to use the *vhdCredential* parameter - *manage-bde* does not support that.

If the script aborts after the user selects a password (example: the password does not meet the minimum requirements), an orphaned, unencrypted VHD may be left mounted. The script attempts to clean that up but if it fails, you may need to do the following:

1. Launch Computer Management (right-click Start menu, select `Computer Management`)

2. Open `Disk Management`, under `Storage`

3. Right-click the VHD disk and select `Detach`

4. Once detached, delete the .vhd file


If the script does not execute on your computer, you may need to relax your execution policy. Launch a PowerShell prompt and enter the following:

```
Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted
```

Alternatively, you can run `Create-Encrypted-VHD.ps1` as follows (but note, if you do not permanently adjust the execution policy for the user mounting/unmounting the encrypted container, the shortcuts may not work as intended):

```
powershell.exe -executionpolicy bypass -file Create-Encrypted-VHD.ps1
```


## Integration testing
`Create-Encrypted-VHD.Tests.ps1` contains basic PowerShell [Pester](https://github.com/pester/Pester) tests that I use to validate the functionality of this script as changes are introduced. To run the tests, you will need Pester 5+:

```
Install-Module -Name Pester -Force -SkipPublisherCheck
```

Once installed, the Pester tests can be invoked as follows (Note: these steps must be performed in an elevated/administrator PowerShell session):

```
cd <path-to-bitlocker-encrypted-vhd-from-batch-or-powershell>
invoke-pester -Output Detailed
```

Note, these tests are not mocked - they actually run the script to create an encrypted VHD container, perform basic operations and destroy it once done.
