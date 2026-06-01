@echo off
setlocal

:: Get the directory of this script
set "REPO_DIR=%~dp0"
cd /d "%REPO_DIR%"

echo ============================================================
echo Neitz Lab - GitHub Repository Setup
echo ============================================================

:: 1. Check for Git
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed! 
    echo Please install it from: https://git-scm.com/downloads
    timeout /t 10
    exit /b 1
)

:: 2. Initialize Git
if not exist ".git" (
    echo Initializing local repository...
    git init
)

:: 3. Add Files
echo Adding files to repository...
git add .
git commit -m "Initial commit of optimized Stage-VSS stimulus pipeline"

echo.
echo ============================================================
echo LOCAL REPOSITORY READY!
echo ============================================================
echo.
echo To finish publishing to GitHub, run these commands:
echo.
echo 1. git remote add origin [YOUR_GITHUB_REPO_URL]
echo 2. git branch -M main
echo 3. git push -u origin main
echo.
echo ============================================================
pause
