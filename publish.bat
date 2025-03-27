@echo off
setlocal EnableDelayedExpansion

echo.
echo ===================================================
echo =         Vue3-Datatable Publish Script          =
echo ===================================================
echo.

:: Renkli metin için
set "RED=31"
set "GREEN=32"
set "YELLOW=33"
set "BLUE=34"
set "MAGENTA=35"
set "CYAN=36"
set "WHITE=37"

:: Renkli metin fonksiyonu
call :colorEcho %YELLOW% "Mevcut versiyon: "
for /f "tokens=*" %%i in ('pnpm -s exec jq -r ".version" package.json') do (
    call :colorEcho %CYAN% "%%i"
)
echo.
echo.

:: Versiyon tipini sorma
echo Versiyon yükseltme tipi seçin:
call :colorEcho %GREEN% "1) patch"
echo  - 1.7.1 -^> 1.7.2
call :colorEcho %YELLOW% "2) minor"
echo  - 1.7.1 -^> 1.8.0
call :colorEcho %RED% "3) major"
echo  - 1.7.1 -^> 2.0.0
call :colorEcho %BLUE% "4) custom"
echo  - özel versiyon (elle girilecek)
echo.

set /p versionType="Seçiminiz (1-4): "

if "%versionType%"=="1" (
    set "versionCmd=patch"
) else if "%versionType%"=="2" (
    set "versionCmd=minor"
) else if "%versionType%"=="3" (
    set "versionCmd=major"
) else if "%versionType%"=="4" (
    set /p customVersion="Özel versiyon numarası (örn: 1.8.0): "
    set "versionCmd=%customVersion%"
) else (
    call :colorEcho %RED% "Geçersiz seçim! Program sonlandırılıyor."
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "NPM'e giriş yapılıyor..."
echo.
call pnpm login

if %errorlevel% neq 0 (
    call :colorEcho %RED% "NPM login başarısız oldu!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Versiyon yükseltiliyor..."
echo.

if "%versionType%"=="4" (
    call pnpm version %versionCmd% --no-git-tag-version
) else (
    call pnpm version %versionCmd%
)

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Versiyon yükseltme başarısız oldu!"
    exit /b 1
)

:: Yeni versiyonu alma
for /f "tokens=*" %%i in ('pnpm -s exec jq -r ".version" package.json') do (
    set "newVersion=%%i"
)

echo.
call :colorEcho %YELLOW% "Projeyi derleme..."
echo.
call pnpm run build

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Derleme başarısız oldu!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Derlenen paket içeriği:"
echo.
dir dist /b

echo.
call :colorEcho %YELLOW% "Paket önizlemesi oluşturuluyor..."
echo.
call pnpm pack --pack-destination ./temp-pack

echo.
set /p confirmPublish="Paketi NPM'e yayınlamak istiyor musunuz? (e/h): "
if /i not "%confirmPublish%"=="e" (
    call :colorEcho %RED% "Yayınlama iptal edildi!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Paket NPM'e yayınlanıyor..."
echo.
call pnpm publish

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Yayınlama başarısız oldu!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Git işlemleri yapılıyor..."
echo.

:: Özel versiyon ise git tag oluştur
if "%versionType%"=="4" (
    call git tag v%newVersion%
)

call git add .
call git commit -m "chore: bump version to v%newVersion%"
call git push

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Git push başarısız oldu!"
    exit /b 1
)

echo.
call :colorEcho %YELLOW% "Git tag'leri gönderiliyor..."
echo.
call git push --tags

if %errorlevel% neq 0 (
    call :colorEcho %RED% "Git tag push başarısız oldu!"
    exit /b 1
)

echo.
call :colorEcho %GREEN% "========================================"
call :colorEcho %GREEN% "  Paket başarıyla yayınlandı: v%newVersion%"
call :colorEcho %GREEN% "========================================"
echo.

:: Geçici paket dosyalarını temizleme
if exist temp-pack (
    del /q temp-pack\*
    rmdir temp-pack
)

exit /b 0

:colorEcho
:: %~1 renk kodu (örn. 31=kırmızı)
:: %~2 yazılacak metin
echo [%~1m%~2[0m
exit /b
