@echo off
setlocal EnableDelayedExpansion

cls
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

:: Main execution starts here
goto :main

:colorEcho
    :: %~1 color code (e.g. 31=red)
    :: %~2 text to write
    echo [%~1m%~2[0m
    goto :EOF

:main
    :: Get current version
    call :colorEcho %YELLOW% "Current version: "
    for /f "tokens=2 delims=:," %%a in ('findstr /C:"\"version\":" package.json') do (
        set "version=%%a"
        set "version=!version:"=!"
        set "version=!version: =!"
        call :colorEcho %CYAN% "!version!"
    )
    echo.

    :: Parse version parts (assuming format is x.y.z)
    for /f "tokens=1,2,3 delims=." %%a in ("!version!") do (
        set "major=%%a"
        set "minor=%%b"
        set "patch=%%c"
    )

    :: Increment patch version
    set /a "patch=!patch!+1"
    set "newVersion=!major!.!minor!.!patch!"

    call :colorEcho %GREEN% "Auto-incrementing to version: !newVersion!"
    echo.
    echo.

    :: Check Git working directory status
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

    echo.
    call :colorEcho %YELLOW% "Updating package.json version to !newVersion!..."
    echo.

    :: Create a temporary file for sed-like replacement
    type package.json > package.json.tmp
    set "search=\"version\": \"!version!\""
    set "replace=\"version\": \"!newVersion!\""

    :: Use PowerShell to replace version in package.json
    powershell -Command "(Get-Content package.json.tmp) -replace [regex]::Escape('!search!'), '!replace!' | Set-Content package.json"
    del package.json.tmp

    :: Verify version change
    for /f "tokens=2 delims=:," %%a in ('findstr /C:"\"version\":" package.json') do (
        set "versionAfter=%%a"
        set "versionAfter=!versionAfter:"=!"
        set "versionAfter=!versionAfter: =!"
    )

    if "!versionAfter!" NEQ "!newVersion!" (
        call :colorEcho %RED% "ERROR: Failed to update version in package.json!"
        exit /b 1
    )

    call :colorEcho %GREEN% "Version updated in package.json: !version! -> !newVersion!"
    echo.

    :: Create git tag for the new version
    git tag v!newVersion!

    echo.
    call :colorEcho %YELLOW% "Building project..."
    echo.

    :: Run build steps individually
    call pnpm exec vite build
    if %errorlevel% neq 0 (
        call :colorEcho %RED% "Vite build failed!"
        goto :error_cleanup
    )

    call pnpm exec vue-tsc --emitDeclarationOnly
    if %errorlevel% neq 0 (
        call :colorEcho %RED% "TypeScript declaration generation failed!"
        goto :error_cleanup
    )

    :: Run tailwind build using pnpm run
    call :colorEcho %YELLOW% "Building Tailwind CSS..."
    echo.
    call pnpm run tailwind:build

    if %errorlevel% neq 0 (
        call :colorEcho %RED% "Tailwind CSS build failed!"
        goto :error_cleanup
    )

    call :colorEcho %GREEN% "Build successful!"
    echo.

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

    if %errorlevel% neq 0 (
        call :colorEcho %RED% "Package preview creation failed!"
        goto :error_cleanup
    )

    echo.
    call :colorEcho %GREEN% "Package preview created successfully."
    echo.
    call :colorEcho %YELLOW% "Ready to publish version !newVersion!"
    echo.

    set /p confirmPublish="Do you want to publish the package to NPM? (y/n, default=y): "
    if /i "%confirmPublish%"=="" (
        set "confirmPublish=y"
        echo Using default: y
    )

    if /i not "%confirmPublish%"=="y" (
        call :colorEcho %RED% "Publishing canceled!"
        goto :error_cleanup
    )

    echo.
    call :colorEcho %YELLOW% "Logging in to NPM..."
    echo.
    call pnpm login

    if %errorlevel% neq 0 (
        call :colorEcho %RED% "NPM login failed!"
        goto :error_cleanup
    )

    echo.
    call :colorEcho %YELLOW% "Publishing package to NPM..."
    echo.
    call pnpm publish

    if %errorlevel% neq 0 (
        call :colorEcho %RED% "Publishing failed!"
        goto :error_cleanup
    )

    echo.
    call :colorEcho %YELLOW% "Performing Git operations..."
    echo.

    :: Commit the version change
    git add package.json
    git add dist
    git commit -m "chore: bump version to v!newVersion!"

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
    call :colorEcho %GREEN% "  Package published successfully: v!newVersion!"
    call :colorEcho %GREEN% "========================================"
    echo.

    :: Clean up temporary package files
    if exist temp-pack (
        del /q temp-pack\*
        rmdir temp-pack
    )

    exit /b 0

:error_cleanup
    :: Restore the original version if something failed
    call :colorEcho %YELLOW% "Cleaning up after error..."
    echo.

    :: Use PowerShell to restore original version in package.json
    set "search=\"version\": \"!newVersion!\""
    set "replace=\"version\": \"!version!\""
    powershell -Command "(Get-Content package.json) -replace [regex]::Escape('!search!'), '!replace!' | Set-Content package.json"

    :: Delete the created Git tag
    git tag -d v!newVersion! 2>nul

    call :colorEcho %RED% "Process aborted. Version reverted to !version!"
    exit /b 1
