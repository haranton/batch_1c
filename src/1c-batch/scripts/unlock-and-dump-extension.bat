@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Dump extension with RAC-based session unlock and retry
REM
REM Args:
REM   %1 - XML output directory
REM   %2 - extension name
REM   %3 - optional: update
REM
REM Note:
REM   On lock error script tries to terminate Configurator sessions via RAC
REM   and then retries dump once.
REM ============================================================

if "%~2"=="" (
    echo Usage: unlock-and-dump-extension.bat ^<XML_DIR^> ^<EXT_NAME^> [update]
    echo.
    echo Examples:
    echo   unlock-and-dump-extension.bat "out\cfe\test" "test"
    echo   unlock-and-dump-extension.bat "out\cfe\test" "test" update
    exit /b 1
)

if not exist ".1c-devbase.bat" (
    echo Error: .1c-devbase.bat was not found in current directory.
    echo Copy .1c-devbase.bat.example to project root as .1c-devbase.bat
    exit /b 1
)
call .\.1c-devbase.bat

set "XML_DIR=%~1"
set "EXT_NAME=%~2"
set "UPDATE_MODE=0"
if /i "%~3"=="update" set "UPDATE_MODE=1"

if not "%ONEC_SERVER%"=="" (
    set "IB_PARAMS=/S "%ONEC_SERVER%\%ONEC_BASE%""
) else if not "%ONEC_FILEBASE_PATH%"=="" (
    set "IB_PARAMS=/F "%ONEC_FILEBASE_PATH%""
) else (
    echo Error: neither ONEC_SERVER nor ONEC_FILEBASE_PATH is set.
    exit /b 1
)

set "AUTH_PARAMS="
if not "%ONEC_USER%"=="" set "AUTH_PARAMS=/N"%ONEC_USER%""
if not "%ONEC_PASSWORD%"=="" set "AUTH_PARAMS=!AUTH_PARAMS! /P"%ONEC_PASSWORD%""

set "DUMP_PARAMS="
if "%UPDATE_MODE%"=="1" set "DUMP_PARAMS=-update"

set "LOG_FILE=%TEMP%\1c-dump-extension-%RANDOM%%RANDOM%.log"

echo First dump attempt...
echo   output: %XML_DIR%
echo   extension: %EXT_NAME%

call :run_dump
if %ERRORLEVEL% equ 0 (
    echo Dump finished successfully
    if exist "%LOG_FILE%" del /q "%LOG_FILE%" >nul 2>&1
    exit /b 0
)

echo First attempt failed. Trying to terminate Configurator sessions via RAC...
call :close_designer_via_rac
if %ERRORLEVEL% neq 0 (
    echo RAC session termination failed.
    echo Dump failed. Check log:
    echo   %LOG_FILE%
    exit /b 1
)

echo Retry dump after RAC unlock...
call :run_dump
if %ERRORLEVEL% equ 0 (
    echo Dump finished successfully after retry
    if exist "%LOG_FILE%" del /q "%LOG_FILE%" >nul 2>&1
    exit /b 0
)

echo Retry failed. Check log:
echo   %LOG_FILE%
exit /b 1

:run_dump
"%ONEC_PATH%" DESIGNER !IB_PARAMS! !AUTH_PARAMS! /DisableStartupDialogs /DumpConfigToFiles "%XML_DIR%" -Extension "%EXT_NAME%" !DUMP_PARAMS! /Out "%LOG_FILE%"
exit /b %ERRORLEVEL%

:close_designer_via_rac
if "%ONEC_SERVER%"=="" (
    exit /b 1
)

for %%I in ("%ONEC_PATH%") do set "ONEC_BIN=%%~dpI"
set "RAC_PATH=%ONEC_BIN%rac.exe"
if not exist "%RAC_PATH%" (
    exit /b 1
)

set "RAS_ADDR=%ONEC_SERVER%:1545"
if not "%ONEC_RAS%"=="" set "RAS_ADDR=%ONEC_RAS%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0terminate-designer-sessions.ps1" -RacPath "%RAC_PATH%" -Agent "%RAS_ADDR%" -InfobaseName "%ONEC_BASE%"
if %ERRORLEVEL% equ 0 (
    exit /b 0
)

exit /b 1
