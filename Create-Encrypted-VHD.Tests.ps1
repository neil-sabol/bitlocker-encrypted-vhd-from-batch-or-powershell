# ###############################
# BitLocker encrypted vhd from batch or PowerShell
# https://github.com/neil-sabol/bitlocker-encrypted-vhd-from-batch-or-powershell
# Neil Sabol
# neil.sabol@gmail.com
# ###############################

# Ensure tests are running as admin
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
if (-not $myWindowsPrincipal.IsInRole($adminRole)) {
    write-host ""
    write-host "These tests must be run in an elevated (administrator) PowerShell session."
    write-host "Please re-launch PowerShell as administrator and try again."
    write-host ""
    exit
}

# Ensure the BitLocker PowerShell module is present
if( -not (Get-Module -ListAvailable -Name "BitLocker")) {
    write-host ""
    write-host "These tests require the BitLocker PowerShell module."
    write-host "Please install the module and try again."
    write-host ""
    exit
}

# Capture the path the script and tests reside in
$script:currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Define test parameters
$script:name = "TestContainer"
$script:path = "C:\Temp"
$script:sizeMB = "128"
$script:driveletter = "X:"
$script:cred = ("Abcd-1234" | ConvertTo-SecureString -AsPlainText -Force)
$script:badCred = ("NOTAbcd-1234" | ConvertTo-SecureString -AsPlainText -Force)
$script:createShortcuts = "y"

# Begin tests
Describe 'Create-Encrypted-VHD' {
    BeforeAll {
        # Create the test container path if it does not exist
        If(-Not (Test-Path "$path")) { New-Item -Path "$path" -ItemType "Directory" }
        # Generate the test encrypted container using the test parameters
        . $currentPath\Create-Encrypted-VHD.ps1 -vhdNam $name -vhdPath $path -vhdSize $sizeMB -vhdLetter $driveletter -vhdCredential $cred -confirmscriptcreation $createShortcuts
        # Wait 10 seconds to ensure Bitlocker encryption completes
        sleep 10
    }
    Context "Basic functionality" {
        It "Should create a VHD file in the location specified ($path\$name.vhd)" {
            "$path\$name.vhd" | Should -Exist
        }
        It "Should enable Bitlocker encryption on the mounte VHD file ($driveletter)" {
            Get-BitLockerVolume -MountPoint $driveletter | select -ExpandProperty VolumeStatus | Should -Be "FullyEncrypted"
        }
        It "Should mount the VHD file ($path\$name.vhd) by default to $driveletter" {
            "$driveletter" | Should -Exist
        }
    }
    Context "Input and output" {
        It "Should allow the creation of a text file in the encrypted VHD file" {
            New-Item -Path "$driveletter\" -Name "testfile1.txt" -ItemType "File" -Value "This is a text string."
            Get-Content -Path "$driveletter\testfile1.txt" | Should -Be "This is a text string."
        }
        It "Should allow the creation of a folder in the encrypted VHD file" {
            New-Item -Path "$driveletter\" -Name "testfolder" -ItemType "Directory"
            "$driveletter\testfolder" | Should -Exist
        }
        It "Should allow the creation of a text file in a folder in the encrypted VHD file" {
            New-Item -Path "$driveletter\testfolder\" -Name "testfile2.txt" -ItemType "File" -Value "This is a another text string."
            Get-Content -Path "$driveletter\testfolder\testfile2.txt" | Should -Be "This is a another text string."
        }
    }
    Context "Bitlocker encryption" {
        It "Should allow the VHD to be Bitlocker locked" {
            { Lock-BitLocker -MountPoint "$driveletter" -ForceDismount } | Should -Not -Throw
        }
        It "Should NOT allow access to the VHD contents while it is Bitlocker locked" {
            { Get-Content -Path "$driveletter\testfile1.txt" -ErrorAction Stop } | Should -Throw
        }
        It "Should NOT allow Bitlocker to unlock the VHD with an incorrect password" {
            { Unlock-BitLocker -MountPoint "$driveletter" -Password $badCred -ErrorAction Stop } | Should -Throw
        }
        It "Should allow Bitlocker to unlock the VHD with the correct password" {
            { Unlock-BitLocker -MountPoint "$driveletter" -Password $cred -ErrorAction Stop } | Should -Not -Throw
        }
    }
    Context "Data integrity" {
        It "Should produce the same test file content after locking and unlocking the VHD" {
            Get-Content -Path "$driveletter\testfile1.txt" | Should -Be "This is a text string."
        }
        It "Should produce the same test folder after locking and unlocking the VHD" {
            "$driveletter\testfolder" | Should -Exist
        }
        It "Should produce the same test file content within a folder after locking and unlocking the VHD" {
            Get-Content -Path "$driveletter\testfolder\testfile2.txt" | Should -Be "This is a another text string."
        }
    }
    Context "Mount and unmount scripts" {
        It "Should create a mount script on the user's desktop" {
            "$env:USERPROFILE\Desktop\MOUNT-$name.ps1" | Should -Exist
        }
        It "Should create an unmount script on the user's desktop" {
            "$env:USERPROFILE\Desktop\UNMOUNT-$name.ps1" | Should -Exist
        }
        It "Should create an unmount script than unmounts the VHD file when called" {
            . $env:USERPROFILE\Desktop\UNMOUNT-$name.ps1
            "$driveletter" | Should -Not -Exist
        }
        It "Should create an mount script than mounts the VHD file when called" {
            . $env:USERPROFILE\Desktop\MOUNT-$name.ps1
            Unlock-BitLocker -MountPoint "$driveletter" -Password $cred
            "$driveletter" | Should -Exist
        }
    }
    AfterAll {
        # Clean up - remove all artifacts created by the test
        sleep 2
        Remove-Item -Path "$env:USERPROFILE\Desktop\MOUNT-$name.ps1" -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Item -Path "$env:USERPROFILE\Desktop\UNMOUNT-$name.ps1" -Force -ErrorAction SilentlyContinue | Out-Null
        Dismount-DiskImage -ImagePath "$path\$name.vhd" -ErrorAction SilentlyContinue | Out-Null
        sleep 2
        Remove-Item -Path "$path\$name.vhd" -Force -ErrorAction SilentlyContinue | Out-Null
    }
}