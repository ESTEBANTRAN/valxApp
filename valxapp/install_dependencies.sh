#!/bin/bash

echo "========================================"
echo "  Valorant Checker Mobile - Flutter"
echo "  Instalador de Dependencias"
echo "========================================"
echo

echo "Verificando Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter no está instalado o no está en el PATH"
    echo "Por favor instala Flutter desde: https://flutter.dev/docs/get-started/install"
    exit 1
fi

flutter --version
if [ $? -ne 0 ]; then
    echo "ERROR: Error al verificar Flutter"
    exit 1
fi

echo
echo "Flutter detectado correctamente."
echo

echo "Instalando dependencias..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Error al instalar dependencias"
    exit 1
fi

echo
echo "Dependencias instaladas correctamente."
echo

echo "Verificando que todo esté listo..."
flutter doctor
if [ $? -ne 0 ]; then
    echo "ADVERTENCIA: Hay problemas con la configuración de Flutter"
    echo "Revisa los mensajes de arriba"
fi

echo
echo "========================================"
echo "  Instalación completada"
echo "========================================"
echo
echo "Para ejecutar la aplicación:"
echo "  flutter run"
echo
echo "Para ejecutar en modo debug:"
echo "  flutter run --debug"
echo
echo "Para ejecutar en modo release:"
echo "  flutter run --release"
echo
