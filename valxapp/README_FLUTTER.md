# Valorant Checker Mobile - Versión Flutter

## 🚀 Migración Completa a Flutter

Esta es la versión móvil del Valorant Checker, migrada completamente a Flutter para aprovechar las ventajas de las verificaciones desde dispositivos móviles y reducir el riesgo de baneo.

## ✨ Características Principales

### 🔒 **Seguridad Móvil Mejorada**
- **User Agents Móviles**: Utiliza user agents específicos de dispositivos móviles para parecer más legítimo
- **Delays Aleatorios**: Implementa delays aleatorios entre solicitudes para evitar detección
- **Rate Limiting Conservador**: Configuración más conservadora para móviles (2 req/s vs 100 req/s en PC)
- **Menos Concurrencia**: Máximo 5 solicitudes concurrentes vs 50 en PC
- **Timeouts Extendidos**: Más tiempo de espera para conexiones móviles

### 📱 **Interfaz Móvil Optimizada**
- **Diseño Responsivo**: Adaptado específicamente para pantallas táctiles
- **Navegación por Tabs**: 4 secciones principales (Principal, Resultados, Log, Config)
- **Controles Táctiles**: Botones grandes y fáciles de usar
- **Feedback Visual**: Indicadores de progreso y estados claros
- **Tema Oscuro**: Interfaz moderna con tema oscuro por defecto

### 🔧 **Funcionalidades Avanzadas**
- **Carga de Archivos**: Seleccionar archivos .txt desde el dispositivo
- **Pegado de Texto**: Pegar cuentas directamente en la app
- **Resultados en Tiempo Real**: Ver resultados mientras se ejecuta
- **Log Detallado**: Historial completo de todas las operaciones
- **Caché Inteligente**: Evita verificaciones duplicadas
- **Exportación**: Guardar resultados en el dispositivo

## 📋 Requisitos

- **Flutter SDK**: 3.8.1 o superior
- **Dart**: 3.0.0 o superior
- **Android**: API 21+ (Android 5.0+)
- **iOS**: 12.0+
- **Conexión a Internet**: Para las verificaciones

## 🛠️ Instalación

### 1. Clonar el Proyecto
```bash
cd valxapp
```

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Ejecutar la Aplicación
```bash
# Para Android
flutter run

# Para iOS
flutter run -d ios

# Para desarrollo web
flutter run -d chrome
```

## 📱 Uso de la Aplicación

### 1. **Cargar Cuentas**
- **Opción A**: Toca "Cargar Archivo" y selecciona un archivo .txt
- **Opción B**: Toca "Pegar Texto" y pega las cuentas en formato `usuario:contraseña`

### 2. **Configurar Verificación**
- Ajusta la configuración según tus necesidades
- Configuración por defecto optimizada para móviles

### 3. **Iniciar Verificación**
- Toca "Iniciar" para comenzar la verificación
- Usa "Pausar" para detener temporalmente
- Usa "Detener" para cancelar completamente

### 4. **Ver Resultados**
- Navega a la pestaña "Resultados" para ver las cuentas verificadas
- Los resultados se organizan por estado (Válidas, Baneadas, Bloqueadas, Errores)

### 5. **Monitorear Progreso**
- Usa la pestaña "Log" para ver el historial detallado
- El progreso se muestra en tiempo real

## 🔧 Configuración

### Configuración por Defecto (Móvil)
```dart
maxConcurrentRequests: 5        // Menos concurrente que PC
requestTimeout: 20              // Más tiempo para móviles
rateLimitPerSecond: 2          // Más conservador
enableRandomDelays: true       // Delays aleatorios
minDelayBetweenRequests: 1000  // 1 segundo mínimo
maxDelayBetweenRequests: 3000  // 3 segundos máximo
```

### Configuración vs PC
| Parámetro | PC | Móvil | Ventaja |
|-----------|----|-------|---------|
| Concurrencia | 50 | 5 | Menos sospechoso |
| Rate Limit | 100/s | 2/s | Más conservador |
| Timeout | 10s | 20s | Mejor para móviles |
| Delays | No | Sí | Evita detección |

## 📊 Ventajas de la Versión Móvil

### 🛡️ **Seguridad**
- **Menor Riesgo de Baneo**: Las verificaciones desde móviles son menos sospechosas
- **User Agents Legítimos**: Simula dispositivos móviles reales
- **Comportamiento Natural**: Delays y patrones más humanos
- **Menos Concurrencia**: Reduce la carga en los servidores

### 📱 **Usabilidad**
- **Interfaz Táctil**: Optimizada para pantallas táctiles
- **Portabilidad**: Lleva el checker en tu bolsillo
- **Acceso Rápido**: Verificaciones desde cualquier lugar
- **Feedback Inmediato**: Resultados en tiempo real

### 🔄 **Flexibilidad**
- **Múltiples Plataformas**: Android, iOS, Web
- **Configuración Dinámica**: Ajusta parámetros según necesites
- **Almacenamiento Local**: Resultados guardados en el dispositivo
- **Sin Instalación**: No requiere configuración compleja

## 🚨 Consideraciones de Seguridad

### ✅ **Buenas Prácticas**
- Usa la app en redes WiFi confiables
- No compartas resultados públicamente
- Respeta los términos de servicio de Riot Games
- Usa la app de manera responsable

### ⚠️ **Advertencias**
- Esta herramienta es solo para uso educativo
- El uso indebido puede resultar en baneos
- Los desarrolladores no se responsabilizan por el uso incorrecto
- Siempre verifica las políticas de Riot Games

## 🔧 Desarrollo

### Estructura del Proyecto
```
lib/
├── main.dart                 # Punto de entrada
├── models/                   # Modelos de datos
│   ├── account.dart
│   └── checker_config.dart
├── providers/                # Gestión de estado
│   └── checker_provider.dart
├── screens/                  # Pantallas principales
│   └── home_screen.dart
├── services/                 # Servicios de API
│   └── api_service.dart
├── utils/                    # Utilidades
│   ├── constants.dart
│   └── theme.dart
└── widgets/                  # Widgets reutilizables
    ├── account_input_widget.dart
    ├── checker_controls_widget.dart
    ├── results_widget.dart
    └── log_widget.dart
```

### Tecnologías Utilizadas
- **Flutter**: Framework principal
- **Provider**: Gestión de estado
- **Dio**: Cliente HTTP avanzado
- **SharedPreferences**: Almacenamiento local
- **File Picker**: Selección de archivos
- **Path Provider**: Acceso a directorios

## 📈 Próximas Mejoras

- [ ] **Configuración Avanzada**: Panel de configuración completo
- [ ] **Exportación**: Exportar resultados en diferentes formatos
- [ ] **Notificaciones**: Notificaciones push para resultados
- [ ] **Sincronización**: Sincronizar con servicios en la nube
- [ ] **Análisis**: Estadísticas detalladas de verificaciones
- [ ] **Temas**: Múltiples temas visuales
- [ ] **Idiomas**: Soporte multiidioma

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## ⚠️ Descargo de Responsabilidad

Esta herramienta es solo para uso educativo y de investigación. Los desarrolladores no se responsabilizan por el uso incorrecto o las consecuencias derivadas del uso de esta herramienta. Siempre respeta los términos de servicio de los servicios que utilizas.

---

**¡Disfruta usando Valorant Checker Mobile! 🎮📱**
