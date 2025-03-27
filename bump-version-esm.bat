@echo off
echo Updating version...
node version-bump.mjs
if %ERRORLEVEL% EQU 0 (
  echo.
  echo Version update completed successfully.
  echo Run "pnpm build" to build the new version.
  echo.
) else (
  echo.
  echo Error occurred during version update.
  echo.
)
pause
