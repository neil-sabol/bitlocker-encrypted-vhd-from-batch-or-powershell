@ECHO OFF
REM ###############################
REM Neil Sabol
REM neil.sabol@gmail.com
REM ###############################

REM See http://stackoverflow.com/questions/7044985/how-can-i-auto-elevate-my-batch-file-so-that-it-requests-from-uac-admin-rights
REM This escalation code is GENIUS!
REM Thanks @Matt (http://stackoverflow.com/users/1016343/matt)

:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges ) 

:getPrivileges
if '%1'=='ELEV' (shift & goto gotPrivileges)  

setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs" 
ECHO UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs" 
"%temp%\OEgetPrivileges.vbs" 
exit /B 

:gotPrivileges
setlocal & pushd .

@ECHO ---------------------------------------------------------------------
@ECHO This script helps you create an encrypted container to store sensitive
@ECHO information. You will be prompted to specify a location, name, size,
@ECHO and password for the container. Scripts to mount and unmount
@ECHO the container will be generated automatically and placed on your desktop.
@ECHO.
@ECHO DO NOT CLOSE THIS WINDOW - it will close automatically when the process is
@ECHO is complete.
@ECHO ---------------------------------------------------------------------
@ECHO.
@ECHO.
:SetVHDParameters
SET vhdName=%USERNAME%_private
SET vhdPath=C:\Users\%USERNAME%\Desktop
SET vhdSize=1024
SET vhdLetter=Y:
@ECHO To accept the default options, press enter 4 times, then set a password
@ECHO.
@ECHO.
@ECHO Helpful hints:
@ECHO     *Paths must be fully qualified (H:, C:\Users\yourname\Desktop, etc.)
@ECHO     *You can copy/paste paths from Explorer
@ECHO     *Size must be a number, entered in MB (500, 1024, etc.)
@ECHO     *There are 1024 MB in 1 GB
@ECHO.
@ECHO.
@SET /P vhdName=Encrypted container name? (default is %USERNAME%_private): %=%
@SET /P vhdPath=Location? (default path is C:\Users\%USERNAME%\Desktop ): %=%
@SET /P vhdSize=Size in MB? (default is 1024): %=%
@SET /P vhdLetter=Drive letter? (default is Y: ): %=%
@ECHO.
@ECHO.
@ECHO CREATE VDISK FILE="%vhdPath%\%vhdName%.vhd"  MAXIMUM=%vhdSize% TYPE=expandable > diskpart.txt
@ECHO SELECT VDISK FILE="%vhdPath%\%vhdName%.vhd" >> diskpart.txt
@ECHO ATTACH VDISK >> diskpart.txt
@ECHO CREATE PARTITION PRIMARY >> diskpart.txt
@ECHO FORMAT QUICK FS=NTFS LABEL="%vhdName%" >> diskpart.txt
@ECHO ASSIGN LETTER=%vhdLetter% >> diskpart.txt
@diskpart /s diskpart.txt > nul 2>&1
IF %ERRORLEVEL% NEQ 0 GOTO SetVHDParameters
@del diskpart.txt
:SetBitlockerPassword
@ECHO.
@ECHO ---------------------------------------------------------------------
@ECHO PLEASE NOTE, IF YOU LOSE THE PASSWORD YOU SPECIFY FOR THIS CONTAINER, 
@ECHO YOUR DATA WILL BE UNRECOVERABLE.
@ECHO ---------------------------------------------------------------------
@ECHO.
@manage-bde -on %vhdLetter% -used -Password
IF %ERRORLEVEL% NEQ 0 GOTO SetBitlockerPassword
@ECHO select vdisk file="%vhdPath%\%vhdName%.vhd" > %USERPROFILE%\Desktop\MOUNT-%vhdName%.bat
@ECHO attach vdisk >> %USERPROFILE%\Desktop\MOUNT-%vhdName%.bat
@ECHO diskpart /s %USERPROFILE%\Desktop\MOUNT-%vhdName%.bat >> %USERPROFILE%\Desktop\MOUNT-%vhdName%.bat
@ECHO select vdisk file="%vhdPath%\%vhdName%.vhd" > %USERPROFILE%\Desktop\UMOUNT-%vhdName%.bat
@ECHO detach vdisk >> %USERPROFILE%\Desktop\UMOUNT-%vhdName%.bat
@ECHO diskpart /s %USERPROFILE%\Desktop\UMOUNT-%vhdName%.bat >> %USERPROFILE%\Desktop\UMOUNT-%vhdName%.bat
@ECHO.
@ECHO.
@ECHO Your encrypted container was created! You can use the "MOUNT-%vhdName%"
@ECHO and "UMOUNT-%vhdName%" scripts on your desktop to mount and unmount the
@ECHO container in the future. This script will automatically mount and open
@ECHO the container this time when you press a key.
@ECHO.
@ECHO.
pause
EXPLORER.EXE %vhdLetter%
EXIT
