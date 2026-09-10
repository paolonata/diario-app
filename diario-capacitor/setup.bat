@echo off
REM ============================================================
REM  Diario - setup completo per Windows
REM  Genera il progetto Android, applica l'icona e prepara tutto.
REM  Lancialo con doppio clic, oppure da cmd:  setup.bat
REM ============================================================
setlocal

echo.
echo === [1/6] Installazione dipendenze (npm install) ===
call npm install
if errorlevel 1 goto err

echo.
echo === [2/6] Aggiunta piattaforma Android ===
if exist android (
  echo    android gia' presente, salto cap add.
) else (
  call npx cap add android
  if errorlevel 1 goto err
)

echo.
echo === [3/6] Copia icona nel progetto ===
xcopy /y /e /i icona\mipmap-mdpi    android\app\src\main\res\mipmap-mdpi    >nul
xcopy /y /e /i icona\mipmap-hdpi    android\app\src\main\res\mipmap-hdpi    >nul
xcopy /y /e /i icona\mipmap-xhdpi   android\app\src\main\res\mipmap-xhdpi   >nul
xcopy /y /e /i icona\mipmap-xxhdpi  android\app\src\main\res\mipmap-xxhdpi  >nul
xcopy /y /e /i icona\mipmap-xxxhdpi android\app\src\main\res\mipmap-xxxhdpi >nul
xcopy /y /e /i icona\values         android\app\src\main\res\values         >nul
echo    Icona copiata (sfondo scuro + foreground centrato).

echo.
echo === [4/6] Sincronizzazione (cap sync) ===
call npx cap sync
if errorlevel 1 goto err

echo.
echo === [5/6] Verifica icona applicata ===
dir android\app\src\main\res\mipmap-mdpi\ic_launcher_foreground.png | find "ic_launcher_foreground"

echo.
echo === [6/6] Apertura Android Studio ===
echo    Ora si apre Android Studio. Quando ha finito il "Gradle sync" in basso:
echo      Build ^> Clean Project
echo      Build ^> Generate App Bundles or APKs ^> Generate APKs
echo    Poi installa: android\app\build\outputs\apk\debug\app-debug.apk
echo.
call npx cap open android
goto end

:err
echo.
echo *** Si e' verificato un errore. Leggi il messaggio qui sopra. ***
echo Se dice che npm/npx sono bloccati, stai usando PowerShell: usa cmd.
pause
exit /b 1

:end
echo.
echo Fatto. Segui le istruzioni del passo 6 dentro Android Studio.
pause
endlocal
