# Changelog - Valorant Checker Mobile

## [1.0.1] - 2025-01-27

### 🔧 Mejoras en la API
- **Logging detallado**: Agregado logging completo en todas las etapas de la API para facilitar el debugging
- **Manejo de errores mejorado**: Implementado manejo robusto de errores en cada paso de la autenticación
- **Headers mejorados**: Agregado `Content-Type` y `Connection` headers para mayor compatibilidad
- **Validación de respuestas**: Implementada validación de estructura de respuestas en cada endpoint

### 🐛 Correcciones
- **Print statements**: Reemplazados todos los `print` statements con `debugPrint` para cumplir con las mejores prácticas
- **BuildContext warnings**: Corregidos warnings menores sobre uso de BuildContext en async gaps
- **Error handling**: Mejorado el manejo de errores en todas las funciones de la API

### 📊 Logging Detallado
- **Cookies**: Logging de obtención y validación de cookies de sesión
- **Autenticación**: Logging detallado del proceso de autenticación con Riot
- **Tokens**: Logging de obtención y validación de tokens de acceso y entitlements
- **Usuario**: Logging de obtención de información del usuario
- **Región**: Logging de determinación de región del usuario
- **Jugador**: Logging detallado de información del jugador (nivel, skins, estado)

### 🔍 Debugging Mejorado
- **Status codes**: Logging de todos los códigos de estado HTTP
- **Respuestas**: Logging de contenido de respuestas para debugging
- **Errores**: Logging detallado de errores y excepciones
- **Progreso**: Logging del progreso de cada cuenta verificada

### 🛡️ Seguridad
- **Headers consistentes**: Implementación consistente de headers en todas las requests
- **Validación**: Validación de estructura de datos en todas las respuestas
- **Error handling**: Manejo robusto de errores para evitar crashes

## [1.0.0] - 2025-01-26

### 🎯 Lanzamiento Inicial
- **Migración completa**: Migración del checker de Python a Flutter
- **Interfaz móvil**: Interfaz moderna optimizada para dispositivos móviles
- **Sistema de proxies**: Implementación de sistema de proxies rotativos
- **Anti-detection**: Medidas anti-detection implementadas
- **Caché**: Sistema de caché para optimizar verificaciones
- **Logging**: Sistema de logging en tiempo real
- **Exportación**: Funcionalidad de exportación de resultados

### 📱 Características Principales
- **Multiplataforma**: Soporte para Android, iOS y Web
- **UI moderna**: Interfaz Material Design con tema oscuro
- **Navegación por tabs**: 4 secciones principales (Principal, Resultados, Log, Config)
- **Carga de archivos**: Soporte para cargar archivos .txt
- **Pegado de texto**: Funcionalidad para pegar cuentas directamente
- **Resultados en tiempo real**: Visualización de resultados mientras se ejecuta
- **Configuración dinámica**: Ajuste de parámetros según necesidades

### 🔒 Seguridad
- **User agents móviles**: User agents específicos para dispositivos móviles
- **Delays aleatorios**: Delays aleatorios entre solicitudes
- **Rate limiting conservador**: Configuración más conservadora para móviles
- **Proxies rotativos**: Sistema de proxies para evitar detección
- **Menos concurrencia**: Máximo 5 solicitudes concurrentes vs 50 en PC
