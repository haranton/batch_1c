@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: dump-extension.bat ^<XML_DIR^> [EXT_NAME] [update]
    echo.
    echo Examples:
    echo   dump-extension.bat "src\cfe\test" "test"
    echo   dump-extension.bat "src\cfe\test" "test" update
    echo   dump-extension.bat "src\cfe\test" update
    exit /b 1
)

if not exist ".1c-devbase.bat" (
    echo Error: .1c-devbase.bat was not found in current directory.
    echo Copy .1c-devbase.bat.example to project root as .1c-devbase.bat.
    exit /b 1
)
call .\.1c-devbase.bat

set "XML_DIR=%~1"
set "EXT_NAME=%~2"
set "UPDATE_ARG=%~3"
set "UPDATE_MODE=0"

if /i "%~2"=="update" (
    set "EXT_NAME="
    set "UPDATE_ARG=update"
)

if "%EXT_NAME%"=="" set "EXT_NAME=%ONEC_EXTENSION_NAME%"
if "%EXT_NAME%"=="" (
    echo Error: extension name is not provided and ONEC_EXTENSION_NAME is not set.
    exit /b 1
)

if /i "%UPDATE_ARG%"=="update" set "UPDATE_MODE=1"

if not "%ONEC_SERVER%"=="" (
    set "IB_PARAMS=/S ""%ONEC_SERVER%\%ONEC_BASE%"""
) else if not "%ONEC_FILEBASE_PATH%"=="" (
    set "IB_PARAMS=/F ""%ONEC_FILEBASE_PATH%"""
) else (
    echo Error: neither ONEC_SERVER nor ONEC_FILEBASE_PATH is set.
    exit /b 1
)

if not defined ONEC_PATH (
    echo Error: ONEC_PATH is not set in .1c-devbase.bat.
    exit /b 1
)

set "AUTH_PARAMS="
if not "%ONEC_USER%"=="" set "AUTH_PARAMS=/N""%ONEC_USER%"""
if not "%ONEC_PASSWORD%"=="" set "AUTH_PARAMS=!AUTH_PARAMS! /P""%ONEC_PASSWORD%"""

set "UPDATE_PARAMS="
if "%UPDATE_MODE%"=="1" set "UPDATE_PARAMS=-update"

echo Dumping extension...
echo   Output: %XML_DIR%
echo   Extension: %EXT_NAME%
if "%UPDATE_MODE%"=="1" (
    echo   Mode: incremental
) else (
    echo   Mode: full
)

"%ONEC_PATH%" DESIGNER !IB_PARAMS! !AUTH_PARAMS! /DisableStartupDialogs /DumpConfigToFiles "%XML_DIR%" -Extension "%EXT_NAME%" !UPDATE_PARAMS!
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo Dump failed with exit code %EXIT_CODE%.
    exit /b %EXIT_CODE%
)

echo Dump finished successfully.
exit /b 0

