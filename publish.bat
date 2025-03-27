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
for /f "tokens=*" %%i in ('pnpm -s exec jq -r ".version" package.json') do (
    call :colorEcho %CYAN% "%%i"
)
echo.
echo.

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

:: Get new version
for /f "tokens=*" %%i in ('pnpm -s exec jq -r ".version" package.json') do (
    set "newVersion=%%i"
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

call git add .
call git commit -m "chore: bump version to v%newVersion%"
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
