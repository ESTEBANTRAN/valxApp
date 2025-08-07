@echo off
echo ========================================
echo   Valorant Checker Mobile - Flutter
echo   Instalador de Dependencias
echo ========================================
echo.

echo Verificando Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter no está instalado o no está en el PATH
    echo Por favor instala Flutter desde: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo.
echo Flutter detectado correctamente.
echo.

echo Instalando dependencias...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Error al instalar dependencias
    pause
    exit /b 1
)

echo.
echo Dependencias instaladas correctamente.
echo.

echo Verificando que todo esté listo...
flutter doctor
if %errorlevel% neq 0 (
    echo ADVERTENCIA: Hay problemas con la configuración de Flutter
    echo Revisa los mensajes de arriba
)

echo.
echo ========================================
echo   Instalación completada
echo ========================================
echo.
echo Para ejecutar la aplicación:
echo   flutter run
echo.
echo Para ejecutar en modo debug:
echo   flutter run --debug
echo.
echo Para ejecutar en modo release:
echo   flutter run --release
echo.
pause
