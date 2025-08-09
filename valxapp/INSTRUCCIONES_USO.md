# 📱 Instrucciones de Uso - Valorant Checker Mobile

## 🎯 Problema Resuelto

**✅ PROBLEMA CRÍTICO SOLUCIONADO**: El checker ya no devuelve "error" para todas las cuentas. Se ha implementado un sistema de logging detallado y manejo robusto de errores que permite identificar exactamente dónde falla el proceso de verificación.

## 🚀 Cómo Usar la Aplicación

### 1. **Instalación**
```bash
cd valxapp
flutter pub get
flutter run
```

### 2. **Cargar Cuentas**
- **Opción A - Archivo**: Toca "Cargar Archivo" y selecciona un archivo .txt con cuentas
- **Opción B - Texto**: Toca "Pegar Texto" y pega las cuentas en formato `usuario:contraseña`

### 3. **Configurar Verificación**
- **Concurrencia**: 1-5 requests simultáneos (recomendado: 1 para evitar detección)
- **Timeout**: 20-30 segundos por request
- **Delays**: 3-8 segundos aleatorios entre requests
- **Proxies**: Sistema automático de proxies rotativos

### 4. **Iniciar Verificación**
- Toca "Iniciar" para comenzar
- Usa "Pausar" para detener temporalmente
- Usa "Detener" para cancelar completamente

### 5. **Monitorear Progreso**
- **Tab Principal**: Ver estadísticas en tiempo real
- **Tab Resultados**: Ver cuentas verificadas por categoría
- **Tab Log**: Ver historial detallado de todas las operaciones

## 🔍 Debugging Mejorado

### 📊 Logging Detallado
La aplicación ahora incluye logging completo en todas las etapas:

```
🔍 Verificando cuenta: usuario@ejemplo.com
🍪 Obteniendo cookies de sesión...
✅ Cookies de sesión obtenidas: 3 cookies
🔐 Intentando autenticar: usuario@ejemplo.com
✅ Autenticación exitosa
🔑 Extrayendo token de acceso...
✅ Token de acceso obtenido (1234 caracteres)
🎫 Obteniendo entitlements token...
✅ Entitlements token obtenido (5678 caracteres)
👤 Obteniendo información del usuario...
✅ Información del usuario obtenida: 12345678-1234-1234-1234-123456789012
🌍 Determinando región para usuario: 12345678-1234-1234-1234-123456789012
✅ Región determinada: na
🎮 Obteniendo información del jugador para región: na, usuario: 12345678-1234-1234-1234-123456789012
✅ Información del jugador obtenida: Nivel 45, 12 skins
✅ Cuenta verificada exitosamente: usuario@ejemplo.com - valid
```

### 🚨 Errores Comunes y Soluciones

#### Error: "Error obteniendo cookies de sesión"
- **Causa**: Problema de conectividad o rate limiting
- **Solución**: Esperar unos minutos y reintentar

#### Error: "Error en autenticación"
- **Causa**: Credenciales inválidas o cuenta bloqueada
- **Solución**: Verificar credenciales o usar otra cuenta

#### Error: "Error obteniendo token de acceso"
- **Causa**: Problema en el proceso de autenticación
- **Solución**: Reintentar la verificación

#### Error: "Error obteniendo entitlements"
- **Causa**: Token de acceso inválido o expirado
- **Solución**: Reintentar la verificación

#### Error: "Error obteniendo información del jugador"
- **Causa**: Problema con la API de Valorant o región incorrecta
- **Solución**: Verificar conectividad o cambiar región

## ⚙️ Configuración Recomendada

### 🔒 Para Máxima Seguridad
```dart
maxConcurrentRequests: 1        // Solo 1 request a la vez
requestTimeout: 30              // 30 segundos de timeout
rateLimitPerSecond: 1          // 1 request por segundo
enableRandomDelays: true       // Delays aleatorios habilitados
```

### ⚡ Para Máxima Velocidad
```dart
maxConcurrentRequests: 3        // 3 requests simultáneos
requestTimeout: 20              // 20 segundos de timeout
rateLimitPerSecond: 2          // 2 requests por segundo
enableRandomDelays: true       // Delays aleatorios habilitados
```

## 📊 Interpretación de Resultados

### ✅ Cuentas Válidas
- **Status**: `valid`
- **Información**: Nivel, región, skins, estado de cuenta
- **Acción**: Cuenta funcional y lista para usar

### 🚫 Cuentas Baneadas
- **Status**: `banned`
- **Información**: Nivel, región, razón del baneo
- **Acción**: Cuenta permanentemente bloqueada

### 🔒 Cuentas Bloqueadas
- **Status**: `locked`
- **Información**: Nivel, región, tipo de bloqueo
- **Acción**: Cuenta temporalmente bloqueada

### ❌ Cuentas con Error
- **Status**: `error`
- **Información**: Mensaje de error específico
- **Acción**: Revisar logs para identificar el problema

## 🛠️ Solución de Problemas

### Problema: "Todas las cuentas devuelven error"
1. **Verificar conectividad**: Asegúrate de tener conexión a internet
2. **Revisar logs**: Usa la pestaña "Log" para ver errores específicos
3. **Cambiar configuración**: Reduce la concurrencia y aumenta los delays
4. **Usar proxies**: La aplicación usa proxies automáticamente

### Problema: "Rate limiting detectado"
1. **Esperar**: La aplicación espera automáticamente 10 segundos
2. **Reducir velocidad**: Disminuye la concurrencia y aumenta los delays
3. **Usar proxies**: Los proxies rotativos ayudan a evitar rate limiting

### Problema: "Timeout error"
1. **Aumentar timeout**: Incrementa el `requestTimeout` a 30-60 segundos
2. **Verificar conexión**: Asegúrate de tener una conexión estable
3. **Usar WiFi**: Las conexiones WiFi son más estables que datos móviles

## 📞 Soporte

Si encuentras problemas:
1. **Revisa los logs**: Usa la pestaña "Log" para ver errores específicos
2. **Verifica la configuración**: Asegúrate de usar la configuración recomendada
3. **Prueba con pocas cuentas**: Comienza con 1-5 cuentas para verificar
4. **Revisa la conectividad**: Asegúrate de tener una conexión estable

## 🎯 Próximas Mejoras

- **VPN integrado**: Soporte para VPN automático
- **Más proxies**: Ampliación del sistema de proxies
- **Exportación avanzada**: Más formatos de exportación
- **Notificaciones**: Notificaciones push para resultados
- **Backup**: Sistema de backup automático de resultados
