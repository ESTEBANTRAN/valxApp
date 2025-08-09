class AppConstants {
  static const String appName = 'Valorant Checker Mobile';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String riotAuthUrl = 'https://auth.riotgames.com';
  static const String riotEntitlementsUrl =
      'https://entitlements.auth.riotgames.com';
  static const String valorantApiBase = 'https://pd.{region}.a.pvp.net';

  // User Agents para móvil (menos sospechoso)
  static const String mobileUserAgent =
      'RiotClient/58.0.0.6400298.4552318 rso-auth (Android; 13;;Samsung Galaxy S23, x64)';
  static const String webUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  // Configuración por defecto (optimizada para evitar rate limiting)
  static const int defaultMaxConcurrentRequests = 1; // Solo 1 request a la vez
  static const int defaultRequestTimeout = 30; // Más tiempo en móvil
  static const int defaultRetryAttempts = 3;
  static const int defaultRetryDelay = 5; // Más delay en móvil
  static const int defaultRateLimitPerSecond = 1; // Muy conservador en móvil

  // Regiones disponibles
  static const List<String> availableRegions = [
    'na',
    'eu',
    'ap',
    'br',
    'kr',
    'latam',
  ];

  // Rangos de nivel
  static const Map<String, List<int>> levelRanges = {
    '1-10': [1, 10],
    '10-20': [10, 20],
    '20-30': [20, 30],
    '30-40': [30, 40],
    '40-50': [40, 50],
    '50-100': [50, 100],
    '100+': [100, 999],
  };

  // Estados de cuenta
  static const String statusValid = 'valid';
  static const String statusBanned = 'banned';
  static const String statusLocked = 'locked';
  static const String statusError = 'error';
  static const String statusTwoFactor = 'twoFactor';
  static const String statusInvalidCredentials = 'invalidCredentials';

  // Mensajes de error
  static const Map<String, String> errorMessages = {
    'invalid_credentials': 'Credenciales inválidas',
    'network_error': 'Error de red',
    'timeout_error': 'Tiempo de espera agotado',
    'rate_limit': 'Demasiadas solicitudes',
    'unknown_error': 'Error desconocido',
  };

  // Configuración de caché
  static const int cacheDurationHours = 24;
  static const int maxCacheSize = 1000;
  static const bool enableRandomDelays = true;

  // Configuración de UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultIconSize = 24.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;

  // Configuración de animaciones
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Configuración de logs
  static const int maxLogMessages = 1000;
  static const bool enableDetailedLogging = true;

  // Configuración de exportación
  static const String defaultExportFormat = 'txt';
  static const List<String> supportedExportFormats = ['txt', 'csv', 'json'];

  // Configuración de notificaciones
  static const bool enableNotifications = true;
  static const String notificationChannelId = 'valorant_checker';
  static const String notificationChannelName = 'Valorant Checker';
  static const String notificationChannelDescription =
      'Notificaciones del checker de Valorant';

  // Configuración de seguridad
  static const bool enableEncryption = false;
  static const String encryptionKey = '';

  // Configuración de rendimiento
  static const int maxAccountsPerBatch = 50;
  static const int minDelayBetweenBatches = 5000; // 5 segundos
  static const int maxDelayBetweenBatches = 15000; // 15 segundos

  // Configuración de validación
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;

  // Configuración de filtros
  static const int defaultMinLevel = 1;
  static const int defaultMaxLevel = 999;
  static const bool defaultIncludeBanned = true;
  static const bool defaultIncludeLocked = true;

  // Configuración de estadísticas
  static const int maxStatsHistory = 100;
  static const Duration statsUpdateInterval = Duration(seconds: 5);

  // Configuración de backup
  static const bool enableAutoBackup = true;
  static const Duration backupInterval = Duration(hours: 6);
  static const int maxBackupFiles = 10;

  // Configuración de debugging
  static const bool enableDebugMode = false;
  static const bool enableVerboseLogging = false;
  static const bool enablePerformanceMonitoring = false;
}
