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

  // Configuración por defecto (optimizada para móvil)
  static const int defaultMaxConcurrentRequests =
      5; // Menos concurrente en móvil
  static const int defaultRequestTimeout = 20; // Más tiempo en móvil
  static const int defaultRetryAttempts = 3;
  static const int defaultRetryDelay = 3; // Más delay en móvil
  static const int defaultRateLimitPerSecond = 2; // Más conservador en móvil

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

  // Colores de estado
  static const Map<String, int> statusColors = {
    'valid': 0xFF4CAF50, // Verde
    'banned': 0xFFF44336, // Rojo
    'locked': 0xFFFF9800, // Naranja
    'error': 0xFF9E9E9E, // Gris
  };

  // Mensajes de error
  static const Map<String, String> errorMessages = {
    'network_error': 'Error de conexión. Verifica tu internet.',
    'timeout_error': 'Tiempo de espera agotado.',
    'invalid_credentials': 'Credenciales inválidas.',
    'rate_limit': 'Demasiadas solicitudes. Espera un momento.',
    'server_error': 'Error del servidor. Intenta más tarde.',
    'unknown_error': 'Error desconocido.',
  };

  // Configuración de caché
  static const int cacheDurationHours = 24;
  static const int maxCacheSize = 500; // Menos caché en móvil

  // Configuración de notificaciones
  static const String notificationChannelId = 'valorant_checker';
  static const String notificationChannelName = 'Valorant Checker';
  static const String notificationChannelDescription =
      'Notificaciones del checker';

  // Archivos
  static const String resultsFileName = 'checker_results.json';
  static const String configFileName = 'app_config.json';
  static const String cacheFileName = 'checker_cache.json';

  // Animaciones
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shimmerDuration = Duration(milliseconds: 1500);

  // Límites
  static const int maxAccountsPerBatch = 20; // Menos en móvil
  static const int maxRetryAttempts = 5;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;

  // Configuración de seguridad móvil
  static const bool enableRandomDelays = true;
  static const int minDelayBetweenRequests = 1000; // 1 segundo mínimo
  static const int maxDelayBetweenRequests = 3000; // 3 segundos máximo

  // Configuración de UI
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
}
