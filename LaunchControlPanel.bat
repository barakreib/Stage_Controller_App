@echo off
REM =========================================================================
REM  LaunchControlPanel.bat
REM  Launches the Neitz Lab Master Control Panel GUI from the terminal.
REM
REM  PREREQUISITE: You must have a Stage-VSS server already running
REM  in a separate MATLAB instance before using the stimuli.
REM
REM  Usage:  Double-click this file, or run from the command prompt:
REM          LaunchControlPanel.bat
REM =========================================================================

set "PROJECT_DIR=%~dp0"

echo Starting MATLAB and launching Master Control Panel...
echo Project directory: %PROJECT_DIR%
echo.
echo NOTE: Make sure your Stage-VSS server is running in a separate
echo       MATLAB instance before clicking any RUN buttons.
echo.

matlab -nosplash -r "cd('%PROJECT_DIR%'); MasterControlPanel"
