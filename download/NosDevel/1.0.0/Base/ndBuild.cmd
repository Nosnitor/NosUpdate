::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: ndBuild.cmd - NosDevel Build Script
:: Copyright © 2014 Nosnitor, Inc.
::
::  $Rev: 79 $
::  $Author: jsblock $
::  $Date: 2014-05-10 16:30:33 -0700 (Sat, 10 May 2014) $
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS

:: Variables
:: Set Default Values for the script
CALL :Environment.Default

:: Clear out variables in case script did not clean up last run.
CALL :Environment.Initialize

:: Notify user of initialization
CALL :App.Write "Initializing %ndBuildName%..." 4 Init
CALL :Console.UpdateTitle "Initializing"

:: Verify OS Support
CALL :App.Write "Verifying operating system support..." 6 Init
CALL :Environment.CheckOS
IF %ndExit% NEQ 0 GOTO End

:: Read Version
CALL :App.Write "Reading script version..." 6 Init
CALL :App.GetVersion

:: Process command line arguments
CALL :App.Write  "Processing command line arguments..." 6 Init
CALL :Environment.CheckArguments %*
IF %ndExit% NEQ 0 GOTO End

CALL :App.Write "NosDevel Build Script v%ndVersion% - Started" 4 ndBuild
:: Display application logo
IF NOT "%ndNoLogo%"=="True" (
    CALL :App.Write "Writing application logo..." 6 ndBuild
    CALL :Console.UpdateTitle "Initializing"
    ECHO NosDevel Build Script v%ndVersion%
    ECHO Copyright ^(c^) 2014 Nosnitor, Inc.
    ECHO.
)

:: Verify Temp Directory
CALL :App.Write "Creating temporary directory..." 6 Init
CALL :App.CreateTempDir

:: Verify required files present
CALL :App.Write "Checking installation..." 6 Init
CALL :Install.Check
IF %ndExit% NEQ 0 GOTO End

:: Read global configuration
IF EXIST "!ndBuildDir!Global.conf" (
    CALL :App.Write "Reading global configuration..." 6 Init
    CALL :Config.ReadFile "!ndBuildDir!Global.conf"
)

:: Get the width of the console columns
CALL :App.Write "Getting console settings..." 6 Init
CALL :Console.GetColumns

:: Check PauseAfterInit
IF /I "%ndDebugPauseAfterInit%"=="True" (
    CALL :App.Write "Debug-PauseAfterInit set, pausing." 4 ndbuild
    PAUSE
)

:: Verify passed configuration file exists.
IF NOT "%ndConfig%"=="" (
    CALL :Console.UpdateTitle "Processing configuration file"
    CALL :App.Write "Verify configuration file exists: %ndConfig%" 6 ndBuild

    IF NOT EXIST "%ndConfig%" (
        CALL :App.Error "Specified configuration file does not exist." 255 ndBuild 
        GOTO End
    )
    CALL :App.Write "Configuration File: %ndConfig%"
    CALL :File.GetDirectory ndConfigDir "%ndConfig%"
    PUSHD "!ndConfigDir!"
    CALL :App.Write "Working Directory: !ndConfigDir!"
    CALL :App.Write
    CALL :Config.ReadFile "%ndConfig%"
)
If "%ndDoExit%"=="True" GOTO End

SET ndNavTarget=Menu.DisplayMain
SET ndOldTarget=Initialization
:AppStart
CALL :App.Write "Moving from [!ndOldTarget!] to [!ndNavTarget!]" 6 ndBuild
IF "!ndNavTarget!"=="End" GOTO AppEnd
CALL :!ndNavTarget!
GOTO AppStart
:AppEnd

:End
CALL :App.Write "Performing graceful shutdown..." 6 ndBuild
IF /I NOT "%ndDebugKeepTempDir%"=="True" (
:: Remove Temp Directory
CALL :App.Write "Removing temporary directory..." 6 ndBuild
IF EXIST "%ndTempDir%" RD /S /Q "%ndTempDir%"
)
CALL :Environment.Initialize
CALL :App.Write "Exiting with exit code %ndExit%" 5  ndBuild
TITLE %ComSpec%
POPD
ENDLOCAL & EXIT /B %ndExit%
GOTO:EOF







::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Build.AssemblyInfo
:: Builds assembly info from a configuration file.
::
:: Arguments:
::	%1  <AssemblyInfoConfig> The configuration file that contains the assembly
::                           info configuration.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Build.AssemblyInfo <AssemblyInfoConfig>
SET ndNavTarget=%ndOldTarget%
SET ndOldTarget=BuildAssemblyInfo
CALL :Console.UpdateTitle "Building AssemblyInfo"
CALL :App.Write "Processing Build.AssemblyInfo action..." 3 Build.AssemblyInfo

:: Verify configuration file exists
IF NOT EXIST "%~1" CALL :App.Err  "'%~1' does not exist." 255 Build.AssemblyInfo & GOTO:EOF
CALL :App.Write "Using '%~1'." 5 Build.AssemblyInfo

CALL :Config.ReadSetting "%~1" Version-Major ndVerTemp
SET ndVersionShort=!ndVerTemp!
CALL :Config.ReadSetting "%~1" Version-Minor ndVerTemp
SET ndVersionShort=!ndVersionShort!.!ndVerTemp!
CALL :Config.ReadSetting "%~1" Version-Revision ndVerTemp
SET ndVersionShort=!ndVersionShort!.!ndVerTemp!
CALL :Config.ReadSetting "%~1" Version-Build ndVerTemp
SET ndVersion=!ndVersionShort!.!ndVerTemp!
SET ndVerTemp=
CALL :App.Write "Version.conf supplied version as %ndVersion%" 7 Build.AssemblyInfo

ECHO %ndVersion% | find "SvnRev" > NUL 2>&1
IF !ErrorLevel! EQU 0 (

:: Verify tools supported
CALL :Tool.Verify SubWCRev

REM Determine if working copy is latest revision and not modified.
REM TODO Set this path based off something else.
SubWCRev.exe "%~dp0.." -nNm > %ndTempDir%SubWCRev-Version.output 

CALL :App.Write "SubWCRev exited with code !ErrorLevel!" 5 Build.AssemblyInfo
IF !ErrorLevel! EQU 7 CALL :App.Error "Unable to update build version. Working copy has local modifications." 255 Build.AssemblyInfo True & GOTO EndBuildVersion
IF !ErrorLevel! EQU 8 CALL :App.Error "Unable to update build version. Working copy contains mixed versions." 255 Build.AssemblyInfo True & GOTO EndBuildVersion
IF !ErrorLevel! EQU 11 CALL :App.Error "Unable to update build version. Working copy has unversioned items." 255 Build.AssemblyInfo True & GOTO EndBuildVersion
IF !ErrorLevel! NEQ 0 CALL :App.Error "Unable to update build version. Unknown error." 255 Build.AssemblyInfo True & TYPE %ndTempDir%SubWCRev-Version.output & GOTO EndBuildVersion
FOR /F "tokens=4 delims= " %%A IN ('TYPE %ndTempDir%SubWCRev-Version.output ^| find "Updated to revision "') DO CALL :App.Write "Working Copy Revision: %%A" 7 Build.AssemblyInfo & SET ndVersion=!ndVersion:SvnRev=%%A!
)

:EndBuildVersion
IF %ndExit% NEQ 0 ECHO Using "0" for version build. & SET ndVersion=%ndVersion:SvnRev=0%& SET ndExit=0
ECHO Application Version: v!ndVersion!

:: Process AssemblyInfo actions
SET ndLastActionFile=!ndActionFile!
CALL :Config.ReadSetting "%~1" Action-File ndActionFile
IF NOT "!ndLastActionFile!"=="!ndActionFile!" CALL :Action.RunFile "!ndConfigDir!!ndActionFile!"
SET ndActionFile=!ndLastActionFile!
GOTO:EOF

:VersionOutput <OutputFile>
CALL :GetPathFromRelativeFile ndTempVersionOutput "%~1"
CALL :App.Write "Outputting version [%ndVersion%] to file '!ndTempVersionOutput!'" 7 VersionOutput
ECHO %ndVersion%> !ndTempVersionOutput!
SET ndTempVersionOutput=
GOTO:EOF











::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Pause
:: Pauses execution of the script, unless the nopause argument was passed.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Pause
IF /I NOT "%ndNoPause%"=="True" PAUSE
GOTO:EOF



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: InformationLabel
:: Writes debug information to the console.
:: 
:: Arguments:
::  %1 - Message aligned to the left
::  %2 - Message aligned to the right
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:InformationLabel <string1> <string2>
SETLOCAL
SET /A ndUsableSpace=ndConsoleWidth - 1
SET String1=%~1
SET String1Len=
CALL :String.Length String1Len "!String1!"
SET String2=%~2
SET String2Len=
CALL :String.Length String2Len "!String2!"
CALL :PadStringEnd String1 !ndConsoleWidth!
SET /A String1Len=ndUsableSpace - String2Len
CALL SET InformationLabel=%%String1:~0,%String1Len%%%%String2%
ECHO %InformationLabel%
ENDLOCAL
GOTO:EOF


:PadStringEnd
CALL :Char.Repeat ndPadStringTemp " " %~2
SET "%~1=!%~1!!ndPadStringTemp!"
SET "ndPadStringTemp="
GOTO:EOF







:GetPathFromRelativeFile <VariableName> <File>
CALL :App.Write "Using %~dpnx2" 8 GetPathFromRelativeFile
SET %~1=%~dpnx2
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Action.Run
:: Executes an action file.
::
:: Arguments:
::  %1  <ActionFile>         The action file to execute.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Action.Run <ActionFile>
IF "%~1"=="" (
    CALL :App.Error "Action.Run requires actions file parameter." 255 Action.Run
    GOTO:EOF
)
IF NOT EXIST "%~1" (
    CALL :App.Write "Action.Run parameter '%~1' does not exist." 255 Action.Run
    GOTO:EOF
)
(
    CALL :Console.UpdateTitle "Running Action File: %~1" 
    SET ndLastActionFile=!ndActionFile!
    SET ndActionFile=%~1
    CALL :Action.RunFile "%~1"
    SET ndActionFile=!ndLastActionFile!
)
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Action.RunFile
:: Runs an action file.
::
:: Arguments:
::  %1  <ActionFile>     A CSV file defining actions.
::  %%i <Action>         The action to perform.
::  %%j <ActionParam>    The actions parameters.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Action.RunFile <ActionFile>
CALL :App.Write "Running Actions File: %~1" 4 Action.RunFile
FOR /F "tokens=1,2,3,4 delims=," %%i in ('TYPE "%~1"') DO (
    SET ndAction=%%i
    SET ndActionParam=%%j
    SET ndActionValid=False
    CALL :App.Write "%~nx1 Action: %%i [Parameter: %%j]" 5 Action.RunFile
    CALL :Console.UpdateTitle "Running Action %%i"
    IF /I "%%i"=="Action.Run" (
        CALL :Action.Run "%%j"
        SET ndActionValid=True
    )    
    IF /I "%%i"=="App.Write" (
        CALL :App.Write "%%k" "%%j"
        SET ndActionValid=True
    )    
    IF /I "%%i"=="Build.AssemblyInfo" (
        CALL :Build.AssemblyInfo "%%j"
        SET ndActionValid=True
    )
    IF /I "%%i"=="Dir.Create" (
        IF EXIST "%%j" CALL :App.Write "Directory Exists: %%j" 7
        IF NOT EXIST "%%j" (
        CALL :App.Write "Creating directory: %%j" 7
        MD "%%j"
        )
        SET ndActionValid=True
    )
    IF /I "%%i"=="Dir.Remove" (
        IF EXIST "%%j" (
            CALL :App.Write "Removing directory: %%j" 8
            RD /S /Q "%%j"
        ) ELSE (
            CALL :App.Write "Directory does not exist: %%j" 8
        )
        SET ndActionValid=True
    )
    IF /I "%%i"=="Exit" (
        IF NOT "!ndDoExit!"=="True" (
            CALL :App.Write "Exiting with error level %%j" 3
            SET ndExit=%%j
            SET ndDoExit=True
        )
        SET ndActionValid=True
    )    
    IF /I "%%i"=="File.Copy" (
        CALL :Tool.Verify Xcopy
        CALL :App.Write "Copying: %%j to %%k" 8
        CALL :Console.UpdateTitle "Copying file %%j"
        IF NOT EXIST "%%~dpk" MD "%%~dpk"
        CALL :File.Touch "%%k"
        !ndToolXcopy! "%%j" "%%k" /I %ndXcopyParams%
        SET ndActionValid=True
    )
    IF /I "%%i"=="File.Touch" (
        CALL :File.Touch "%%j"
        SET ndActionValid=True
    )
    IF /I "%%i"=="Timeout" (
        !ndBuildDir!Bin\Timeout.exe /NoLogo /t %%j
        SET ndActionValid=True
    )
    IF /I "%%i"=="Tool.Find" (
        CALL :Tool.Find "%%j" "%%k" "%%l" True
        SET ndActionValid=True
    )
    IF /I "%%i"=="Tool.Verify" (
        CALL :Tool.Verify "%%j" "True"
        SET ndActionValid=True
        IF NOT 0!ndExit! EQU 0 CALL :App.Error "Tool could not be verified: %%j" 254 Action.RunFile True & SET ndDoExit=True& GOTO:EOF
    )
    IF /I "%%i"=="RunConfig" (
        CALL :Config.ReadFile "%%j"
        SET ndActionValid=True
    )
    IF /I "%%i"=="VersionOutput" (
        CALL :VersionOutput "%%j"
        SET ndActionValid=True
    )

    IF NOT "!ndActionValid!"=="True" CALL :App.Error "%~nx1 Unknown action: %%i" 254
    SET ndActionValid=
    IF NOT 0!ndExit! EQU 0 CALL :App.Error "Unhandled error in action %%i" 254 Action.RunFile True & SET ndDoExit=True
    CALL :App.Write  "Finished with action %%i" 6 Action.RunFile
    IF NOT 0!ndExit! EQU 0 GOTO:EOF
)
GOTO:EOF


:App.CreateTempDir
CALL :App.Write "Creating temporary directory..." 7 App.CreateTempDir
IF EXIST "%ndTempDir%" (
    CALL :App.Write "Directory Exists: %ndTempDir%" 5 App.CreateTempDir
    CALL :App.Write "Deleting files." 5 App.CreateTempDir
    RD /S /Q "%ndTempDir%"
) ELSE (
    CALL :App.Write "Creating Directory: %ndTempDir%" 5 App.CreateTempDir
)
MD "%ndTempDir%"
GOTO:EOF

:: App.Error
:: Error handler/logger/notification for script.
:App.Error <ErrorMessage> <ErrorLevel> <Category> <NoPause>
    CALL :App.Write "%~1" 1 "%~3" "%~4"
    SET ndExit=%~2
GOTO:EOF

:App.GetVersion
IF EXIST "!ndBuildDir!VERSION" (
    SET /P ndVersion=< "!ndBuildDir!VERSION"
    SET ndVersionShort=!ndVersion:~0,5!
) ELSE (
    SET ndVersion=X.X.X.X
)
::TODO: Base off last dot
SET ndVersionShort=%ndVersion:~0,5%
CALL :App.Write "Version !ndVersion!" 7 App.GetVersion
GOTO:EOF

:App.Write <Message> <Level> <Category>
IF "%~2"=="" (
    SET ndTempAppWrite=3
) ELSE (
    SET ndTempAppWrite=%~2
)
CALL :Console.Write "%~1" "!ndTempAppWrite!" "%~3" "%~4"
SET ndTempAppWrite=
GOTO:EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Char.Repeat
:: Repeats a character a specified number of times.
::
:: Arguments:
::  %1  ResultVar       The name of the environment variable that is populated
::                      with the result.
::  %2  Character       The character to repeat.
::  %3  Count           The number of times to repeat <Character>.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Char.Repeat <ResultVar> <Character> <Count>
SET "%~1="
FOR /L %%I IN (1,1,%~3) DO SET "%~1=!%~1!%~2"
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Config.ReadFile
:: Reads standard settings from a .conf file.
::
:: Arguments:
::  %1  <ConfigFile>    The configuration file to read standard settings from.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Config.ReadFile <ConfigFile>
CALL :Config.ReadSetting "%~1" Action-File ndActionFile
CALL :Config.ReadSetting "%~1" Config-Directory ndConfigDir
CALL :Config.ReadSetting "%~1" Debug-Level ndDebug
IF 0!ndDebug! GTR 0 (
CALL :Config.ReadSetting "%~1" Debug-KeepTempDirectory ndDebugKeepTempDir
CALL :Config.ReadSetting "%~1" Debug-PauseAfterInit ndDebugPauseAfterInit
)
CALL :Config.ReadSetting "%~1" Project-Name ndProjectName
CALL :Config.ReadSetting "%~1" Source-Dir ndSourceDir
CALL :Config.ReadSetting "%~1" Xcopy-Params ndXcopyParams
FOR /F "tokens=1,2,3 delims=," %%i in (!ndBuildDir!Res\Tools.csv) DO (
    CALL :Config.ReadSetting "%~1" "Tool-%%i" "ndTool%%i"
)
IF NOT "!ndActionFile!"=="" (
    CALL :Action.RunFile "!ndConfigDir!!ndActionFile!"
)
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Config.ReadSetting
:: Reads a setting from a .conf file.
::
:: Arguments:
::  %1 - The .conf file.
::  %2 - The name of the setting to read.
::  %3 - The variable to hold the settings value.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Config.ReadSetting <ConfigFile> <SettingName> <VariableName>
TYPE "%~1" | FIND "%~2" > "!ndTempDir!ReadSetting.output" 2>&1
IF !ErrorLevel! NEQ 0 GOTO:EOF
SET /P ndReadSettingTemp=< "!ndTempDir!ReadSetting.output"
CALL :String.Length ndLSet "%~2"
CALL :String.Length ndLVar "!ndReadSettingTemp!"
SET /A ndLSet=%ndLSet% + 1
SET /A ndLVar=%ndLVar% - %ndLSet%
SET ndReadSettingTemp=^!ndReadSettingTemp:~%ndLSet%,%ndLVar%^!
SET %~3=!ndReadSettingTemp!
SET ndLSet=
SET ndLVar=
SET ndReadSettingTemp=
CALL :App.Write "Read %~2 setting from '%~1': !%~3!" 7 Config.ReadSetting
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Config.WriteSetting
:: Writes a setting to a .conf file.
::
:: Arguments:
::  %1 - The .conf file.
::  %2 - The name of the setting to write.
::  %3 - The value of the setting.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Config.WriteSetting <ConfigFile> <SettingName> <Value>
CALL :Tool.Verify CScript
CALL :Tool.Verify FindStr
:: Don't write setting if setting exists and value is the same.
ECHO %~3| !ndBuildDir!Lib\REPL.BAT "\\" "\\" > !ndTempDir!%~nx1.tmp
SET /P TestString=<!ndTempDir!%~nx1.tmp
findstr "^%~2=!TestString!$" "%~1" >NUL
IF !ErrorLevel! EQU 0 SET TestString=& GOTO:EOF
SET TestString=
:: Setting needs to be written
findstr "^%~2=.*$" "%~1" >NUL
IF !ErrorLevel! EQU 0 (
:: Replace value
TYPE "%~1" | !ndBuildDir!Lib\REPL.BAT "^%~2=.*$" "%~2=%~3" > !ndTempDir!%~nx1.tmp
MOVE !ndTempDir!%~nx1.tmp "%~1" >NUL
)
:: Create value
IF !ErrorLevel! EQU 1 (
ECHO %~2=%~3>> %~1
)
CALL :App.Write "Wrote %~2 setting to '%~1': %~3" 7 Config.WriteSetting
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Console.GetColumns
:: Populates the ndConsoleWidth variable with the number of columns the
:: console window has.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Console.GetColumns
CALL :Tool.Verify "Mode"
CALL :Tool.Verify "FindStr"
FOR /F "usebackq tokens=2* delims=: " %%W in (`%ndToolMode% con ^| %ndToolFindStr% Columns`) DO SET ndConsoleWidth=%%W
CALL :App.Write "Console is %ndConsoleWidth% characters wide" 7 Console.GetColumns
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Console.ReadInteger
:: Reads an integer input from the console.
::
:: Arguments:
::  %1  <ReturnVar>     The variable to be populated with the return value.
::  %2  <SettingName>   The name of the setting that is being read.
::  %3  <MinValue>      The minimum value for the integer.
::  %4  <MaxValue>      The maximum value for the integer.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Console.ReadInteger <ReturnVar> <SettingName> <MinValue> <MaxValue>
SET ndReadInt=
SET /P ndReadInt=%~2 [%~3 to %~4, Enter: !%~1!]: 
IF "!ndReadInt!"=="" (
    CALL :App.Write "Using current value" 8 Console.ReadInteger
) ELSE (
    SET /A ndTestInt=ndReadInt
    IF !ndTestInt! EQU 0 (
        IF !ndReadInt! NEQ 0 (
            CALL :App.Error "Input must be a number between %~3 and %~4." !ndExit! Console.ReadInteger True
            CALL :Console.ReadInteger "%~1" "%~2" "%~3" "%~4"
            GOTO:EOF
        )
    )
    IF !ndTestInt! GEQ %~3 (
        IF !ndTestInt! LEQ %~4 (
            SET ndDebug=!ndTestInt!
            CALL :App.Write "Successful integer" 8 Console.ReadInteger
        ) ELSE (
            CALL :App.Error "Input must be a number between %~3 and %~4." !ndExit! Console.ReadInteger True
            CALL :Console.ReadInteger "%~1" "%~2" "%~3" "%~4"
            GOTO:EOF
        )
    ) ELSE (
        CALL :App.Error "Input must be a number between %~3 and %~4." !ndExit! Console.ReadInteger True
        CALL :Console.ReadInteger "%~1" "%~2" "%~3" "%~4"
        GOTO:EOF
    )
    SET ndTestInt=
)
SET ndReadInt=
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Console.UpdateTitle
:: Updates the application title in the command window.
::
:: Arguments:
::  %1  <Message>       The message that is written to the console.title
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Console.UpdateTitle <Message>
IF "%ndVersionShort%"=="" (
    SET ndTempUpdateTitle=%ndBuildName% - %~1
) ELSE (
    SET ndTempUpdateTitle=%ndBuildName% v%ndVersionShort% - %~1
)
CALL :App.Write "!ndTempUpdateTitle!" 8 Console.UpdateTitle
TITLE !ndTempUpdateTitle!
SET ndTempUpdateTitle=
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Console.Write
:: Writes a message to the console.
:: 
:: Arguments:
::  %1  <Message>       The message written to the console.
::  %2  <Level>         The debug level for the message.
::  %3  <Category>      The message category.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Console.Write <Message> <Level> <Category>
IF 0%~2 GTR 03 (
    IF 0%~2 LEQ 0!ndDebug! CALL :Console.WriteDebug "%~1" %~2 "%~3"
) ELSE (
    IF 0%~2 EQU 01 CALL :Console.WriteError "%~1" "%~4"
    IF 0%~2 EQU 02 CALL :Console.WriteWarning "%~1" "%~2" "%~4"
    IF 0%~2 EQU 03 CALL :Console.WriteMessage "%~1"
)
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Console.WriteDebug
:: Writes a debug message to the console.
::
:: Arguments:
::  %1  <Message>       The message to write to the console.
::  %2  <Level>         The debug level of the message.
::  %3  <Category>      The message category.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Console.WriteDebug <Message> <Level> <Category>
IF "%~3"=="" (
    ECHO [Debug] [%~2] %~1
) ELSE (
    ECHO [Debug] [%~2] [%~3] %~1
)
GOTO:EOF

:Console.WriteMessage <Message>
IF "%~1"=="" (
    ECHO.
) ELSE (
    ECHO %~1
)
GOTO:EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Console.WriteError
:: Writes an error to the screen.
::
:: Arguments:
::  %1  <ErrorMessage>  The error message written to the console.
::  %2  <NoPause>       If "True" the error will be displayed without a pause.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Console.WriteError <ErrorMessage> <NoPause>
ECHO ERROR: %~1
IF /I NOT "%ndNoPause%"=="True" (
    IF /I NOT "%~2"=="True" PAUSE
)
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Display.Usage
:: Displays script usage information.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Display.Usage
ECHO Runs the NosDevel build script processor.
ECHO.
ECHO ndBuild.cmd [/Config filename][/NoPause]
ECHO.
ECHO   /Config          Reads the configuration from the specified filename.
ECHO      Filename    
ECHO   /NoPause         Does not pause execution of the script, for example
ECHO                    when an error occurs.
ECHO   /NoLogo          Does not display the application logo when executing.
    
GOTO:EOF




:Environment.Check
SET ndNavTarget=%ndOldTarget%
SET ndOldTarget=Environment.Check
CALL :Environment.Reset & SET ndNavTarget=%ndNavTarget%& SET ndOldTarget=Environment.Check
CALL :App.Write "Checking Environment..." 5 Environment.Check
CALL :Environment.CheckOS True
FOR /F "tokens=1,2,3 delims=," %%i in (!ndBuildDir!Res\Tools.csv) DO (
CALL :Tool.Find "%%i" "%%j" "%%k" True
)
%~dp0Bin\Timeout.exe /T 3 /Q
GOTO:EOF

:Environment.CheckArgument.Config
IF "%~2"=="" (
    CALL :App.Error "/Config parameter passed with no arguments. A file name is expected." 133 Environment.CheckArguments True
    SHIFT /1
    GOTO:EOF
)
SET ndConfig=%~2
SHIFT /1
SHIFT /1
CALL :App.Write "/Config %~2 command line argument processed." 7 Environment.CheckArguments
GOTO:EOF


:Environment.CheckArguments
IF "%~1"=="" GOTO Environment.CheckArgumentsDone
SET CurArg=%~1
IF /I "%CurArg%"=="/?" CALL :Display.Usage & EXIT /B 0
IF /I "%CurArg%"=="-?" CALL :Display.Usage & EXIT /B 0
IF /I "%CurArg%"=="/NoPause" SET ndNoPause=True& SHIFT /1 & CALL :App.Write "/NoPause command line argument processed." 7 Environment.CheckArguments & GOTO Environment.CheckArguments
IF /I "%CurArg%"=="-NoPause" SET ndNoPause=True& SHIFT /1 & CALL :App.Write "-NoPause command line argument processed." 7 Environment.CheckArguments & GOTO Environment.CheckArguments
IF /I "%CurArg%"=="/NoLogo" SET ndNoLogo=True& SHIFT /1 & CALL :App.Write "/NoLogo command line argument processed." 7 Environment.CheckArguments & GOTO Environment.CheckArguments
IF /I "%CurArg%"=="-NoLogo" SET ndNoLogo=True& SHIFT /1 & CALL :App.Write "-NoLogo command line argument processed." 7 Environment.CheckArguments & GOTO Environment.CheckArguments
IF /I "%CurArg%"=="/Config" (
    CALL :Environment.CheckArgument.Config "%~1" "%~2"
    IF 0%ndExit% EQU 0 (
        SHIFT /1
        SHIFT /1
    ) ELSE (
        SHIFT /1
    )
    GOTO Environment.CheckArguments
)
IF /I "%CurArg%"=="-Config" (
    CALL :Environment.CheckArgument.Config "%~1" "%~2"
    IF 0%ndExit% EQU 0 (
        SHIFT /1
        SHIFT /1
    ) ELSE (
        SHIFT /1
    )
    GOTO Environment.CheckArguments
)
IF NOT "%CurArg%"=="" CALL :App.Error "Unknown argument '%CurArg%'" 255 Environment.CheckArguments False & ECHO Type "%~nx0" /? for usage. & CALL :Pause & GOTO End
:Environment.CheckArgumentsDone
CALL :App.Write "Arguments checked." 7 Environment.CheckArguments
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Environment.CheckOS
:: Checks the environment's operating system.
::
:: Arguments:
::  %1  <WriteConsole>  If True will write results to console.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Environment.CheckOS <WriteConsole>
IF NOT "%ndOsVer%"=="" (
    IF NOT "%ndOsVer%"=="Unknown" (
        GOTO:EOF
    )
)
CALL :App.Write "Checking operating system" 7 Environment.CheckOS
SET ndOsVer=Unknown

:: Windows 7
:: TODO Verify Findstr or find alternative
VER | findstr /i "6\.1\." > NUL 2>&1
IF %ErrorLevel% EQU 0 (
IF "%~1"=="True" (
CALL :InformationLabel "  Operating System: Windows 7" [OK]
)
SET ndOsVer=Windows 7
GOTO Environment.CheckOSDetected
)

:Environment.CheckOSDetected
CALL :App.Write "Operating System: %ndOsVer%" 5 Environment.CheckOS
IF "%ndOsVer%"=="Unknown" (
    IF "%~1"=="True" (
        CALL :InformationLabel "  Operating System: Unknown" [ERROR]
    )
    CALL :App.Error "Unsupported operating system." 255 Environment.CheckOS
)
GOTO:EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Environment.Default
:: Sets the default environment values.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Environment.Default
SET ndDebug=9
CALL :App.Write "ndDebug=!ndDebug!" 6 Init
SET ndBuildName=ndBuild
CALL :App.Write "ndBuildName=!ndBuildName!" 6 Init
SET ndBuildDir=%~dp0
CALL :App.Write "ndBuildDir=!ndBuildDir!" 6 Init
SET ndTempDir=%~dp0Temp\
CALL :App.Write "ndTempDir=!ndTempDir!" 6 Init
SET ndTempMenu=!ndTempDir!Menu.csv
CALL :App.Write "ndTempMenu=!ndTempMenu!" 6 Init
SET ndExit=0
CALL :App.Write "ndExit=!ndExit!" 6 Init
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Environment.Initialize
:: Initializes environment variables to reset data from a previous partial
:: run.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Environment.Initialize
SET ndAction=
SET ndActionFile=
SET ndActionParam=
SET ndActionValid=
SET ndConfig=
SET ndConfigDir=
SET ndDebugKeepTempDir=
SET ndDebugPauseAfterInit=
SET ndDoExit=
SET ndExitNotified=
SET ndLastActionFile=
SET ndNavTarget=
SET ndNoPause=
SET ndNoLogo=
SET ndOldTarget=
SET ndOsVer=
SET ndProjectName=
SET ndSourceDir=
SET ndToolsAvailable=
SET ndToolsUnavailable=
SET ndVersion=
SET ndVersionShort=
FOR /F "tokens=1,2,3 delims=," %%i in (!ndBuildDir!Res\Tools.csv) DO (
    SET ndTool%%i=
)
GOTO:EOF


:Environment.Reset
CALL :App.Write "Resetting Environment..." 5 Environment.Reset
CALL :Environment.Initialize & SET ndOldTarget=%ndOldTarget%
CALL :App.GetVersion
SET ndNavTarget=%ndOldTarget%
SET ndOldTarget=Environment.Reset

SET ndOsVer=Unknown

GOTO:EOF


:Environment.View
ECHO %ndBuildName% Environment Variables:
ECHO.
SET nd
PAUSE
SET ndNavTarget=%ndOldTarget%
SET ndOldTarget=Environment.View
GOTO:EOF

:Environment.ViewAll
ECHO Environment Variables:
ECHO.
SET
PAUSE
SET ndNavTarget=%ndOldTarget%
SET ndOldTarget=Environment.ViewAll
GOTO:EOF
:Execute.Shell
CALL :Console.UpdateTitle "Command Shell (%ComSpec%)"
SET ndNavTarget=%ndOldTarget%
SET ndOldTarget=Shell
ECHO Launching command shell...
ECHO Use the 'exit' command to return to %ndBuildName%
ECHO.
%ComSpec% /K
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: File.GetDirectory
:: Poplates <ResultVar> with the directory of a given filename <Path>.
::
:: Arguments:
::  %1  <ResultVar>   The name of the variable to be populated with the 
::                       value.
::  %2  <Path>           The path to the file.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:File.GetDirectory <ResultVar> <Path>
CALL :App.Write "Using directory: %~dp2" 7 File.GetDirectory
SET %~1=%~dp2
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: File.Touch
:: Changes a file time stamp. Creates the file if it does not exist.
::
:: Arguments:
::  %1  <Filename>      The file to touch. File will be created if it does not
::                      exist.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:File.Touch <Filename>
SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT EXIST "%~1" (
    CALL :App.Write "Creating file %~1" 8 File.Touch
    TYPE NUL >>"%~1"
    GOTO:EOF
) ELSE (
CALL :App.Write "Updating file datetime %~1" 8 File.Touch
SET a=%~a1
IF "!a!"=="" SET a=NONE
PUSHD "%~dp1"
IF "%a%"=="%a:r=%" ^(copy "%~nx1"+,, > NUL ^) ELSE attrib -r "%~nx1"  > NUL & copy "%~nx1"+,,  > NUL & attrib +r "%~nx1" > NUL
POPD
SET a=
)
(
    ENDLOCAL
)
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Install.Check
:: Checks that the installation includes all required files.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Install.Check
CALL :App.Write "Checking installation..." 7 Install.Check
CALL :Install.CheckFile "!ndBuildDir!Bin\Timeout.exe"
IF !ndExit! NEQ 0 GOTO :Install.Check-Error
CALL :Install.CheckFile "!ndBuildDir!Res\Tools.csv"
IF !ndExit! NEQ 0 GOTO :Install.Check-Error
:Install.Check-Complete
CALL :App.Write "Installation check complete." 7 Install.Check
GOTO:EOF
:Install.Check-Error
CALL :App.Error "Error was encountered. {!ndExit!}" 255
GOTO:EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Install.CheckFile
:: Checks that the required installation file exists.
::
:: Arguments:
::  %1  <Filename>  The file to check.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Install.CheckFile <Filename>
CALL :App.Write "Checking %~1" 7 Install.CheckFile
IF NOT EXIST "%~1" (
    CALL :App.Error "The !ndBuildName! installation is corrupt or incomplete. ^(%~nx1^)" 100 Install.CheckFile
)
GOTO:EOF


:Menu.DisplayDebugParam
CALL :Console.UpdateTitle "Environment Menu"
SET ndOldTarget=Menu.DisplayDebugParam
CLS
CALL :Menu.DrawMessage
CALL :Menu.DrawHeader "Debug Parameters"
CALL :Menu.WriteItemToFile "!ndTempMenu!" " " "" ""  True 
CALL :Menu.WriteItemToFile "!ndTempMenu!" "1" "Debug Level: !ndDebug!" "MenuChoice.DebugLevel" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" " " "" ""  False
CALL :Menu.WriteItemToFile "!ndTempMenu!" "R" "Return to Previous Menu" "Menu.DisplayMain" False
CALL :Menu.DrawMenu "!ndTempMenu!"
GOTO:EOF

:Menu.DisplayEnvironment
CALL :Console.UpdateTitle "Environment Menu"
SET ndOldTarget=Menu.DisplayEnvironment
CLS
CALL :Menu.DrawMessage
CALL :Menu.DrawHeader "Environment Menu"
CALL :Menu.WriteItemToFile "!ndTempMenu!" " " "" ""  True 
CALL :Menu.WriteItemToFile "!ndTempMenu!" "1" "View %ndBuildName% Environment Variables" "Environment.View" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" "2" "View All Environment Variables" "Environment.ViewAll" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" "3" "Check Environment" "Environment.Check" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" "4" "Reset Environment" "Environment.Reset" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" " " "" ""  False 
CALL :Menu.WriteItemToFile "!ndTempMenu!" "R" "Return to Previous Menu" "Menu.DisplayMain" False
CALL :Menu.DrawMenu "!ndTempMenu!"
GOTO:EOF


:Menu.DisplayMain
CALL :Console.UpdateTitle "Main Menu"
SET ndOldTarget=Menu.DisplayMain
IF NOT "%ndDebug%"=="" (
    CALL :App.Write "Displaying Main Menu..." 7 Menu.DisplayMain
    CALL :App.Write "Waiting for 2 seconds..." 4 Menu.DisplayMain
    IF 3 LEQ %ndDebug% %~dp0Bin\Timeout.exe /T 2 /Q
)
CLS
CALL :Menu.DrawMessage
CALL :Menu.DrawHeader "Main Menu"
CALL :Menu.WriteItemToFile "!ndTempMenu!" " " "" ""  True 
CALL :Menu.WriteItemToFile "!ndTempMenu!" "1" "Check Environment" "Menu.DisplayEnvironment" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" " " "" ""  False 
CALL :Menu.WriteItemToFile "!ndTempMenu!" "C" "Clear Unhandled Exception" "" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" "D" "Debug Parameters" "Menu.DisplayDebugParam" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" "S" "Launch Shell" "Execute.Shell" False
CALL :Menu.WriteItemToFile "!ndTempMenu!" "Q" "Quit Application" "End" False
CALL :Menu.DrawMenu "!ndTempMenu!"
GOTO:EOF


:Menu.DrawHeader
CALL :InformationLabel "NosDevel Build Script" "v%ndVersion%"
SET /a ndDrawMenuHeaderLen=ndConsoleWidth - 1
CALL :Char.Repeat ndDrawMenuHeaderTemp "*" !ndDrawMenuHeaderLen!
CALL :String.Length ndDrawMenuTextLen "%~1"
SET /a ndDrawMenuTxtStartPos=(ndDrawMenuHeaderLen/ 2) - (ndDrawMenuTextLen / 2) - 1
SET /A ndDrawMenuAppendCount=ndDrawMenuHeaderLen - ndDrawMenuTxtStartPos - ndDrawMenuTextLen - 2
CALL :Char.Repeat ndMenuHeader " " !ndDrawMenuTxtStartPos!
CALL :Char.Repeat ndMenuHeaderAppend " " !ndDrawMenuAppendCount!
SET ndMenuHeader=*!ndMenuHeader!%~1!ndMenuHeaderAppend!*
ECHO !ndDrawMenuHeaderTemp!
ECHO !ndMenuHeader!
ECHO !ndDrawMenuHeaderTemp!
SET ndDrawMenuHeaderTemp=
SET ndDrawMenuHeaderLen=
SET ndDrawMenuTxtStartPos=
SET ndMenuHeader=
GOTO:EOF

:Menu.DrawMenu <MenuFile>
CALL :App.Write "Drawing menu from file %~1" 9 Menu.DrawMenu
SET ndMenuOptions=
FOR /F "tokens=1,2,3 delims=," %%i in ('TYPE "%~1"') DO (
    IF NOT "%%i"==" " (
        ECHO   %%i^) %%j
        SET ndMenuOptions=!ndMenuOptions!%%i
    ) ELSE (
        ECHO.
    )
)
CALL :Tool.Verify "Choice"
ECHO.
IF NOT "!ndMenuOptions!" == "" (
    CHOICE.EXE /C !ndMenuOptions! /M Selection
    IF !ErrorLevel! EQU 255 CALL :App.Error "Error with menu selection." 255 Menu.DrawMenu
    IF !ErrorLevel! EQU 0 CALL :App.Write "Selection canceled." 9 Menu.DrawMenu
    SET /A ndMenuChoicePos=!ErrorLevel! - 1
    ECHO !ndMenuChoicePos!
    SET ndMenuChoice=%%ndMenuOptions:~!ndMenuChoicePos!,1%%
    FOR /F "tokens=1,2,3 delims=," %%i in ('TYPE "%~1" ^| FIND "!ndMenuChoice!,"') DO (
        IF NOT "%%i"=="" (
            IF NOT "%%k"=="" (
                SET ndOldTarget=!ndNavTarget!
                SET ndNavTarget=%%k
            ) ELSE (
                CALL :App.Write "Menu selection has no target." 9 Menu.DrawMenu
            )
        )
    )
)
CLS
SET ndMenuOptions=
SET ndMenuChoice=
GOTO:EOF

:Menu.DrawMessage
IF %ndExit% NEQ 0 (
ECHO Unhandled expection occurred. ^(ndExit %ndExit%^)
)
GOTO:EOF

:Menu.WriteItemToFile <MenuFile> <ItemKey> <ItemDescription> <ItemLabel> <CreateNewFile>
IF "%~5"=="True" CALL :App.Write "Creating file %~1" 9 Menu.WriteItemToFile
IF "%~2"==" " (
    CALL :App.Write "Adding blank line to file %~1" 9 Menu.WriteItemToFile
) ELSE (
    CALL :App.Write "Writing [%~2] %~3, which executes %~4 to file %~1" 9 Menu.WriteItemToFile
)
IF "%~5"=="True" (
    ECHO %~2,%~3,%~4> "%~1"
) ELSE (
    ECHO %~2,%~3,%~4>> "%~1"
)
GOTO:EOF

:MenuChoice.DebugLevel
CALL :Console.ReadInteger ndDebug "DebugLevel" 0 9
CALL :App.Write "[MenuChoice.DebugLevel] DebugLevel set to !ndDebug!" 9 MenuChoice.DebugLevel
SET ndNavTarget=!ndOldTarget!
SET ndOldTarget=MenuChoice.DebugLevel
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: String.Length
:: Determines the length of a string.
:: 
:: Arguments:
::  %1  <ResultVar>         The variable to place the result.
::  %2  <String>            The variable of the string to determine length of.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:String.Length <ResultVar> <String>
(   
    SETLOCAL ENABLEDELAYEDEXPANSION
    SET "s=%~2#"
    SET "l=0"
    FOR %%P IN (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) DO (
        IF "!s:~%%P,1!" NEQ "" ( 
            SET /A "l+=%%P"
            SET "s=!s:~%%P!"
        )
    )
)
( 
    ENDLOCAL
    SET "%~1=%l%"
    CALL :App.Write "%~2: %l%" 8 String.Length
    
    EXIT /B
)


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Tool.Find
:: Finds a tool using all available means.
::
:: Arguments:
::  %1  <ToolName>          The name of the tool.
::  %2  <Filename>          The filename of the tool.
::  %3  <FileDescription>   The tools description.
::  %4  <ShowResult>        If True - Will show the result of the search.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Tool.Find <ToolName> <Filename> <FileDescription> <ShowResult>
:: Verify tool has not already been marked available
ECHO %ndToolsAvailable% | find "%~1" > NUL 2>&1
IF !ErrorLevel! EQU 0 GOTO:EOF
:: Check if tool location has been saved to configuration
IF DEFINED ndTool%~1 (
    IF EXIST "!ndTool%~1!" (
        CALL :App.Write "Found %~1: !ndTool%~1! ^(via Config^)" 7 Tool.Find
        SET ndToolsAvailable=%~1 %ndToolsAvailable%
        GOTO :Tool.Found
    ) ELSE (
        ::TODO - Remove Setting from file instead of just emptying it
        CALL :Config.WriteSetting "!ndBuildDir!Global.conf" "Tool-%~1" ""
    )
)
CALL :Tool.FindInKnownLocations "%~1" "%~2" "%~3"
IF 0!ndExit! EQU 00 GOTO :Tool.Found
SET ndExit=0
CALL :Tool.FindInPath "%~1" "%~2" "%~3"
IF 0!ndExit! EQU 00 GOTO :Tool.Found
SET ndExit=0
CALL :Tool.FindInFilesystem "%~1" "%~2" "%~3"
IF 0!ndExit! EQU 00 GOTO :Tool.Found
SET ndExit=0
GOTO :Tool.NotFound
:Tool.Found
IF "%~4"=="True" (
    CALL :InformationLabel "  %~3: %~2" [OK]
)
CALL :Config.WriteSetting "!ndBuildDir!Global.conf" "Tool-%~1" "!ndTool%~1!"
GOTO:EOF
:Tool.NotFound
IF "%~4"=="True" (
CALL :InformationLabel "  %~3: Not Found" [WARNING]
)
GOTO:EOF



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Tool.FindInFilesystem
:: Finds a tool in the file system.
::
:: Arguments:
::  %1  <ToolName>          The name of the tool.
::  %2  <Filename>          The filename of the tool.
::  %3  <FileDescription>   The tools description.
::  %4  <ShowResult>        If True - Will show the result of the search.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Tool.FindInFilesystem <ToolName> <Filename> <FileDescription> <ShowResult>
ECHO %ndToolsAvailable% | find "%~1" > NUL 2>&1
IF %ErrorLevel% EQU 0 GOTO:EOF
CALL :App.Write "Searching for tool: %~1" 7 Tool.FindInFilesystem
PUSHD C:\
CALL :Console.UpdateTitle "Searching C:\ for %~1"
DIR "%~2" /B /S >"!ndTempDir!Directory.csv" 2>&1
FOR /F "tokens=*" %%i in ('TYPE "!ndTempDir!Directory.csv"') DO IF NOT "%%i"=="File Not Found" SET p=%%~dpnxi
POPD
if not defined p (
    IF NOT "%~d0"=="C:" (
        CALL :Console.UpdateTitle "Searching %~d0\ for %~1"
        PUSHD %~d0\
        dir "%~2" /B /S >"!ndTempDir!Directory.csv" 2>&1
        FOR /F "tokens=*" %%i in ('TYPE "!ndTempDir!Directory.csv"') DO IF NOT "%%i"=="File Not Found" SET p=%%~dpnxi
        IF "!p!"=="File Not Found" SET p=
        POPD
    )
)
if defined p (
    SET ndTool%~1=!p!
    CALL :App.Write "Found %~1: !ndTool%~1!" 7 Tool.FindInFilesystem
    IF "%~4"=="True" (
        CALL :InformationLabel "  %~3: %~2" [OK]
    )
    SET ndToolsAvailable=%~1 %ndToolsAvailable%
) ELSE (
IF "%~4"=="True" (
CALL :InformationLabel "  %~3: Not Found" [WARNING]
)
SET ndToolsUnavailable=%~1 %ndToolsUnavailable%
CALL :App.Write "%~1 was not found in the filesystem." 9 Tool.FindInFilesystem
SET ndExit=1
)
SET p=
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Tool.FindInKnownLocations
:: Finds a tool in known locations. Known locations are kept in .csv files
:: under Res\Tools\Toolname-KnownLocations.csv
::
:: Arguments:
::  %1  <ToolName>          The name of the tool.
::  %2  <Filename>          The filename of the tool.
::  %3  <FileDescription>   The tools description.
::  %4  <ShowResult>        If True - Will show the result of the search.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Tool.FindInKnownLocations <ToolName> <Filename> <FileDescription> <ShowResult>
ECHO %ndToolsAvailable% | find "%~1" > NUL 2>&1
IF %ErrorLevel% EQU 0 GOTO:EOF
IF EXIST "!ndBuildDir!Res\Tools\%~1-KnownLocations.csv" (
    CALL :App.Write "Searching for tool: %~1" 7 Tool.FindInKnownLocations
    FOR /F "tokens=1,2,3 delims=," %%i in ('TYPE !ndBuildDir!Res\Tools\%~1-KnownLocations.csv') DO (
        ECHO %%i| !ndBuildDir!Lib\REPL.BAT "%systemroot%" "%SystemRoot%"> !ndTempDir!Repl.tmp
        SET /P ndToolFilename=<!ndTempDir!Repl.tmp
        IF EXIST "!ndToolFilename!" (
            SET ndTool%~1=%%i
            CALL App.Write "Found %~1: !ndTool%~1!" 7 Tool.FindInKnownLocations
            SET ndToolFilename=
            GOTO:EOF
        )
        SET ndToolFilename=
    )
    SET ndExit=1

) ELSE (
    CALL :App.Write "%~1-KnownLocations.csv was not found." 7 Tool.FindInKnownLocations
    SET ndExit=1
)
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Tool.FindInPath
:: Finds a tool in the current path using the WHERE command.
::
:: Arguments:
::  %1  <ToolName>          The name of the tool.
::  %2  <Filename>          The filename of the tool.
::  %3  <FileDescription>   The tools description.
::  %4  <ShowResult>        If True - Will show the result of the search.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Tool.FindInPath <ToolName> <Filename> <FileDescription> <ShowResult>
:: Do not search if tool is available
ECHO %ndToolsAvailable% | find "%~1" > NUL 2>&1
IF %ErrorLevel% EQU 0 GOTO:EOF
::Search path for tool
CALL :App.Write "Searching for tool: %~1" 7 Tool.FindInPath
WHERE "%~2" > "!ndTempDir!%~1.output" 2>&1
IF %ErrorLevel% EQU 0 (
    SET /P ndTool%~1=<"!ndTempDir!%~1.output"
    CALL :App.Write "Found %~1: !ndTool%~1!" 7 Tool.FindInPath
    IF "%~4"=="True" (
        CALL :InformationLabel "  %~3: %~2" [OK]
    )
    SET ndToolsAvailable=%~1 %ndToolsAvailable%
) ELSE (
    IF "%~4"=="True" (
        CALL :InformationLabel "  %~3: Not Found" [WARNING]
    )
    SET ndToolsUnavailable=%~1 %ndToolsUnavailable%
    CALL :App.Write "%~1 was not found in path." 7 Tool.FindInPath
    SET ndExit=1
)
GOTO:EOF


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Tool.Verify
:: Verifies that required tools are available.
::
:: Arguments:
::  %1  <ToolName>          The name of the tool to verify.
::  %2  <ShowResult>        Show the result in a search is necessary.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Tool.Verify <ToolName> <ShowResult>
ECHO !ndToolsAvailable! | find "%~1" > NUL 2>&1
SET ndTempReturn=!ErrorLevel!
CALL :App.Write "%~1: Supported tool check returned !ndTempReturn!" 8 Tool.Verify
IF !ndTempReturn! EQU 0 SET ndTempReturn=& GOTO:EOF
ECHO !ndToolsUnavailable! | find "%~1" > NUL 2>&1
SET ndTempReturn=!ErrorLevel!
CALL :App.Write "%~1: Unsupported tool check returned !ndTempReturn!" 8 Tool.Verify
IF !ndTempReturn! EQU 0 CALL :App.Error "%~1 support not available." 255 Tool.Verify & SET ndTempReturn=& GOTO:EOF
SET ndTempReturn=
FOR /F "tokens=1,2,3 delims=," %%i in ('TYPE "!ndBuildDir!Res\Tools.csv" ^| FIND "%~1"') DO (
    CALL :Tool.Find "%%i" "%%j" "%%k" "%~2"
    SET ndToolSupported=True
)
IF NOT "!ndToolSupported!"=="True" CALL :App.Error "Unsupported tool %~1" 254 Tool.Verify True
SET ndToolSupported=
GOTO:EOF
