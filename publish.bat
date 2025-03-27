@echo off
setlocal EnableDelayedExpansion

echo.
echo ===================================================
echo =         Vue3-Datatable Publish Script          =
echo ===================================================
echo.

:: For colored text
set "RED=31"
set "GREEN=32"
set "YELLOW=33"
set "BLUE=34"
set "MAGENTA=35"
set "CYAN=36"
set "WHITE=37"

:: Colored text function
call :colorEcho %YELLOW% "Current version: "

:: Get current version without using jq
for /f "tokens=2 delims=:," %%a in ('findstr /C:"\"version\":" package.json') do (
    set "version=%%a"
    set "version=!version:"=!"
    set "version=!version: =!"
    call :colorEcho %CYAN% "!version!"
)
echo.
echo.

:: Check Git status
echo Checking Git working directory status...
git status --porcelain > git_status.tmp
set /p git_status=<git_status.tmp
del git_status.tmp

if not "!git_status!"=="" (
    call :colorEcho %YELLOW% "WARNING: Git working directory is not clean."
    echo Changes detected:
    git status --short
    echo.
    set /p commitFirst="Do you want to commit these changes first? (y/n, default=y): "
    if "!commitFirst!"=="" set "commitFirst=y"
    
    if /i "!commitFirst!"=="y" (
        set /p commitMsg="Enter commit message (default: 'chore: prepare for version update'): "
        if "!commitMsg!"=="" set "commitMsg=chore: prepare for version update"
        
        git add .
        git commit -m "!commitMsg!"
        
        if !errorlevel! neq 0 (
            call :colorEcho %RED% "Failed to commit changes!"
            exit /b 1
        )
        call :colorEcho %GREEN% "Changes committed successfully."
        echo.
    ) else (
        call :colorEcho %RED% "Please commit your changes manually before running this script."
        exit /b 1
    )
)

:: Ask for version type
echo Select version upgrade type:
call :colorEcho %GREEN% "1) patch [default]"
echo  - 1.7.1 -^> 1.7.2
call :colorEcho %YELLOW% "2) minor"
echo  - 1.7.1 -^> 1.8.0
call :colorEcho %RED% "3) major"
echo  - 1.7.1 -^> 2.0.0
call :colorEcho %BLUE% "4) custom"
echo  - custom version (manual input)
echo.

set /p versionType="Your choice (1-4, default=1): "

if "%versionType%"=="" (
    set "versionType=1"
    set "versionCmd=patch"
    echo Using default: patch
) else if "%versionType%"=="1" (
    set "versionCmd=patch"
) else if "%versionType%"=="2" (
    set "versionCmd=minor"
) else if "%versionType%"=="3" (
    set "versionCmd=major"
) else if "%versionType%"=="4" (
    set /p customVersion="Enter custom version number (e.g. 1.8.0): "
    set "versionCmd=%customVersion%"
) else (
    call :colorEcho %RED% "Invalid selection! Using default: patch"
    set "versionType=1"
    set "versionCmd=patch"
)

echo.
call :colorEcho %YELLOW% "Logging in to NPM..."
echo.
call pnpm login

if %errorlevel% neq 0 (
    call :colorEcho %RED% "NPM login failed!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Upgrading version..."
echo.

if "%versionType%"=="4" (
    call pnpm version %versionCmd% --no-git-tag-version
) else (
    call pnpm version %versionCmd%
)

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Version upgrade failed!"
    exit /b 1
)

:: Get new version without jq
for /f "tokens=2 delims=:," %%a in ('findstr /C:"\"version\":" package.json') do (
    set "newVersion=%%a"
    set "newVersion=!newVersion:"=!"
    set "newVersion=!newVersion: =!"
)

echo.
call :colorEcho %YELLOW% "Building project..."
echo.
call pnpm run build

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Build failed!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Built package contents:"
echo.
dir dist /b

echo.
call :colorEcho %YELLOW% "Creating package preview..."
echo.

:: Create temp directory if it doesn't exist
if not exist temp-pack mkdir temp-pack

call pnpm pack --pack-destination ./temp-pack

echo.
set /p confirmPublish="Do you want to publish the package to NPM? (y/n, default=y): "
if /i "%confirmPublish%"=="" (
    set "confirmPublish=y"
    echo Using default: y
)

if /i not "%confirmPublish%"=="y" (
    call :colorEcho %RED% "Publishing canceled!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Publishing package to NPM..."
echo.
call pnpm publish

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Publishing failed!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Performing Git operations..."
echo.

:: Create git tag for custom version
if "%versionType%"=="4" (
    call git tag v%newVersion%
)

:: Only do git add and commit if there are changes
git status --porcelain > git_status.tmp
set /p git_status=<git_status.tmp
del git_status.tmp

if not "!git_status!"=="" (
    call git add .
    call git commit -m "chore: bump version to v%newVersion%"
)

call git push

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Git push failed!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Pushing Git tags..."
echo.
call git push --tags

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Git tag push failed!"
    exit /b 1
)

echo.
call :colorEcho %GREEN% "========================================"
call :colorEcho %GREEN% "  Package published successfully: v%newVersion%"
call :colorEcho %GREEN% "========================================"
echo.

:: Clean up temporary package files
if exist temp-pack (
    del /q temp-pack\*
    rmdir temp-pack
)

exit /b 0

:colorEcho
:: %~1 color code (e.g. 31=red)
:: %~2 text to write
echo [%~1m%~2[0m
exit /b
