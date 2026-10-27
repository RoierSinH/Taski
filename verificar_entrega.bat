@echo off
chcp 65001 >nul
cd /d "C:\Users\roger\mi_primera_app"
echo ====================================================================
echo   TASKI PARTE 10 - VERIFICACION DE APK RELEASE FIRMADO Y PRUEBAS
echo ====================================================================
echo.
echo [1/3] Archivo APK de Release generado (v1.0.0+2):
dir "C:\Users\roger\mi_primera_app\build\app\outputs\flutter-apk\app-release.apk" | findstr "app-release.apk"
echo.
echo [2/3] Verificacion de firma criptografica (RSA 2048 - taski-release.jks):
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -printcert -jarfile "C:\Users\roger\mi_primera_app\build\app\outputs\flutter-apk\app-release.apk" | findstr /C:"Propietario:" /C:"Owner:" /C:"SHA256:" /C:"Algoritmo" /C:"Signature"
echo.
echo [3/3] Ejecutando suite de pruebas automatizadas (flutter test):
call flutter test --no-pub
echo.
echo ====================================================================
echo   VERIFICACION COMPLETADA AL 100%%
echo ====================================================================
pause
