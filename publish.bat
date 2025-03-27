@echo off
setlocal EnableDelayedExpansion

:: =================================================================
:: Vue3-Datatable Automatic Publisher
:: This script will:
::  1. Update the version number (patch)
::  2. Build the project
::  3. Commit changes to git with version number
::  4. Push to remote repository
::  5. Publish to NPM
:: =================================================================

echo -------------------------------------------
echo Publishing New Version to NPM
echo -------------------------------------------

:: Check if git is installed
where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Git is not installed or not in PATH. Please install Git and try again.
    goto :error
)

:: Check if we're in the main branch
git rev-parse --abbrev-ref HEAD > branch.tmp
set /p CURRENT_BRANCH=<branch.tmp
del branch.tmp

if not "%CURRENT_BRANCH%" == "main" (
    if not "%CURRENT_BRANCH%" == "master" (
        echo WARNING: You are not on main/master branch. Current branch: %CURRENT_BRANCH%
        echo Would you like to continue anyway? (y/n)
        set /p CONTINUE=
        if /i not "%CONTINUE%" == "y" goto :end
    )
)

:: Step 1: Check for uncommitted changes
git diff --quiet --exit-code
if %ERRORLEVEL% NEQ 0 (
    echo Uncommitted changes detected.
    echo Automatically committing current changes...
    git add .
    git commit -m "Prepare for new version release"
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to commit changes.
        goto :error
    )
)

:: Step 2: Update version number
echo Updating version number...
node version-bump.mjs
if %ERRORLEVEL% NEQ 0 (
    echo Failed to update version number.
    goto :error
)

:: Get the new version number
echo Getting version number...
for /f "tokens=* usebackq" %%a in (`node -e "import fs from 'fs'; console.log(JSON.parse(fs.readFileSync('./package.json')).version)"`) do (
    set VERSION=%%a
)

:: Step 3: Build the project
echo Building project...
call pnpm build
if %ERRORLEVEL% NEQ 0 (
    echo Build failed. Aborting publish.
    goto :error
)

:: Step 4: Commit changes
echo Committing changes to git...
git add package.json dist
git commit -m "v%VERSION% make setup"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to commit changes.
    goto :error
)

:: Step 5: Push to remote
echo Pushing to remote repository...
git push
if %ERRORLEVEL% NEQ 0 (
    echo Failed to push to remote repository.
    goto :error
)

:: Step 6: Publish to NPM
echo Publishing to NPM...
echo Checking if you're logged in to NPM...
pnpm whoami >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo You need to login to NPM first
    pnpm login
)

echo Publishing package...
pnpm publish --access public --no-git-checks
if %ERRORLEVEL% NEQ 0 (
    echo Failed to publish to NPM.
    goto :error
)

echo -------------------------------------------
echo Successfully published version v%VERSION% to NPM!
echo -------------------------------------------
goto :end

:error
echo -------------------------------------------
echo Error occurred. Publishing failed.
echo -------------------------------------------
exit /b 1

:end
echo Process completed.
pause
